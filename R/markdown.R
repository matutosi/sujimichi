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
#' A list item is a sentence of its own, but it rarely ends with a full
#' stop.  [split_sentences()] joins the lines of a paragraph, because a
#' Japanese manuscript breaks a line in the middle of a sentence, so the
#' items of a list would otherwise be run together into one long
#' sentence.  A terminator is therefore added to an item that does not
#' already end with one.  Pass `list_end = ""` to leave the items as
#' they are.
#'
#' @param text A character vector, one element per line.
#' @param list_end A string added to the end of a list item that does not
#'   end with a sentence terminator.  The fullwidth full stop (．) by
#'   default; `""` adds nothing.
#' @return A character vector of lines, with Markdown notation removed.
#' @examples
#' strip_markdown(c("# 見出し", "",
#'                   "本文だ．", "",
#'                   "- 箇条書き1", "- 箇条書き2"))
#' strip_markdown("**強調**した[リンク](https://example.com)．")
#'
#' # a list item becomes a sentence of its own
#' strip_markdown(c("- 箇条書き1", "- 箇条書き2"))
#'
#' @export
strip_markdown <- function(text, list_end = sentence_marks()[[2]]){
  lines <- drop_code_blocks(as.character(text))
  vapply(lines, strip_markdown_line, character(1),
         list_end = list_end, USE.NAMES = FALSE)
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
#' @inheritParams strip_markdown
#' @return A string.
#' @keywords internal
strip_markdown_line <- function(line, list_end = ""){
  # blockquote: one or more leading "> " markers, possibly nested
  line <- gsub("^([[:blank:]]*>[[:blank:]]?)+", "", line, perl = TRUE)
  # heading: leading # marks
  line <- gsub("^[[:blank:]]*#{1,6}[[:blank:]]+", "", line, perl = TRUE)
  # a list item stands on its own, so remember it before the marker goes
  item <- grepl("^[[:blank:]]*([-*+]|[0-9]+[.)])[[:blank:]]+", line,
                perl = TRUE)
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
  line <- gsub("`([^`]*)`", "\\1", line, perl = TRUE)
  if(item) line <- add_sentence_end(line, list_end)
  line
}

#' Add a sentence terminator to the end of a line
#'
#' Internal function for [strip_markdown()].
#' Nothing is added to an empty line, or to a line that already ends with
#' a terminator, possibly followed by a closing bracket.
#'
#' @param line A string.
#' @param mark A string.  `""` adds nothing.
#' @return A string.
#' @keywords internal
add_sentence_end <- function(line, mark){
  if(!nzchar(mark)) return(line)
  body <- trimws(line)
  if(!nzchar(body)) return(line)
  # the same closing brackets and quotation marks as
  # move_mark_after_close(), written as code points to keep this file
  # ASCII: 」』〉》）］”’ and the ASCII ones
  close <- paste0(intToUtf8(c(0x300d, 0x300f, 0x3009, 0x300b,
                              0xff09, 0xff3d, 0x201d, 0x2019)),
                  ")\\]\"'")
  ends  <- paste0("[", paste(sentence_marks(), collapse = ""),
                  "][", close, "]*$")
  if(grepl(ends, body, perl = TRUE)) return(line)
  paste0(body, mark)
}
