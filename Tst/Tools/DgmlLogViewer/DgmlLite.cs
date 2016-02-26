﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace DgmlLogViewer
{
    class DgmlLite
    {
        XDocument dgml;
        XNamespace dgmlNs = XNamespace.Get("http://schemas.microsoft.com/vs/2009/dgml");
        XElement nodes;
        XElement links;
        Dictionary<string, XElement> nodeMap = new Dictionary<string, XElement>();
        Dictionary<string, XElement> linkMap = new Dictionary<string, XElement>();

        public DgmlLite()
        {
            nodes = new XElement(dgmlNs + "Nodes");
            links = new XElement(dgmlNs + "Links");
            dgml = new XDocument(new XElement(dgmlNs + "DirectedGraph", nodes, links));
        }

        public void GetOrCreateGroup(string groupName)
        {
            XElement e;
            if (!nodeMap.TryGetValue(groupName, out e))
            {
                e = new XElement(dgmlNs + "Node", new XAttribute("Id", groupName), new XAttribute("Group", "Expanded"));
                nodeMap[groupName] = e;
                nodes.Add(e);
            }
        }

        public void GetOrCreateNodeInGroup(string groupName, string nodeName)
        {
            GetOrCreateGroup(groupName);

            XElement e;
            if (!nodeMap.TryGetValue(nodeName, out e))
            {
                e = new XElement(dgmlNs + "Node", new XAttribute("Id", nodeName));
                nodeMap[nodeName] = e;
                nodes.Add(e);
                XElement link = GetOrCreateLink(groupName, nodeName);
                link.Add(new XAttribute("Category", "Contains"));
            }
        }

        public XElement GetOrCreateLink(string sourceNode, string targetNode, string label = null)
        {
            XElement link;
            string linkKey = sourceNode + "->" + targetNode;
            if (!linkMap.TryGetValue(linkKey, out link))
            {
                link = new XElement(dgmlNs + "Link", new XAttribute("Source", sourceNode), new XAttribute("Target", targetNode));
                links.Add(link);
            }

            if (label != null)
            {
                string existing = (string)link.Attribute("Label");
                if (!string.IsNullOrEmpty(existing))
                {
                    existing += ", ";
                }
                existing += label;
                link.SetAttributeValue("Label", existing);
            }
            return link;
        }

        public void Save(string outPath)
        {
            dgml.Save(outPath);
        }
    }
}