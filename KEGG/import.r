#!/usr/bin/env Rscript

args=commandArgs(T)
library(XML)

data=xmlParse(args[1]) #data=xmlParse("~/kegg_dump/xml/kgml/metabolic/ko/ko00010.xml")
xml_data<-xmlToList(data)

pathway.info=setNames(data.frame(t(xml_data[length(xml_data)]$.attrs)), names(xml_data[length(xml_data)]$.attrs))
xml_data=xml_data[-length(xml_data)]  #Removes the last row (w/c is the pathway information)

#Types in xml files: "ortholog"     "compound"     "map"          "ECrel"        "maplink"      "reversible"   "irreversible"

#--Orthologs (KOs which work in the same reaction##########################
ko2rxn=do.call(rbind, sapply(xml_data, function(x) { 
    	    if("graphics" %in% names(x)) { 
    	    if(x$.attrs[which(names(x$.attrs)=='type')]=='ortholog'){ #there are graphics in the list 
		reaction=unlist(strsplit(x$.attrs[names(x$.attrs) == 'reaction']," "))
		name=unlist(strsplit(x$.attrs[names(x$.attrs) == 'name'], " "))
do.call(rbind,lapply(reaction, function(rxn) { do.call(rbind,lapply(name, function(naa) {data.frame(reaction=rxn,name=naa) }))}))
				}}}))
################################################## NOTE single KO can belong to multiple reactions, reactions may include multiple KOs

nodeindex=c("cpd:char:cpdid","ko:char:koid")
##################################################
#--EDGES
edges=do.call(c,lapply(xml_data[which(names(xml_data) %in% "reaction")], function(x) { 
	    rxnID=unlist(strsplit(x$.attrs[[2]], " "))
	    rxnTYPE=x$.attrs[[3]] 	#reaction type

	    kos.in.pathway=as.character(subset(ko2rxn, reaction == rxnID)$name) #This line hasnt been PUT USE which KOs are part of a bigger protein complex
#	    kos.in.pathway=unlist(sapply(kos.in.pathway_complex, function(x) unlist(strsplit(as.character(x), " ")) ))

	    substrates=lapply(which(names(x) == 'substrate'), function(subs) { x[[subs]][[2]]})
	    products=lapply(which(names(x) == 'product'), function(subs) { x[[subs]][[2]]})
	    
	    lapply(list(substrates, products), function(cpd) {  
	   	do.call(rbind,lapply(cpd, function(s) { 
    		    do.call(rbind,lapply(kos.in.pathway, function (k) {
    			    setNames(data.frame(s,k, rxnID, rxnTYPE,stringsAsFactors=F), c(nodeindex[[1]], nodeindex[[2]],"rxnID","rxnDIR"))
    			    }))		}))		})
    	    }))
sub2ko=unique(do.call(rbind,edges[names(edges)=='reaction1']))
ko2pdt=unique(do.call(rbind,edges[names(edges)=='reaction2']))

#--Output##################################################
#Substrate2KO
sub2koo=cbind(sub2ko, data.frame(relationship='substrateof'))[,c(1,2,5,3)]
koo2sub=cbind(subset(sub2ko, rxnDIR =='reversible')[,c(2,1,3)], data.frame(relationship='produces'))[,c(1,2,4,3)] #reversible reactions

#KO2Pdt
koo2pdt=cbind(ko2pdt[,c(2,1,3)] , data.frame(relationship='produces'))[,c(1,2,4,3)]
pdt2koo=cbind(subset(ko2pdt, rxnDIR =='reversible')[,c(1,2,3)], data.frame(relationship='substrateof'))[,c(1,2,4,3)] #reversible reactions

#Printing out

##################################################

#--NODES
#--KOs

