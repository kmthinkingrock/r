library(RSQLite)
library(stringr)

db<-dbConnect(SQLite(), "c:\\users\\kay\\documents\\anki\\user 1\\collection.anki2")

dbGetQuery(db, "select '' + id from revlog")

emptysr<-""
notes <- dbReadTable(db, "notes", NULL, TRUE, "*")

## process "notes" into unique tag set
u<-setdiff(union(notes$tags, NULL), emptystr)
strim<-str_trim(u)
p<-paste(strim, collapse=" ")
split<-strsplit(p, " ", TRUE, FALSE, FALSE)
tags=unique(split[[1]])
## tags is now unique tag set

out<-rep(FALSE,length(tags))
notetags<-str_trim(notes$tags)
split2<-strsplit(notetags, " ", TRUE, FALSE, FALSE)
nums<-lapply(split2, charmatch, tags)
matrixinput=lapply(nums, function(arg1, arg2){arg2[arg1] <- TRUE; arg2;}, out)
matrixinput=lapply(lapply(matrixinput, matrix,dimnames=list(tags)), t)
final=t(array(unlist(matrixinput), c(length(tags), length(matrixinput)), dimnames=list(tags)))


