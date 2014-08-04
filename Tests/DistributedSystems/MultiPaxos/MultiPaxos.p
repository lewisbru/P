/*
The basic paxos algorithm. 
*/
event prepare : (proposer: id, proposal : (round: int, serverId : int)) assume 3;
event accept : (proposer: id, proposal : (round: int, serverId : int), value : int) assume 3;
event agree : (proposal : (round: int, serverId : int), value : int) assume 6;
event reject : (proposal : (round: int, serverId : int)) assume 6;
event accepted : (proposal : (round: int, serverId : int), value : int) assume 6;
event local;
event success;
event allNodes: (nodes: seq[id]);
event goPropose;
event Chosen : (command:int);
/**** client events ********/
event update : (seqId: int, command : int);

machine PaxosNode {

	var currentLeader : (rank:int, server : id);
	var leaderElectionService : id;
/********************** Proposer **************************************************/
	var acceptors : seq[id];
	var proposeVal : int;
	var majority : int;
	var roundNum : int;
	var myRank : int;
	var nextProposal: (round: int, serverId : int);
	var receivedAgree : (proposal : (round: int, serverId : int), value : int);
	var iter : int ;
	var maxRound : int;
	var countAccept : int;
	var countAgree : int;
	var tempVal : int;
	var returnVal : bool;
	var timer: mid;
	var receivedMess_1 : (proposal : (round: int, serverId : int), value : int);
/*************************** Acceptor **********************************************/
	var lastSeenProposal : (proposal : (round: int, serverId : int), value : int);
	var receivedMess_2 : (proposer: id, proposal : (round: int, serverId : int), value : int);
	
	
	start state Init {
		defer Ping;
		entry {
			lastSeenProposal.proposal = (round = -1, serverId = -1);
			lastSeenProposal.value = -1;
			myRank = ((rank:int))payload.rank;
			currentLeader = (rank = myRank, server = this);
			roundNum = 0;
			maxRound = 0;
			timer = new Timer((this, 10));
		}
		on allNodes do UpdateAcceptors;
		on local goto PerformOperation;
	}
	
	action UpdateAcceptors {
		acceptors = payload.nodes;
		majority = (sizeof(acceptors))/2 + 1;
		assert(majority == 2);
		//Also start the leader election service;
		leaderElectionService = new LeaderElection((servers = acceptors, parentServer = this, rank = myRank));
		
		raise(local);
	}
	
	action CheckIfLeader {
		if(currentLeader.rank == myRank) {
			// I am the leader 
			proposeVal = payload.command;
			raise(goPropose);
		}
		else
		{
			//forward it to the leader
			send(currentLeader.server, update, payload);
		}
	}
	state PerformOperation {
		ignore agree;
		
		/***** proposer ******/
		on update do CheckIfLeader;
		on goPropose push ProposeValuePhase1;
		
		/***** acceptor ****/
		on prepare do prepareAction;
		on accept do acceptAction;
		
		/**** leaner ****/
		on Chosen goto RunLearner;
		
		/*****leader election ****/
		on Ping do ForwardToLE;
		on newLeader do UpdateLeader;
	}
	
	action ForwardToLE {
		send(leaderElectionService, Ping, payload);
	}
	
	action UpdateLeader {
		currentLeader = payload;
	}
	
	action prepareAction {
		receivedMess_2.proposal = ((proposer: id, proposal : (round: int, serverId : int)))payload.proposal;
		receivedMess_2.proposer = ((proposer: id, proposal : (round: int, serverId : int)))payload.proposer;
		returnVal = lessThan(receivedMess_2.proposal, lastSeenProposal.proposal);
		if(lastSeenProposal.value ==  -1)
		{
			send(receivedMess_2.proposer, agree, (proposal = (round = -1, serverId = -1), value = -1));
			lastSeenProposal.proposal = receivedMess_2.proposal;
		}
		else if(returnVal)
		{
			send(receivedMess_2.proposer, reject, (proposal = lastSeenProposal.proposal));
		}
		else 
		{
			send(receivedMess_2.proposer, agree, lastSeenProposal);
			lastSeenProposal.proposal = receivedMess_2.proposal;
		}
	}
	
	action acceptAction {
		receivedMess_2 = ((proposer: id, proposal : (round: int, serverId : int), value : int))payload;
		returnVal = equal(receivedMess_2.proposal, lastSeenProposal.proposal);
		if(!returnVal)
		{
			send(receivedMess_2.proposer, reject, (proposal = lastSeenProposal.proposal));
		}
		else
		{
			lastSeenProposal.proposal = receivedMess_2.proposal;
			lastSeenProposal.value = receivedMess_2.value;
			send(receivedMess_2.proposer, accepted, (proposal = receivedMess_2.proposal, value = receivedMess_2.value));
		}
	}
	
	
	
	
	fun GetNextProposal(maxRound : int) : (round: int, serverId : int) {
		return (round = maxRound + 1, serverId = myRank);
	}
	
	fun equal (p1 : (round: int, serverId : int), p2 : (round: int, serverId : int)) : bool {
		if(p1.round == p2.round && p1.serverId == p2.serverId)
			return true;
		else
			return false;
	}
	
	fun lessThan (p1 : (round: int, serverId : int), p2 : (round: int, serverId : int)) : bool {
		if(p1.round < p2.round)
		{
			return true;
		}
		else if(p1.round == p2.round)
		{
			if(p1.serverId < p2.serverId)
				return true;
			else
				return false;
		}
		else
		{
			return false;
		}
	
	}
	
	/**************************** Proposer **********************************************************/
	
	fun BroadCastAcceptors(mess: eid, pay : any) {
		iter = 0;
		while(iter < sizeof(acceptors))
		{
			send(acceptors[iter], mess, pay);
			iter = iter + 1;
		}
	}
	
	action CountAgree {
		receivedMess_1 = ((proposal : (round: int, serverId : int), value : int))payload;
		countAgree = countAgree + 1;
		returnVal = lessThan(receivedAgree.proposal, receivedMess_1.proposal);
		if(returnVal)
		{
			receivedAgree.proposal = receivedMess_1.proposal;
			receivedAgree.value = receivedMess_1.value;
		}
		if(countAgree == majority)
			raise(success);
		
	}
	state ProposeValuePhase1 {
		ignore accepted;
		entry {
			countAgree = 0;
			nextProposal = GetNextProposal(maxRound);
			receivedAgree = (proposal = (round = -1, serverId = -1), value = -1);
			BroadCastAcceptors(prepare, (proposer = this, proposal = (round = nextProposal.round, serverId = myRank)));
			invoke ValidityCheck(monitor_proposer_sent, proposeVal);
			send(timer, startTimer);
		}
		
		on agree do CountAgree;
		on reject goto ProposeValuePhase1 {
			if(nextProposal.round <= ((proposal : (round: int, serverId : int)))payload.proposal.round)
				maxRound = ((proposal : (round: int, serverId : int)))payload.proposal.round;
				
			send(timer, cancelTimer);
		};
		on success goto ProposeValuePhase2
		{
			send(timer, cancelTimer);
		};
		on timeout goto ProposeValuePhase1;
	}
	
	action CountAccepted {
		returnVal = equal(((proposal : (round: int, serverId : int), value : int))payload.proposal, nextProposal);
		if(returnVal)
		{
			countAccept = countAccept + 1;
		}
		if(countAccept == majority)
		{
			raise(success);
		}
	
	}
	
	fun getHighestProposedValue() : int {
		if(receivedAgree.value != -1)
		{
			return receivedAgree.value;
		}
		else
		{
			return proposeVal;
		}
	}
	
	state ProposeValuePhase2 {
		ignore agree;
		entry {
		
			countAccept = 0;
			proposeVal = getHighestProposedValue();
			//invoke the monitor on proposal event
			invoke BasicPaxosInvariant_P2b(monitor_valueProposed, (proposer = this, proposal = nextProposal, value = proposeVal));
			invoke ValidityCheck(monitor_proposer_sent, proposeVal);
			
			BroadCastAcceptors(accept, (proposer = this, proposal = nextProposal, value = proposeVal));
			send(timer, startTimer);
		}
		
		on accepted do CountAccepted;
		on reject goto ProposeValuePhase1 {
			if(nextProposal.round <= ((proposal : (round: int, serverId : int)))payload.proposal.round)
				maxRound = ((proposal : (round: int, serverId : int)))payload.proposal.round;
				
			send(timer, cancelTimer);
		};
		on success goto DoneProposal
		{
			//the value is chosen, hence invoke the monitor on chosen event
			invoke BasicPaxosInvariant_P2b(monitor_valueChosen, (proposer = this, proposal = nextProposal, value = proposeVal));
		
			send(timer, cancelTimer);
		};
		on timeout goto ProposeValuePhase1;
		
	}
	
	state DoneProposal {
		entry {
			invoke ValidityCheck(monitor_proposer_chosen, proposeVal);
			raise(Chosen, (command = proposeVal));
		}
	}
	
	/**************************** Learner *******************************************/
	
	state RunLearner {
		ignore agree, accepted, timeout, prepare, reject, accept;
		entry {
		}
	
	}
}