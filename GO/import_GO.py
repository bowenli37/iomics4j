from org.neo4j.unsafe.batchinsert import BatchInserters
from org.neo4j.graphdb import *
from org.neo4j.index.lucene.unsafe.batchinsert import LuceneBatchInserterIndexProvider
from org.apache.lucene.search import TermQuery
from org.apache.lucene.index import Term 

import xml.sax  #event based ie. proc. 
from math import fmod
from org.neo4j.helpers.collection import MapUtil
import shutil
import os

#

#GO node creation
class GONodeHandler( xml.sax.ContentHandler ):
    def __init__(self, nodeIndex, inserter, Nodes):
        self.CurrentData = ""
        self.id = ""
        self.name = ""
        self.namespace = ""
        self.defstr = ""
        self.is_obsolete = "0"
        self.totalTerm = 0
        self.nodeIndex = nodeIndex
        self.inserter = inserter
        self.NodeLabel = DynamicLabel.label( "GO_term" );
        
    # Call when an element starts
    def startElement(self, tag, attributes):
        self.CurrentData = tag
        if tag == "term":
            self.totalTerm += 1
        
    # Call when an elements ends
    def endElement(self, tag):
        self.CurrentData = ""
        if fmod(self.totalTerm, 1000) == 0 and tag == "term":
            print self.totalTerm
        
        if tag == "term":
            properties = MapUtil.map( "id", self.id )
            properties.put("name", self.name)
            properties.put("namespace", self.namespace)
            properties.put("defstr", self.defstr)
            if self.is_obsolete == "1":
                properties.put("is_obsolete", "1")
            Node = self.inserter.createNode(properties, self.NodeLabel)
            self.nodeIndex.add( Node, properties )
            # save Node in Nodes 
            Nodes[self.id] = Node
            
    # Call when a character is read
    def characters(self, content):
        if self.CurrentData == "id":
            self.id = content
        elif self.CurrentData == "name":
            self.name = content
        elif self.CurrentData == "namespace":
            self.namespace = content
        elif self.CurrentData == "defstr":
            self.defstr = content
        elif self.CurrentData == "is_obsolete":
            self.obsolete = content


#Edge creation
class GOEdgeHandler( xml.sax.ContentHandler ):
    def __init__(self, nodeIndex, inserter, Nodes):
        self.CurrentData = ""
        self.id = ""
        self.is_a = ""
        self.type = "" #relationship
        self.to  = ""  #relationship
        self.inTerm = False # avoid <typedef> in the end
        self.totalTerm = 0
        self.totalRel = 0
        self.totalIsA = 0
        self.nodeIndex = nodeIndex
        self.inserter = inserter
        self.is_a_type = DynamicRelationshipType.withName( "is_a" );
        
    # Call when an element starts
    def startElement(self, tag, attributes):
        self.CurrentData = tag
        if tag == "relationship":
            self.totalRel += 1
        elif tag == "is_a":
            self.totalIsA += 1
        elif tag == "term":
            self.totalTerm += 1
            self.inTerm = True
            
    # Call when an elements ends
    def endElement(self, tag):
        self.CurrentData = ""
        if fmod(self.totalRel, 1000) == 0 and tag == "relationship":
            print "#relationship: ", self.totalRel
            print "#is_a: ", self.totalIsA
            print "#term: ", self.totalTerm
            
        # relationship
        if tag == "relationship":
            # get source node for the relationship
            if Nodes.has_key(self.id):
                sNode = Nodes[self.id]
            else:
                print "self.id does not exist: ", self.id, ", ", self.to
            # get target node from the relationship
            if Nodes.has_key(self.to):    
                tNode = Nodes[self.to]
            else:
                print "self.to deoes not exist: ", self.id, ", ", self.to
            self.inserter.createRelationship(sNode, tNode, DynamicRelationshipType.withName( self.type ), None)
        elif tag == "is_a" and self.inTerm:
            # get source node for the relationship
            if Nodes.has_key(self.id):
                sNode = Nodes[self.id]
            else:
                print "self.id does not exist: ", self.id, ", ", self.is_a
            # get target node from the relationship
            if Nodes.has_key(self.is_a):
                tNode = Nodes[self.is_a]
            else:
                print "self.is_a deoes not exist: ", self.id, ", ", self.is_a
            self.inserter.createRelationship(sNode, tNode, self.is_a_type, None)
        elif tag == "term":
            self.inTerm = False

        
    # Call when a character is read
    def characters(self, content):
        if self.CurrentData == "id":
            self.id = content
        elif self.CurrentData == "is_a":
            self.is_a = content
        elif self.CurrentData == "type":
            self.type = content
        elif self.CurrentData == "to":
            self.to = content
   
        
if ( __name__ == "__main__"):
    db_path = "/home/dcslbw/Workspace/eclipse/neo4j_import/db/test"
    GO_xml_path = "/home/dcslbw/Workspace/iOmics/neo4j/setup/go_daily-termdb.obo-xml"
    # remove existing database directory
    if os.path.exists(db_path):
        shutil.rmtree(db_path, False, None)
    inserter = BatchInserters.inserter( db_path )
    indexProvider = LuceneBatchInserterIndexProvider( inserter )
    GO = indexProvider.nodeIndex( "GO", MapUtil.stringMap( "type", "exact" ) )
    # 402900 go terms
    GO.setCacheCapacity( "id", 420000 )
    # node id hash
    Nodes = {}
    
    # create an XMLReader
    parser = xml.sax.make_parser()
    # turn off namepsaces
    parser.setFeature(xml.sax.handler.feature_namespaces, 0)
    # override the default ContextHandler
    
    # Insert nodes
    Handler = GONodeHandler(GO, inserter, Nodes)
    parser.setContentHandler( Handler )
    parser.parse(GO_xml_path)
    
    # make the changes visible for reading, use this sparsely, requires IO!
    GO.flush()
    
    print "Length of Nodes: ", len(Nodes)
    # Insert relationships
    Handler = GOEdgeHandler(GO, inserter, Nodes)
    parser.setContentHandler( Handler )
    parser.parse(GO_xml_path)
    
    # make the changes visible for reading, use this sparsely, requires IO!
    GO.flush()
    
    # shutdown
    indexProvider.shutdown();
    inserter.shutdown();


