#!/usr/bin/env Rscript
library(igraph)
library(RJSONIO)
library(RCurl)

#--Params
KO=args[1]
rank='family'
system(sprintf("echo -e \"LCA.taxid\trank\tGLO\tcount\" > out/seq.0223/%s-%s-GLOS", KO, rank))
familytaxids=system(paste("ls out/seq.0222/",KO,"-",rank,"-* | perl -ne '/\\-(\\d+)/; print qq($1\n)'",sep=""),int=T)

query<-"start pathway=node:pathwayid(pathway={pathway}) match pathway--(ko:`ko`)<-[r]-(cpd:`cpd`) return ko.ko,cpd.cpd;"
query<-"start pathway=node:pathwayid(pathway={pathway}) match pathway--(ko:`ko`)<-[r]-(cpd:`cpd`) return ko.ko AS node"
query<-"start pathway=node:pathwayid(pathway={pathway}) match pathway--(ko:`ko`)<-[r]-(cpd:`cpd`) return cpd.cpd AS node"
params="path:ko00010"
    post=toJSON(
	    list(
		query=query,
		params=list(pathway=params)
		)
	    )

result=fromJSON(
	getURL("http://localhost:7474/db/data/cypher", 
	customrequest='POST', 
	httpheader=c('Content-Type'='application/json'), 
	postfields=post
	)
	)
edges=do.call(rbind,(result$data))
kos=unique(unlist(result$data))
cpd=unique(unlist(result$data))

output=graph.data.frame(edges)
