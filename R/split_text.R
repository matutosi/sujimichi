#' Sentence terminators
#'
#' The characters that end a sentence: the ideographic full stop
#' (U+3002, 。), the fullwidth full stop (U+FF0E, ．) and the ASCII
#' full stop.
#'
#' @return A character vector.
#' @examples
#' sentence_marks()
#'
#' @export
sentence_marks <- function(){
  # 。 ． .   (escaped to keep the R code ASCII only)
  c("\u3002", "\uff0e", ".")
}

#' Closing brackets and quotation marks
#'
#' Internal function.  The characters that may follow a sentence
#' terminator and still belong to the same sentence: 」』〉》）］”’ and
#' the ASCII ones.  Written as code points to keep this file ASCII.
#' The ASCII "]" comes back escaped, so that the string can be dropped
#' straight into a character class.
#'
#' @return A string.
#' @keywords internal
closing_marks <- function(){
  paste0(intToUtf8(c(0x300d, 0x300f, 0x3009, 0x300b,
                     0xff09, 0xff3d, 0x201d, 0x2019)),
         ")\\]\"'")
}

#' A short sample text
#'
#' Three sentences used in the examples and in the README.
#' They are chained by 「つながり」 and 「構造」.
#'
#' @return A character vector of lines.
#' @examples
#' sample_text()
#'
#' @export
sample_text <- function(){
  # 文章とは，単語のつながりである．
  # つながりがあるおかげで，文章の構造を明示できる．
  # 構造がわかれば，文章を理解しやすくなる．
  c("\u6587\u7ae0\u3068\u306f\uff0c\u5358\u8a9e\u306e\u3064\u306a\u304c\u308a\u3067\u3042\u308b\uff0e",
    "\u3064\u306a\u304c\u308a\u304c\u3042\u308b\u304a\u304b\u3052\u3067\uff0c\u6587\u7ae0\u306e\u69cb\u9020\u3092\u660e\u793a\u3067\u304d\u308b\uff0e",
    "\u69cb\u9020\u304c\u308f\u304b\u308c\u3070\uff0c\u6587\u7ae0\u3092\u7406\u89e3\u3057\u3084\u3059\u304f\u306a\u308b\uff0e")
}

#' Split a text into paragraphs and sentences
#'
#' `split_paragraphs()` splits a text at blank lines,
#' `split_sentences()` splits a paragraph at sentence terminators, and
#' `as_sentences()` does both and returns a table.
#'
#' Lines inside a paragraph are joined before the split into sentences,
#' because a Japanese manuscript often breaks a line at a sentence end or
#' at a phrase boundary.  A space is kept only where an ASCII word would
#' otherwise be glued to the next one.
#'
#' An ASCII full stop ends a sentence only at the end of a paragraph, or
#' before a space or a closing bracket.  A full stop inside a word is
#' part of it, so that "0.5", "ui.R" and ".claude/done.md" stay in one
#' piece.  A terminator followed by a closing bracket or quotation mark
#' keeps the bracket in the same sentence.
#'
#' @param text A character vector.  Elements are treated as lines and are
#'   pasted together with a line break.
#' @param sep A character vector of sentence terminators.
#'   Each element is one character and is used as a literal.
#' @return
#'   * `split_paragraphs()`: a character vector of paragraphs.
#'   * `split_sentences()`: a character vector of sentences.
#'   * `as_sentences()`: a tibble with columns `paragraph_id`,
#'     `sentence_id` and `sentence`.  `sentence_id` runs through the whole
#'     text and does not restart in each paragraph.
#' @examples
#' as_sentences(sample_text())
#'
#' # a blank line starts a new paragraph
#' as_sentences(c(sample_text(), "", sample_text()))
#'
#' @export
as_sentences <- function(text, sep = sentence_marks()){
  paragraphs <- split_paragraphs(text)
  sentences  <- lapply(paragraphs, split_sentences, sep = sep)
  n          <- lengths(sentences)
  sentences  <- sentences[n > 0]
  n          <- n[n > 0]
  tibble::tibble(
    paragraph_id = rep(seq_along(n), times = n),
    sentence_id  = seq_len(sum(n)),
    sentence     = as.character(unlist(sentences, use.names = FALSE)))
}

#' @rdname as_sentences
#' @export
split_paragraphs <- function(text){
  text       <- paste(as.character(text), collapse = "\n")
  text       <- gsub("\r\n|\r", "\n", text)
  paragraphs <- strsplit(text, "\n[[:blank:]]*\n", perl = TRUE)[[1]]
  paragraphs <- trimws(paragraphs)
  paragraphs[nzchar(paragraphs)]
}

#' @rdname as_sentences
#' @export
split_sentences <- function(text, sep = sentence_marks()){
  text <- join_lines(paste(as.character(text), collapse = "\n"))
  mark <- "\u0001"   # never appears in a manuscript
  dot  <- sep %in% "."
  if(any(!dot)){
    cls  <- paste0("[", paste(sep[!dot], collapse = ""), "]")
    text <- gsub(paste0("(", cls, ")"), paste0("\\1", mark), text, perl = TRUE)
  }
  if(any(dot)){
    # a terminator only at the end, or before a space or a closing
    # bracket, so that "0.5", "ui.R" and ".claude/done.md" stay whole
    text <- gsub(paste0("\\.(?=[[:blank:]]|$|[", closing_marks(), "])"),
                 paste0(".", mark), text, perl = TRUE)
  }
  text      <- move_mark_after_close(text, mark)
  sentences <- trimws(strsplit(text, mark, fixed = TRUE)[[1]])
  sentences[nzchar(sentences)]
}

#' Join the lines of a paragraph into one string
#'
#' Internal function for [split_sentences()].
#'
#' @param text A string.
#' @param mark A string used as the split mark.
#' @return A string.
#' @keywords internal
join_lines <- function(text){
  text <- gsub("\r\n|\r", "\n", text)
  # keep a space where two ASCII words would otherwise be glued together
  text <- gsub("([A-Za-z0-9])[[:blank:]]*\n[[:blank:]]*([A-Za-z0-9])",
               "\\1 \\2", text, perl = TRUE)
  gsub("[[:blank:]]*\n[[:blank:]]*", "", text, perl = TRUE)
}

#' @rdname join_lines
#' @keywords internal
move_mark_after_close <- function(text, mark){
  # closing brackets and quotation marks: 」』〉》）］”’ and ASCII ones.
  # the ASCII "]" is escaped, or it would close the class.
  close   <- closing_marks()
  pattern <- paste0(mark, "([", close, "])")
  repeat{
    moved <- gsub(pattern, paste0("\\1", mark), text, perl = TRUE)
    if(identical(moved, text)) break
    text <- moved
  }
  text
}
