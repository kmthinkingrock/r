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
decks.data.frame<-data.frame(did = names(decksnames), name = decksnames, stringsAsFactors=FALSE)

collection=list(models = models.data.frame, decks = decks.data.frame)

revlog<-tbl_df(dbGetQuery(worklist[["db"]], "select cast(a.cid as text) cid,
		       cast(b.did as text) did,
		       cast(b.nid as text) nid,
		       cast(c.mid as text) mid, a.ease, a.ivl rivl, a.lastivl, a.factor rfactor, a.[time], a.type rtype, b.type ctype, b.queue, b.due, b.ivl civl, b.factor cfactor, b.reps, b.lapses, b.[left], b.odue, a.id / 1000 as epochsecs, datetime(a.id / 1000, 'unixepoch') as datestr from revlog a join cards b on b.id = a.cid join notes c on c.id = b.nid"))

dbDisconnect(worklist[["db"]])
worklist[["db"]]<-NULL


# from revlog!
deckmodelcombos <- distinct(select(revlog, did, mid))

merge1<-merge(deckmodelcombos,decks.data.frame)#,by.x="did",by.y="id")
xxxxx<-merge(merge1, models.data.frame)

nov10<-filter(revlog, str_detect(revlog$datestr, "2015-11-10"))

## date procesing - still fiddling with it
select(filter(mutate(revlog, revtime = as.POSIXct(datestr, "UTC"), revday = strftime(revtime, "%F")), datestr < '2015-11-11'), revday, ease)

## experimentation with "abbreviate" to shorten deck names
## algorithm should be different
decks.data.frame$abbr <- abbreviate(str_replace_all(decksnames, "::", " "), minlength=12, method="both")

#merge(revlog, decks.data.frame)

#collection$decks$abbr = abbrs

#merge(decks.data.frame, 
#print(as.data.frame(abbrs))

