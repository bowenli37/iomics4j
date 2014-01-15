#!/usr/bin/env Rscript
library(igraph)
library(RJSONIO)
library(RCurl)

#To generate edges for graph.data.frame
query<-"start pathway=node:pathwayid(pathway={pathway}) match pathway--(ko:`ko`)-[r]-(cpd:`cpd`) return ko.ko,cpd.cpd;"
params<-"path:ko00010"

#query<-"start pathway=node:pathwayid(pathway={pathway}) match pathway--(ko:`ko`)<-[r]-(cpd:`cpd`) return ko.ko AS node"
#query<-"start pathway=node:pathwayid(pathway={pathway}) match pathway--(ko:`ko`)-[r]-(cpd:`cpd`) return cpd.cpd AS node"

#Querying neo4j ####################################
post=toJSON(
	    list(
		query=query,
		params=list(pathway=params)
		)
	    )
result=fromJSON(
	getURL("http://192.168.100.1:7474/db/data/cypher", 
	customrequest='POST', 
	httpheader=c('Content-Type'='application/json'), 
	postfields=post
	)
	)
##################################################

edges=do.call(rbind,(result$data))
#kos=unique(unlist(result$data))
#cpd=unique(unlist(result$data))

graph.obj=graph.data.frame(edges)
