Sys.setenv(LANG = "en")

library(RSQLite)
library(stringr)
library(dplyr)
library(jsonlite)

db<-dbConnect(SQLite(), "c:\\users\\kay\\documents\\anki\\user 1\\collection.anki2")

col<-dbReadTable(db, "col", NULL, TRUE, "*")
decks<-fromJSON(col$decks)
models<-fromJSON(col$models)

notes.db.table<-dbReadTable(db, "notes", NULL, T, "id did, mid, mod, tags, sfld")

model.names <- lapply(models, function(x) { x$name })
model.ids <- unlist(lapply(models, function(x) { x$id }))
model.field.counts <- lapply(models, function(x) { nrow(x$flds) })

# from revlog!
deckmodelcombos <- distinct(select(revlog, did, mid))

models.data.frame <- data.frame(num.fields = model.field.counts, model.name = model.names, mid = model.ids)

decksnames=unlist(lapply(decks, function(x) { x$name }))
decksdf<-data.frame(id = names(decksnames), name = decksnames)

xxxxx<-merge(merge(deckmodelcombos, decksdf), models.data.frame)

revlog<-tbl_df(dbGetQuery(db, "select cast(a.cid as text) cid,
		       cast(b.did as text) did,
		       cast(b.nid as text) nid,
		       cast(c.mid as text) mid, a.ease, a.ivl rivl, a.lastivl, a.factor rfactor, a.[time], a.type rtype, b.type ctype, b.queue, b.due, b.ivl civl, b.factor cfactor, b.reps, b.lapses, b.[left], b.odue, a.id / 1000 as epochsecs, datetime(a.id / 1000, 'unixepoch') as datestr from revlog a join cards b on b.id = a.cid join notes c on c.id = b.nid"))

decksnames=unlist(lapply(decks, function(x) { x$name }))
decksdf=data.frame(id = names(decksnames), name = decksnames)

## experimentation with "abbreviate" to shorten deck names
## algorithm should be different
abbrs=abbreviate(str_replace_all(decksnames, "::", " "), minlength=12, method="both")
as.data.frame(abbrs)

		      
summary(as.POSIXct(sort(times[[1]]), origin="1970-01-01"))
