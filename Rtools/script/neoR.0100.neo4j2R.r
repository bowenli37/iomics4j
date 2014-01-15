#!/usr/bin/env Rscript
library('RCurl')
library('RJSONIO')

##################################################
#--Step1: Set the cypher query 
#NOTE: Rmbr to escape double quotes accordingly 
##################################################
q<-"start read = node:readID('readid:\"HWI-ST884:57:1:1101:13989:75421#0\"') match read--(ko:`ko`) return ko.name;"
q<-"start read = node:readID('readid:\"HWI-ST884:57:1:1101:13989:75421#0\"') 
match read-[:rapsearched|childof*]->common_ancestor
return common_ancestor;"

##################################################
#--Step2: query FUNCTION
##################################################
#Cypher queries could be inconsistant (works only for single entry return ie 1 node or 1 property)

query <- function(querystring, type) {
  h = basicTextGatherer()
  curlPerform(url="http://localhost:7474/db/data/cypher",
    postfields=paste('query',curlEscape(querystring), sep='='),
    writefunction = h$update,
    verbose = FALSE
  )           
  result <- fromJSON(h$value())
if(type=='property'){
   data=data.frame(t(sapply(result$data, unlist)))
   names(data)<-result$columns
    }
if(type=='node'){
data=do.call(rbind,lapply(result$data, function(x) data.frame(unlist(x,recursive=F)$data)))
}
if(type='relationship'){
   
}
return(data)
}
data<-query(q,'property')
data<-query(q,'node')


q<-"start 
read=node:readID('readid:\"HWI-ST884:124:D0G92ACXX:1:1101:10761:149051\"')
match read-[:rapsearched]->leaves-[:childof*]->lca
return count (distinct(leaves)) as le
order by le desc;"


##################################################
#Recreate igraph object from cypher query	 #
##################################################
library(igraph)

#attributes file

#Cypher query-- Query must return CPDs, KOs and the relationship type
q="start 
pathway=node:pathwayid('pathway:\"path:ko00061\"')
match pathway--(ko:`ko`)-[r]-(cpd:`cpd`)
return ko,cpd,type(r)"

q="start 
read=node:readID('readid:\"HWI-ST884:124:D0G92ACXX:1:1101:10761:149051\"')
match read-[:rapsearched|childof*]->taxa
return labels(taxa);"


lapply(result$data, function(row){
    ko=row[[1]]$data$ko; cpd=row[[2]]$data[[1]]; relationship=row[[3]]


#relationship file


##################################################
#Comments
#result from curlPerform returns a table in the form of a list, length 2: 
#[1]names of the columns

#[2]List of rows
#eg result[[2]][[n]] 		where n is the row num 
