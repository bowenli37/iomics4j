from org.neo4j.unsafe.batchinsert import BatchInserters
from org.neo4j.graphdb import DynamicLabel
from org.neo4j.index.lucene.unsafe.batchinsert import LuceneBatchInserterIndexProvider
from org.neo4j.helpers.collection import MapUtil
import gzip, csv, shutil, os    

if ( __name__ == "__main__"):
    db_path = "/home/dcslbw/Workspace/eclipse/neo4j_import/db/test"
    # remove existing database directory
    if os.path.exists(db_path):
        shutil.rmtree(db_path, False, None)
    inserter = BatchInserters.inserter( "db/test" );
    indexProvider = LuceneBatchInserterIndexProvider( inserter );
    NCBI_GENE = indexProvider.nodeIndex( "NCBI_GENE", MapUtil.stringMap( "type", "exact" ) );
    NCBI_GENE.setCacheCapacity( "GeneID", 10000 ); # 9702 lines
    
    infile = '/data/PhD/iomics4j/Homo_sapiens.gene_info.gz'
    nrow = 1
    NodeLabel = DynamicLabel.label( "NCBI_GENE" );
    
    with gzip.open(infile) as f:
        reader = csv.reader(f, delimiter = "\t")
        for line in reader:
            if nrow == 1:
                header = line[0].strip().split('(')[0] # exclude text in ()
                colnames = header.split(' ')[1:16] # exclude #format
            elif nrow > 1:
                for i in xrange(len(line)):
                    print i, colnames[i], ":", line[i]
                properties = MapUtil.map( "GeneID",  line[1])
                for i in [0] + range(2, 15):
                    properties.put(colnames[i], line[i])
                Node = inserter.createNode( properties, NodeLabel )
                NCBI_GENE.add( Node, properties )
            else:
                break
            nrow += 1
            
    #shutdown
    indexProvider.shutdown();
    inserter.shutdown();


