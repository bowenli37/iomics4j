from org.neo4j.unsafe.batchinsert import BatchInserters
from org.neo4j.graphdb import *
from org.neo4j.index.lucene.unsafe.batchinsert import LuceneBatchInserterIndexProvider
from org.neo4j.helpers.collection import MapUtil
from Bio import SwissProt
from math import fmod
import shutil, os, xml.sax, glob, gzip, csv, time

# GO node creation
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
        self.Nodes = Nodes
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
            self.Nodes[self.id] = Node
            
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

# GOEdge creation
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
        self.Nodes = Nodes
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
            if self.Nodes.has_key(self.id):
                sNode = self.Nodes[self.id]
            else:
                print "self.id does not exist: ", self.id, ", ", self.to
            # get target node from the relationship
            if self.Nodes.has_key(self.to):    
                tNode = self.Nodes[self.to]
            else:
                print "self.to deoes not exist: ", self.id, ", ", self.to
            self.inserter.createRelationship(sNode, tNode, DynamicRelationshipType.withName( self.type ), None)
        elif tag == "is_a" and self.inTerm:
            # get source node for the relationship
            if self.Nodes.has_key(self.id):
                sNode = self.Nodes[self.id]
            else:
                print "self.id does not exist: ", self.id, ", ", self.is_a
            # get target node from the relationship
            if self.Nodes.has_key(self.is_a):
                tNode = self.Nodes[self.is_a]
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
            
# Pubmed xml handler
class PubmedHandler( xml.sax.ContentHandler ):
    def __init__(self, nodeIndex, inserter, Nodes):
        self.CurrentData = ""
        self.id = ""
        self.PubDate = ""
        self.Source = ""
        self.LastAuthor = ""
        self.Title = ""
        self.totalTerm = 0
        self.nodeIndex = nodeIndex
        self.inserter = inserter
        self.Nodes = Nodes
        self.NodeLabel = DynamicLabel.label( "Pubmed" );
        
    # Call when an element starts
    def startElement(self, tag, attributes):
        if tag == "Id":
            self.CurrentData = tag
        elif tag == "Item":
            item_name = attributes.getValue("Name")
            if item_name == "PubDate" or item_name == "Source" or item_name == "LastAuthor" or item_name == "Title":
                self.CurrentData = item_name
        elif tag == "DocSum":
            self.totalTerm += 1
        
    # Call when an elements ends
    def endElement(self, tag):
        self.CurrentData = ""
        
        if fmod(self.totalTerm, 1000) == 0 and tag == "DocSum":
            print self.totalTerm
        
        if tag == "DocSum" and not self.Nodes.has_key(self.id):
            properties = MapUtil.map( "id", self.id )
            properties.put("PubDate", self.PubDate)
            properties.put("Source", self.Source)
            properties.put("LastAuthor", self.LastAuthor)
            properties.put("Title", self.Title)
            Node = self.inserter.createNode(properties, self.NodeLabel)
            self.nodeIndex.add( Node, properties )
            # save Node in Nodes 
            self.Nodes[self.id] = Node
            
    # Call when a character is read
    def characters(self, content):
        if self.CurrentData == "Id":
            self.id = content
        elif self.CurrentData == "PubDate":
            self.PubDate = content
        elif self.CurrentData == "Source":
            self.Source = content
        elif self.CurrentData == "LastAuthor":
            self.LastAuthor = content
        elif self.CurrentData == "Title":
            self.Title = content


class iomics4j:
    def __init__(self):
        # Global variable
        self.db_path = "/home/dcslbw/Workspace/eclipse/neo4j_import/db/test"
        self.infile_SwissProt = "/data/PhD/iomics4j/uniprot_sprot_human.dat.gz"
        self.infile_trembl = "/data/PhD/iomics4j/uniprot_trembl_human.dat.gz"
        self.infile_GO = "/data/PhD/iomics4j/go_daily-termdb.obo-xml.gz"
        self.infile_PubMed = "/data/PhD/iomics4j/pubmed/*.gz"
        self.infile_NCBIGene = '/data/PhD/iomics4j/Homo_sapiens.gene_info.gz'
        self.infile_gene2pubmed = "/data/PhD/iomics4j/gene2pubmed.gz"
        self.cache_capacity_uniprot = 140000
        self.cache_capacity_go = 420000
        self.cache_capacity_pubmed = 1000000
        self.cache_capacity_ncbigene = 10000
        self.NODES_PUBMED = {}
        self.NODES_NCBIGENE = {}
        self.NODES_GO = {}
        self.NODES_UNIPROT = {}
        
        if os.path.exists(self.db_path):
            shutil.rmtree(self.db_path, False, None)
        self.inserter = BatchInserters.inserter( self.db_path )
        self.indexProvider = LuceneBatchInserterIndexProvider( self.inserter )
        
    def close(self):
        self.indexProvider.shutdown();
        self.inserter.shutdown();
    
    def import_go(self):
        GO = self.indexProvider.nodeIndex( "GO", MapUtil.stringMap( "type", "exact" ) )
        # 402900 go terms
        GO.setCacheCapacity( "id", self.cache_capacity_go )
        
        # create an XMLReader
        parser = xml.sax.make_parser()
        # turn off namepsaces
        parser.setFeature(xml.sax.handler.feature_namespaces, 0)
        # override the default ContextHandler
        
        # Insert nodes
        Handler = GONodeHandler(GO, self.inserter, self.NODES_GO)
        parser.setContentHandler( Handler )
        with gzip.open(self.infile_GO, "rb") as f:
            parser.parse(f)
        
        # make the changes visible for reading, use this sparsely, requires IO!
        GO.flush()
        
        print "Length of Nodes: ", len(self.NODES_GO)
        # Insert relationships
        Handler = GOEdgeHandler(GO, self.inserter, self.NODES_GO)
        parser.setContentHandler( Handler )
        with gzip.open(self.infile_GO, "rb") as f:
            parser.parse(f)
        
        # make the changes visible for reading, use this sparsely, requires IO!
        GO.flush()
    
    def import_pubmed(self):
        # create an XMLReader
        parser = xml.sax.make_parser()
        # turn off namepsaces
        parser.setFeature(xml.sax.handler.feature_namespaces, 0)
        # override the default ContextHandler
        
        # Insert nodes
        PUBMED_ID = self.indexProvider.nodeIndex( "PUBMED_ID", MapUtil.stringMap( "type", "exact" ) );
        PUBMED_ID.setCacheCapacity( "GeneID", self.cache_capacity_pubmed ); # 406362 lines
        Handler = PubmedHandler(PUBMED_ID, self.inserter, self.NODES_PUBMED)
        parser.setContentHandler( Handler )
    
        for gzfile in glob.iglob(self.infile_PubMed):
            print "Importing", gzfile
            with gzip.open(gzfile, 'rb') as f:
                parser.parse(f)
            
        # make the changes visible for reading, use this sparsely, requires IO!
        PUBMED_ID.flush() 
    
    def import_ncbigene(self):
        print "Import NCBI Genes, depends on PubMed"
            # Part I: Insert NCBI_genes
        NCBI_GENE = self.indexProvider.nodeIndex( "NCBI_GENE", MapUtil.stringMap( "type", "exact" ) );
        NCBI_GENE.setCacheCapacity( "GeneID", self.cache_capacity_ncbigene ); # 9702 lines
        
        
        nrow = 1
        NodeLabel = DynamicLabel.label( "Gene" );
        
        print "Importing", self.infile_NCBIGene
        with gzip.open(self.infile_NCBIGene) as f:
            reader = csv.reader(f, delimiter = "\t")
            for line in reader:
                if nrow == 1:
                    header = line[0].strip().split('(')[0] # exclude text in ()
                    colnames = header.split(' ')[1:16] # exclude #format
                elif nrow > 1:
                    #===============================================================
                    # for i in xrange(len(line)):
                    #     print i, colnames[i], ":", line[i]
                    #===============================================================
                    properties = MapUtil.map( "GeneID",  line[1])
                    for i in [0] + range(2, 15):
                        properties.put(colnames[i], line[i])
                    Node = self.inserter.createNode( properties, NodeLabel )
                    NCBI_GENE.add( Node, properties )
                    # add id to Nodes
                    self.NODES_NCBIGENE[line[1]] = Node
                else:
                    break
                if fmod(nrow, 1000) == 0:
                    print "Imported", nrow, "genes"
                nrow += 1
        NCBI_GENE.flush()
        
        # Part III: Insert relationships between genes and pubmed articles
        
        nrow = 1
        npair = 0
        
        print "Importing:", self.infile_gene2pubmed
        with gzip.open(self.infile_gene2pubmed) as f:
            reader = csv.reader(f, delimiter = "\t")
            for line in reader:
                if nrow > 1:
                    tax_id, GeneID, Pubmed_ID = line
                    if tax_id == "9606":
                        if self.NODES_NCBIGENE.has_key(GeneID) and self.NODES_PUBMED.has_key(Pubmed_ID):
                            if fmod(npair, 1000) == 0 and npair >= 1000:
                                print "Imported", npair, "gene pubmed pairs"
                            self.inserter.createRelationship(self.NODES_NCBIGENE[GeneID], self.NODES_PUBMED[Pubmed_ID], DynamicRelationshipType.withName( "Ref" ), None)
                            npair += 1
                nrow += 1
                
    def import_uniprot(self):
        print "Import Uniprot, depends on GO, NCBI_GENE and PubMed"
        uniprot = self.indexProvider.nodeIndex( "UNIPROT", MapUtil.stringMap( "type", "exact" ) );
        uniprot.setCacheCapacity( "entry_name",  self.cache_capacity_uniprot );
        NodeLabel = DynamicLabel.label( "Protein" );
        Protein_Pubmed_Edge_Type = DynamicRelationshipType.withName( "Ref" )
        Protein_Gene_Edge_Type = DynamicRelationshipType.withName( "FromGene" )
        Protein_GOCC_Edge_Type = DynamicRelationshipType.withName( "GOCC" )
        Protein_GOMF_Edge_Type = DynamicRelationshipType.withName( "GOMF" )
        Protein_GOBP_Edge_Type = DynamicRelationshipType.withName( "GOBP" )
        
        nNodes = 0
        for infile in [self.infile_SwissProt, self.infile_trembl]:
            with gzip.open(infile, "rb") as f:
                for record in SwissProt.parse(f):
                    nNodes += 1
                    if fmod(nNodes, 1000) == 0:
                        print "Number of protein in Nodes:", nNodes
                    
                    # set node properties
                    properties = MapUtil.map( "entry_name", record.entry_name )
                    if record.data_class:
                        properties.put("data_class", record.data_class)
                    if record.molecule_type:
                        properties.put("molecule_type", record.molecule_type)
                    if record.sequence_length:
                        properties.put("sequence_length", record.sequence_length)
                    if len(record.accessions) > 0:
                        properties.put("accessions", record.accessions[0])
                    if record.gene_name:
                        properties.put("gene_name", record.gene_name[5:-1])
                    
                    # create node
                    node = self.inserter.createNode(properties, NodeLabel)
                    uniprot.add( node, properties )
                    # save Node in Nodes 
                    self.NODES_UNIPROT[record.entry_name] = node
                    
                    # Create edge to pubmed
                    for ref in record.references:
                        if len(ref.references) > 0:
                            if ref.references[0][0] == "PubMed":
                                Pubmed_ID = ref.references[0][1]
                                if self.NODES_PUBMED.has_key(Pubmed_ID):
                                    self.inserter.createRelationship(node, self.NODES_PUBMED[Pubmed_ID], Protein_Pubmed_Edge_Type, None)
        
                    # Create edge to GO and NCBI_GENE
                    for ref in record.cross_references:
                        if ref[0] == "GeneID":
                            GeneID = ref[1]
                            if self.NODES_NCBIGENE.has_key(GeneID):
                                self.inserter.createRelationship(node, self.NODES_NCBIGENE[GeneID], Protein_Gene_Edge_Type, None)
                        elif ref[0] == "GO":
                            GOID = ref[1]
                            GOType = ref[2][0] # C: cellular compartment; F: molecular function; P: biological process
                            if self.NODES_GO.has_key(GOID):
                                if GOType == "C":
                                    self.inserter.createRelationship(node, self.NODES_GO[GOID], Protein_GOCC_Edge_Type, None)
                                if GOType == "F":
                                    self.inserter.createRelationship(node, self.NODES_GO[GOID], Protein_GOMF_Edge_Type, None)
                                if GOType == "P":
                                    self.inserter.createRelationship(node, self.NODES_GO[GOID], Protein_GOBP_Edge_Type, None)         
            
        uniprot.flush()

if ( __name__ == "__main__"):
    time0 = time.time()

    db = iomics4j()
    db.import_go()
    db.import_pubmed()
    db.import_ncbigene()
    db.import_uniprot()
    
    time1 = time.time()
    print 'Finished in %0.3f s' % (time1-time0)
    db.close()
    
    
