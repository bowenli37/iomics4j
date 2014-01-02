#!/usr/bin/env Rscript
library('RCurl')
library('RJSONIO')

#query FUNCTION
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

q<-"start read = node:readID('readid:\"HWI-ST884:57:1:1101:13989:75421#0\"') 
match read-[r1]->gi-->tax-->tax2-[:childof*]->common_ancestor<-[:childof*]-tax3<--gi<-[r2]-read
where r1.bitscore > \"35\" and r2.bitscore > \"35\" return common_ancestor;"
data<-query(q)

#result list of 2: names(result) [1] columns data
#1st list: var eg. read & gi

#2nd list: rows
#result[[2]][[n]] 		where n is the row num 
  
#data
#data[x] where x reps the column
