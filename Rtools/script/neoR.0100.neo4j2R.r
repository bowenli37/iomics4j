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

##################################################
#Export subgraph from cypher query into igraph   #
##################################################
library(igraph)

#attributes file


#relationship file


##################################################
#Comments
#result from curlPerform returns a table in the form of a list, length 2: 
#[1]names of the columns

#[2]List of rows
#eg result[[2]][[n]] 		where n is the row num 
