#' Remove the citations from a text
#'
#' A citation names an author and a year, and says nothing about the
#' line of reasoning of the text itself.  Left in, the author names and
#' the years become content words and link sentences that have nothing
#' in common but a source.
#'
#' A bracket is read as a citation when it holds a year, that is four
#' digits from 1800 to 2099.  Fullwidth brackets (（）) and ASCII ones
#' are both removed.  A bracket without a year is kept, so that a note
#' such as 「(以下，畦畔草原という)」 stays in the text.  A year that
#' stands outside a bracket, as in 「2011年の調査では」, is part of the
#' prose and is kept.
#'
#' Use it before [as_sentences()], next to [strip_markdown()].
#'
#' @param text A character vector.
#' @return A character vector, with the citations removed.
#' @examples
#' drop_citations("畦畔は重要である（丑丸2012）．")
#'
#' # a bracket without a year is a note, and stays
#' drop_citations("畦畔法面に成立する草原(以下，畦畔草原という)を扱う．")
#'
#' @export
drop_citations <- function(text){
  text  <- as.character(text)
  year  <- "(1[89]|20)[0-9]{2}"
  open  <- intToUtf8(0xff08)   # （
  close <- intToUtf8(0xff09)   # ）
  inner <- paste0("[^", open, close, "]*")
  full  <- paste0(open, inner, year, inner, close)
  half  <- paste0("\\([^()]*", year, "[^()]*\\)")
  text  <- gsub(full, "", text, perl = TRUE)
  gsub(half, "", text, perl = TRUE)
}
