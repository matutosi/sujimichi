#' Strip Markdown notation to plain text
#'
#' Removes Markdown syntax markers while keeping the body text, so the
#' result can be handed to [as_sentences()].  A fenced code block
#' (`` ``` `` or `~~~`) is removed entirely, fence lines and content
#' alike, because code is not prose and should not be split into
#' sentences.  A heading, a list marker and a blockquote marker are
#' each removed, but the text after them is kept.  An inline code span
#' keeps its content and loses only the backticks, unless the content
#' holds no letter and no digit (`` `.` ``), in which case the span goes
#' away with it; a bare mark left behind would otherwise be read as the
#' end of a sentence.
#'
#' A link (`[text](url)`) keeps its text and loses the address, since the
#' text is part of the prose while the address is not.  An image
#' (`![alt](url)`) is removed as a whole, and so is an autolink
#' (`<https://example.com>`).  Emphasis marks (`**`, `*`, `__`) are
#' removed and the text between them is kept.  A lone `_` is left alone,
#' because it is more often part of a name such as `sentence_id` than a
#' mark of emphasis.
#'
#' @param text A character vector, one element per line.
#' @return A character vector of lines, with Markdown notation removed.
#' @examples
#' strip_markdown(c("# 見出し", "",
#'                   "本文だ．", "",
#'                   "- 箇条書き1", "- 箇条書き2"))
#' strip_markdown("**強調**した[リンク](https://example.com)．")
#'
#' @export
strip_markdown <- function(text){
  lines <- drop_code_blocks(as.character(text))
  vapply(lines, strip_markdown_line, character(1), USE.NAMES = FALSE)
}

#' Drop the lines of fenced code blocks
#'
#' Internal function for [strip_markdown()].
#'
#' @param lines A character vector.
#' @return A character vector with fenced code blocks removed.
#' @keywords internal
drop_code_blocks <- function(lines){
  fence   <- grepl("^[[:blank:]]*(```|~~~)", lines, perl = TRUE)
  in_code <- logical(length(lines))
  open    <- FALSE
  for(i in seq_along(lines)){
    in_code[[i]] <- fence[[i]] || open
    if(fence[[i]]) open <- !open
  }
  lines[!in_code]
}

#' Strip the Markdown notation of one line
#'
#' Internal function for [strip_markdown()].
#'
#' @param line A string.
#' @return A string.
#' @keywords internal
strip_markdown_line <- function(line){
  # blockquote: one or more leading "> " markers, possibly nested
  line <- gsub("^([[:blank:]]*>[[:blank:]]?)+", "", line, perl = TRUE)
  # heading: leading # marks
  line <- gsub("^[[:blank:]]*#{1,6}[[:blank:]]+", "", line, perl = TRUE)
  # unordered list marker
  line <- gsub("^[[:blank:]]*[-*+][[:blank:]]+", "", line, perl = TRUE)
  # ordered list marker
  line <- gsub("^[[:blank:]]*[0-9]+[.)][[:blank:]]+", "", line, perl = TRUE)
  # image: not prose, so drop it as a whole (before the link rule)
  line <- gsub("!\\[[^]]*\\]\\([^)]*\\)", "", line, perl = TRUE)
  # link: keep the text, drop the address
  line <- gsub("\\[([^]]*)\\]\\([^)]*\\)", "\\1", line, perl = TRUE)
  # reference style link: keep the text, drop the label
  line <- gsub("\\[([^]]*)\\]\\[[^]]*\\]", "\\1", line, perl = TRUE)
  # autolink
  line <- gsub("<[a-zA-Z][a-zA-Z0-9+.-]*:[^>[:blank:]]*>", "", line,
               perl = TRUE)
  # emphasis: keep the text, drop the marks
  line <- gsub("\\*\\*([^*]+)\\*\\*", "\\1", line, perl = TRUE)
  line <- gsub("__([^_]+)__", "\\1", line, perl = TRUE)
  line <- gsub("\\*([^*]+)\\*", "\\1", line, perl = TRUE)
  # inline code holding no letter and no digit: drop the span as a whole
  line <- gsub("`[^`\\p{L}\\p{N}]*`", "", line, perl = TRUE)
  # inline code: keep the content, drop the backticks
  gsub("`([^`]*)`", "\\1", line, perl = TRUE)
}
