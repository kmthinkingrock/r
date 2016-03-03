connectAnkiCollection = function(collectionFile)
{
    dbConnect(SQLite(), collectionFile)
}

anki_load_col = function(db)
{
	col <- dbReadTable(db, "col", NULL, TRUE, "*")
		
	col
}

anki_parse_decks = function(col)
{
	fromJSON(col$decks)
}

anki_process_decks = function(decks)
{
decks[names(decks)[lapply(decks,
	function(x) { is.matrix(x$terms) }) == TRUE]] <- NULL
decksnames <- unlist(lapply(decks, function(x) { x$name }))
decks.data.frame <- data.frame(
	did = names(decksnames), name = decksnames,
	desc = unlist(lapply(decks, function(x) { x$desc })),
 	stringsAsFactors=FALSE)
decks.data.frame$abbr <- abbreviate(str_replace_all(decksnames, "::", " "), minlength=12, method="both")
rpl <- str_replace(decks.data.frame$name, "^.*::", "")
rpl[duplicated(rpl)] <- abbreviate(decks.data.frame$name[duplicated(rpl)],minlength=8)
decks.data.frame$short <- rpl
decks.data.frame$short = factor(decks.data.frame$short)
decks.data.frame
}


anki_parse_models = function(col)
{
	fromJSON(col$models)
}

anki_load_notes = function(db)
{
	dbReadTable(db, "notes", NULL, T, "cast(id as text) did, mid, mod, tags, sfld")
}

anki_load_cards = function(db)
{
	dbReadTable(db, "cards", NULL, T,
	       "cast(id as text) cid, cast(nid as text) nid, cast(did as text) did, ord, mod, usn, type, queue, due, ivl, factor, reps, lapses, left, odue, odid")
}
