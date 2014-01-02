#!/usr/bin/env Rscript
library('RCurl')
library('RJSONIO')

##################################################
#--Step1: Set the cypher query 
#NOTE: Rmbr to escape double quotes accordingly 
##################################################
q<-"start read = node:readID('readid:\"HWI-ST884:57:1:1101:13989:75421#0\"') 
match read-[r1]->gi-->tax-->tax2-[:childof*]->common_ancestor<-[:childof*]-tax3<--gi<-[r2]-read
where r1.bitscore > \"35\" and r2.bitscore > \"35\" return common_ancestor;"

##################################################
#--Step2: query FUNCTION
##################################################
query <- function(querystring) {
  h = basicTextGatherer()
  curlPerform(url="http://localhost:7474/db/data/cypher",
    postfields=paste('query',curlEscape(querystring), sep='='),
    writefunction = h$update,
    verbose = FALSE
  )           
  result <- fromJSON(h$value())
data=setNames(data.frame(
do.call(rbind,lapply(result$data, function(row) { 
sapply(row, function(column) column$data)
}))
), result$columns)
  data
}

data<-query(q)

##################################################
#Saves the output as a data.frame
##################################################
save(data, file="output.rda")



##################################################
#Comments
#result from curlPerform returns a table in the form of a list, length 2: 
#[1]names of the columns

#[2]List of rows
#eg result[[2]][[n]] 		where n is the row num 
