Sys.setenv(LANG = "en")

## keep this for future reference, peut-etre
script.dir <- dirname(sys.frame(1)$ofile)

source(paste(script.dir, "loadlibs.R", sep="/"))
source(paste(script.dir, "r-anki-lib.R", sep="/"))

worklist=list(db = connectAnkiCollection("c:\\users\\kay\\documents\\anki\\user 1\\collection.anki2"))

ankiDb.table.col<-dbReadTable(worklist[["db"]], "col", NULL, TRUE, "*")
decks<-fromJSON(ankiDb.table.col$decks)
models<-fromJSON(ankiDb.table.col$models)
#collection=data.frame(decks = decks, models = models)

notes.db.table<-dbReadTable(worklist[["db"]], "notes", NULL, T, "id did, mid, mod, tags, sfld")

model.names <- unlist(lapply(models, function(x) { x$name }))
model.ids <- unlist(lapply(models, function(x) { x$id }))
model.field.counts <- unlist(lapply(models, function(x) { nrow(x$flds) }))
models.data.frame <- data.frame(num.fields = model.field.counts, model.name = model.names, mid = model.ids)

#names(decks)[lapply(decks, function(x) { is.matrix(x$terms) }) == FALSE]

# delete dynamic decks
decks[names(decks)[lapply(decks, function(x) { is.matrix(x$terms) }) == TRUE]] <- NULL

decksnames=unlist(lapply(decks, function(x) { x$name }))
decks.data.frame<-data.frame(
	did = names(decksnames), name = decksnames,
	desc = unlist(lapply(decks, function(x) { x$desc })),
 	stringsAsFactors=FALSE)

collection=list(models = models.data.frame, decks = decks.data.frame)

revlog<-tbl_df(dbGetQuery(worklist[["db"]], "select cast(a.cid as text) cid,
		       cast(b.did as text) did,
		       cast(b.nid as text) nid,
		       cast(c.mid as text) mid, a.ease, a.ivl rivl, a.lastivl, a.factor rfactor, a.[time], a.type rtype, b.type ctype, b.queue, b.due, b.ivl civl, b.factor cfactor, b.reps, b.lapses, b.[left], b.odue, a.id / 1000 as epochsecs, datetime(a.id / 1000, 'unixepoch') as datestr from revlog a join cards b on b.id = a.cid join notes c on c.id = b.nid"))

dbDisconnect(worklist[["db"]])
worklist[["db"]]<-NULL

# from revlog! should be otherwise
deckmodelcombos <- distinct(select(revlog, did, mid))

merge1<-merge(deckmodelcombos,decks.data.frame)#,by.x="did",by.y="id")
xxxxx<-merge(merge1, models.data.frame)

nov10<-filter(revlog, str_detect(revlog$datestr, "2015-11-10"))

nov10merged=merge(nov10, decks.data.frame, x.by="id", y.by="did")
barplot<-ggplot(nov10merged, aes(x=abbr)) + geom_bar() +theme(axis.text.x=element_text(angle=30, hjust=1, vjust=1))

## date procesing - still fiddling with it
#select(filter(
revlog=mutate(revlog, revtime = as.POSIXct(datestr, "UTC"), revday = strftime(revtime, "%F"), revday.posixct=as.POSIXct(revday))
#, datestr < '2015-11-11'), revday, ease)

## experimentation with "abbreviate" to shorten deck names
## algorithm should be different
decks.data.frame$abbr <- abbreviate(str_replace_all(decksnames, "::", " "), minlength=12, method="both")

rpl<-str_replace(decks.data.frame$name, "^.*::", "")
rpl[duplicated(rpl)] = abbreviate(decks.data.frame$name[duplicated(rpl)],minlength=8)
decks.data.frame$short <- rpl

## merge abbreviations and short names of decks
revlog=merge(revlog, decks.data.frame)

#collection$decks$abbr = abbrs

#merge(decks.data.frame, 
#print(as.data.frame(abbrs))


endDate = as.POSIXct(Sys.Date())
beginDate = seq(endDate, by="-1 year", length.out=2)[2]
period.review.log=filter(revlog, revtime >= beginDate & revtime <= endDate)

barplot<-ggplot(period.review.log, aes(x=revday.posixct))
plot<-barplot + stat_bin(binwidth=86400*2)
