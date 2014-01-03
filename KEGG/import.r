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
sapply(xml_data, function(x) { 
    if("substrate" %in% names(x) { 
#the reaction name
rxnID=x$.attrs[[2]]
#retrieves the enzymes which work for this reaction
subset(kos, reaction == rxnID)



   paste(sapply(which(names(x) == 'substrate'), function(subs) { 
	x[[subs]][[2]]
   }), collapse=" ")



   x[which(names(x) == 'product')]
    }
})
