#' Content words of the opening of 『吾輩は猫である』
#'
#' The content words of the first 148 sentences of Natsume Soseki's
#' 『吾輩は猫である』, one row per word, ready for
#' [connect_sentences()].  It gives a text long enough to try the
#' package on without a morphological analyser at hand, which the three
#' sentences of [sample_text()] are too short for.
#'
#' The words were taken with 'chamame' by way of
#' `moranajp::neko_chamame`, and are lemmas.  The raw sentences are not
#' kept, so the table suits [connect_sentences()] and [dead_code()],
#' not the displays, which need the text to indent.  The whole text is
#' treated as one paragraph, as no paragraph is recorded.
#'
#' The text is out of copyright.  The table was first prepared in the
#' anabass package, which sujimichi replaced.
#'
#' @format A tibble with 910 rows and 3 columns.
#'   * `sentence_id`: the number of the sentence, from 1 to 148.
#'   * `position`: the place of the word among the content words of its
#'     sentence, counted from 1.
#'   * `word`: the word, as a lemma.
#' @source Natsume Soseki 『吾輩は猫である』, through
#'   <https://github.com/matutosi/moranajp>.
#' @examples
#' links <- connect_sentences(neko_words)
#' head(links)
#' sentences <- data.frame(sentence_id = 1:148, paragraph_id = 1L)
#' head(dead_code(links, sentences))
"neko_words"
