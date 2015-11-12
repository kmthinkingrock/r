Sys.setenv(LANG = "en")
script.dir <- dirname(sys.frame(1)$ofile)

source(paste(script.dir, "loadlibs.R", sep="/"))
source(paste(script.dir, "r-anki-lib.R", sep="/"))

worklist=list(db = connectAnkiCollection("c:\\users\\kay\\documents\\anki\\user 1\\collection.anki2"))
db = worklist[["db"]]

col<-dbReadTable(db, "col", NULL, TRUE, "*")
decks<-fromJSON(col$decks)
models<-fromJSON(col$models)
#collection=data.frame(decks = decks, models = models)

notes.db.table<-dbReadTable(db, "notes", NULL, T, "id did, mid, mod, tags, sfld")

model.names <- unlist(lapply(models, function(x) { x$name }))
model.ids <- unlist(lapply(models, function(x) { x$id }))
model.field.counts <- unlist(lapply(models, function(x) { nrow(x$flds) }))
models.data.frame <- data.frame(num.fields = model.field.counts, model.name = model.names, mid = model.ids)

#names(decks)[lapply(decks, function(x) { is.matrix(x$terms) }) == FALSE]

# delete dynamic decks
decks[names(decks)[lapply(decks, function(x) { is.matrix(x$terms) }) == TRUE]] <- NULL

decksnames=unlist(lapply(decks, function(x) { x$name }))
decks.data.frame<-data.frame(id = names(decksnames), name = decksnames)

collection=list(models = models.data.frame, decks = decks.data.frame)

revlog<-tbl_df(dbGetQuery(db, "select cast(a.cid as text) cid,
		       cast(b.did as text) did,
		       cast(b.nid as text) nid,
		       cast(c.mid as text) mid, a.ease, a.ivl rivl, a.lastivl, a.factor rfactor, a.[time], a.type rtype, b.type ctype, b.queue, b.due, b.ivl civl, b.factor cfactor, b.reps, b.lapses, b.[left], b.odue, a.id / 1000 as epochsecs, datetime(a.id / 1000, 'unixepoch') as datestr from revlog a join cards b on b.id = a.cid join notes c on c.id = b.nid"))

# from revlog!
deckmodelcombos <- distinct(select(revlog, did, mid))

xxxxx<-merge(merge(deckmodelcombos, decks.data.frame), models.data.frame)

## date procesing - still fiddling with it
select(filter(mutate(revlog, revtime = as.POSIXct(datestr, "UTC"), revday = strftime(revtime, "%F")), datestr < '2015-11-11'), revday, ease)

## experimentation with "abbreviate" to shorten deck names
## algorithm should be different
abbrs=abbreviate(str_replace_all(decksnames, "::", " "), minlength=12, method="both")
collection$decks$abbr = abbrs
#print(as.data.frame(abbrs))

