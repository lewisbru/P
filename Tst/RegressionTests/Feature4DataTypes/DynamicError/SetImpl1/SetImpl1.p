// Tests the correctness of set types

machine Main {
    var t : (a: seq [int], b: map[int, seq[int]]);
	var t1 : (a: seq [int], b: map[int, seq[int]]);
	var ts: (a: int, b: int);
	var tt: (int, int);
	var te: (int, event);
    var y : int;
	var b: bool;
	var e: event;
	var a: any;
        var st: set [int];
	var st1: set [int];
	var sq: seq [int];
	var sq1: seq [int];
	var st2: set [seq [int]];
	var tmp: int;
	var tmp1: int;
	
    start state S
    {
       entry
       {
		st += (4);
                st += (5);
                st -= (4);
                st1 += (5);	
		tmp = sizeof(st);
		st2 += (sq);
		assert (sq1 in st2 == false); //Fails
		raise halt;
       }
    }
}

