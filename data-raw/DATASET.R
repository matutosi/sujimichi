# neko_words: the content words of the opening of 『吾輩は猫である』
#
# The text is out of copyright (Natsume Soseki, died 1916), and comes by
# way of moranajp::neko_chamame, a morpheme table made with 'chamame'.
# The table was first prepared in the anabass package (2024), which
# sujimichi replaced; it was carried over when anabass was archived.
#
# The columns are renamed to the ones sujimichi uses, and `position` is
# the order of the word among the content words of its sentence.  The
# raw sentences are not kept, so the table suits connect_sentences() and
# dead_code(), not the displays, which need the text to indent.
#
# Rebuild with:  Rscript data-raw/DATASET.R
# It needs the anabass copy of the data, or moranajp for a fresh one.

path <- "../anabass/data/neko_sentences.rda"
if(!file.exists(path)) stop("no neko_sentences.rda at ", path)
e <- new.env()
load(path, envir = e)
d <- as.data.frame(e$neko_sentences)

d <- d[order(d$sentence), c("sentence", "word")]
neko_words <- tibble::tibble(
  sentence_id = as.integer(d$sentence),
  position    = as.integer(stats::ave(seq_len(nrow(d)), d$sentence,
                                      FUN = seq_along)),
  word        = as.character(d$word))

save(neko_words, file = "data/neko_words.rda",
     compress = "bzip2", version = 2)
