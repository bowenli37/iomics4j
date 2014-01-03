#!/usr/bin/env Rscript
args=commandArgs(T)
library(XML)

data=xmlParse(args[1])
#data=xmlParse("~/kegg_dump/xml/kgml/metabolic/ko/ko00010.xml")
xml_data<-xmlToList(data)

#3 types entry/relation/reaction 

#Pathway information
pathway.info=setNames(data.frame(t(xml_data[length(xml_data)]$.attrs)), names(xml_data[length(xml_data)]$.attrs))
#Removes the last row (w/c is the pathway information)
xml_data=xml_data[-length(xml_data)]

#KOs associated with rxn
kos=do.call(rbind, 
	sapply(xml_data, function(x) { 
    	    if("graphics" %in% names(x)) { 
    	    if(x$.attrs[which(names(x$.attrs)=='type')]=='ortholog'){
	    data.frame(
		id=as.character(x$.attrs[names(x$.attrs) == 'id']),
		reaction=as.character(x$.attrs[names(x$.attrs) == 'reaction']),
		name=as.character(x$.attrs[names(x$.attrs) == 'name'])
		)
	    }}}))

#Cpds assoc. with reaction


#Draws the edges
edges=do.call(c,lapply(xml_data, function(x) { 
    if("substrate" %in% names(x)) { 
#the reaction name
rxnID=x$.attrs[[2]]
#reaction type
rxnTYPE=x$.attrs[[3]]

#KOs involved in the reaction
kos.in.pathway_complex=subset(kos, reaction == rxnID)$name
kos.in.pathway=unlist(sapply(kos.in.pathway, function(x) unlist(strsplit(as.character(x), " ")) ))

substrates=sapply(which(names(x) == 'substrate'), function(subs) { x[[subs]][[2]]})

products=paste(sapply(which(names(x) == 'product'), function(subs) { x[[subs]][[2]]}), collapse=" ")

#substrate2ko
sub2ko=do.call(rbind,lapply(substrates, function(s) { 
    do.call(rbind,lapply(kos.in.pathway, function (k) {
    	data.frame(rxnID=rxnID, rxnTYPE=rxnTYPE, substrate=as.character(s),ko=as.character(k))
    }))
    }))

ko2pdt=do.call(rbind,lapply(products, function(s) { 
    do.call(rbind,lapply(kos.in.pathway, function (k) {
    	data.frame(rxnID=rxnID, rxnTYPE=rxnTYPE, product=as.character(s),ko=as.character(k))
    }))
    }))

list(sub2ko, ko2pdt)
    }
}))

sub2ko=do.call(rbind,edges[names(edges)=='reaction1'])
rownames(sub2ko)<-NULL
ko2pdt=do.call(rbind,edges[names(edges)=='reaction2'])
rownames(ko2pdt)<-NULL
