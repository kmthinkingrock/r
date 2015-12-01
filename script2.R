Sys.setenv(LANG = "en")
##
## Variable list
##
## script.dir			relative or absolute path to scripts
## collection.anki2.path	Path to collection.anki2 SQLite database
## worklist			a list containing "work" variables
## 				right now just "db"
## ankiDb.table.col		the "col" table
## decks			col.decks parsed JSON
## models			col.models parsed JSON
## notes.db.table		contents of "notes" taable
## model.names			names of models
## model.ids			ids of models
## models.field.counts		model field counts
## models.data.frame		data frame representing all models

## keep this for future reference, peut-etre
script.dir <- dirname(sys.frame(1)$ofile)

source(paste(script.dir, "loadlibs.R", sep="/"))
source(paste(script.dir, "r-anki-lib.R", sep="/"))
source(paste(script.dir, "localconf.R", sep="/"))

if(!file.exists(collection.anki2.path))
{
    stop(paste("Anki2 Collection file does not exist (",
         collection.anki2.path, ")"))
}

worklist <- list(db = connectAnkiCollection(collection.anki2.path))
print(worklist[["db"]])

ankiDb.table.col <- dbReadTable(worklist[["db"]], "col", NULL, TRUE, "*")

decks <- fromJSON(ankiDb.table.col$decks)
models <- fromJSON(ankiDb.table.col$models)

notes.db.table <- dbReadTable(worklist[["db"]],
			      "notes", NULL, T, "cast(id as text) did, mid, mod, tags, sfld")
cards.db.table <- tbl_df(dbReadTable (
	       worklist[["db"]], "cards", NULL, T,
	       "cast(id as text) cid, nid, cast(did as text) did, ord,
	       mod, usn, type, queue,
	             due, ivl, factor, reps, lapses, left, odue, odid"
))

cards.db.table = mutate(cards.db.table, t=ifelse(queue == 2 & ivl >= 21, "mature", ifelse((queue == 1 | queue == 3) | (queue == 2 & ivl < 21), "young", ifelse(queue == 0, "new", ifelse(queue < 0, "suspended", NA)))))

model.names		<- unlist(lapply(models, function(x) { x$name }))
model.ids		<- unlist(lapply(models, function(x) { x$id }))
model.field.counts	<- unlist(lapply(models, function(x) { nrow(x$flds) }))
models.data.frame	<- data.frame(num.fields	= model.field.counts,
				      model.name	= model.names,
				      mid		= model.ids)

# delete dynamic decks
decks[names(decks)[lapply(decks,
	function(x) { is.matrix(x$terms) }) == TRUE]] <- NULL

decksnames <- unlist(lapply(decks, function(x) { x$name }))
decks.data.frame <- data.frame(
	did = names(decksnames), name = decksnames,
	desc = unlist(lapply(decks, function(x) { x$desc })),
 	stringsAsFactors=FALSE)

## experimentation with "abbreviate" to shorten deck names
## algorithm should be different
decks.data.frame$abbr <- abbreviate(str_replace_all(decksnames, "::", " "), minlength=12, method="both")

rpl <- str_replace(decks.data.frame$name, "^.*::", "")
rpl[duplicated(rpl)] <- abbreviate(decks.data.frame$name[duplicated(rpl)],minlength=8)
decks.data.frame$short <- rpl

collection <- list(models = models.data.frame, decks = decks.data.frame)

revlog <- tbl_df(dbGetQuery(worklist[["db"]], "select cast(a.cid as text) cid,
		       cast(b.did as text) did,
		       cast(b.nid as text) nid,
		       cast(c.mid as text) mid,
		       a.ease, a.ivl rivl, a.lastivl, a.factor rfactor,
		       a.[time], a.type rtype, b.type ctype,
		       b.queue, b.due, b.ivl civl, b.factor cfactor,
		       b.reps, b.lapses, b.[left], b.odue,
		       a.id / 1000 as epochsecs,
		       datetime(a.id / 1000, 'unixepoch') as datestr
		       from revlog a join cards b on b.id = a.cid
		       join notes c on c.id = b.nid"))

## We're done with DB
dbDisconnect(worklist[["db"]])
worklist[["db"]] <- NULL

svg("decks.svg", width=8, height=6)
print(ggplot(decks.data.frame, aes(y=short, x=0,label=name,xmin=0,xmax=1)) + geom_text(aes(hjust=0)) + scale_x_continuous("Deck Name") + theme(panel.grid = element_blank(), axis.ticks.x=element_blank(), axis.text.x=element_blank()))
#print(ggplot(decks.data.frame, aes(y=short, x="",label=name,xmin=0,xmax=0)) + geom_text(aes(hjust=1)) + scale_x_discrete("Deck Name"))
dev.off()

c=tbl_df(cards.db.table)
c2=merge(c, decks.data.frame)
c2$did = factor(c$did)
svg("cardcountbydeck.svg", width=6, height=4)
print(ggplot(c2, aes(x=short, fill=t)) + geom_bar() + theme(axis.text.x=element_text(angle=30, hjust=1, vjust=1)) + ylab("Card Count") + xlab("Deck") + ggtitle("Card Count by Anki Deck") + scale_fill_manual(values = c("dark green", "#3366cc", "yellow", "light green")))

dev.off()

# how to determine status of cards
#select
#sum(case when queue=2 and ivl >= 21 then 1 else 0 end), -- mtr
#sum(case when queue in (1,3) or (queue=2 and ivl < 21) then 1 else 0 end), -- yng/lrn
#sum(case when queue=0 then 1 else 0 end), -- new
#sum(case when queue<0 then 1 else 0 end) -- susp
#from cards where did in %s""" % self._limit())


# from revlog! should be otherwise
deckmodelcombos <- distinct(select(revlog, did, mid))

merge1 <- merge(deckmodelcombos,decks.data.frame)#,by.x="did",by.y="id")
xxxxx <- merge(merge1, models.data.frame)

#derp
nov10 <- filter(revlog, str_detect(revlog$datestr, "2015-11-10"))

nov10merged <- merge(nov10, decks.data.frame, x.by="id", y.by="did")
barplot <- ggplot(nov10merged, aes(x=abbr)) + geom_bar() +theme(axis.text.x=element_text(angle=30, hjust=1, vjust=1))

## date procesing - still fiddling with it
#select(filter(
revlog <- mutate(revlog, revtime = as.POSIXct(datestr, "UTC"), revday = strftime(revtime, "%F"), revday.posixct=as.POSIXct(revday))
#, datestr < '2015-11-11'), revday, ease)


## merge abbreviations and short names of decks
revlog <- merge(revlog, decks.data.frame)

# uncertain gibberish
#collection$decks$abbr = abbrs

#merge(decks.data.frame, 
#print(as.data.frame(abbrs))

# omg variables
endDate <- as.POSIXct(Sys.Date())
beginDate <- seq(endDate, by="-1 year", length.out=2)[2]
period.review.log <- filter(revlog, revtime >= beginDate & revtime <= endDate)

# a plot
barplot <- ggplot(period.review.log, aes(x=revday.posixct))
plot <- barplot + stat_bin(binwidth=86400*2)

# kind of interesting plot
ggplot(filter(revlog, revtime >= '2015-11-11'), aes(x=revtime,y=time,colour=ease))+geom_point(alpha=.3)

ggplot(filter(mutate(revlog, easef = factor(ease)), revtime >= '2015-11-11 12:00' & revtime < '2015-11-12'), aes(x=revtime,y=time/1000,colour=easef))+geom_point(alpha=.3) + scale_color_manual(values=c("red", "purple", "green", "blue")) + scale_y_log10() + theme(legend.key = element_rect(fill = "#eeeeee")) + ylab("Seconds to Answer")+ xlab("Review Time") + annotation_logticks(sides="l")

deck.patterns <- c("^French::")
# starting an attempt to filter decks
#match(deck.patterns, 
