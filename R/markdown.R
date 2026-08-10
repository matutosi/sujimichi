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
#' A list item and a heading are each a sentence of their own, but
#' neither usually ends with a full stop.  [split_sentences()] joins the
#' lines of a paragraph, because a Japanese manuscript breaks a line in
#' the middle of a sentence, so the items of a list would otherwise be
#' run together into one long sentence.  A terminator is therefore added
#' to a line that does not already end with one.  Pass `end_mark = ""`
#' to leave the lines as they are.
#'
#' A heading is followed by a blank line, so it would stand as a
#' paragraph of its own and share no word with anything.  It is joined
#' to the paragraph below it instead, where it reads as the sentence
#' that the paragraph is about, and where a heading whose words do not
#' come back in the text below shows up as dead code.  Pass
#' `heading = "keep"` to leave a heading as its own paragraph, or
#' `heading = "drop"` to take headings out of the analysis.
#'
#' @param text A character vector, one element per line.
#' @param end_mark A string added to the end of a list item or a heading
#'   that does not end with a sentence terminator.  The fullwidth full
#'   stop (．) by default; `""` adds nothing, and then a heading is kept
#'   as its own paragraph whatever `heading` says, since joining it to
#'   the text below would glue it to the first sentence.
#' @param heading One of `"merge"` (join a heading to the paragraph
#'   below it), `"keep"` (leave it as its own paragraph) or `"drop"`
#'   (remove headings).
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
#' # a heading joins the paragraph below it
#' strip_markdown(c("# 目的", "", "この節では目的を述べる．"))
#'
#' @export
strip_markdown <- function(text, end_mark = sentence_marks()[[2]],
                           heading = c("merge", "keep", "drop")){
  heading <- match.arg(heading)
  lines   <- drop_code_blocks(as.character(text))
  head_at <- grepl("^[[:blank:]]*#{1,6}[[:blank:]]+", lines, perl = TRUE)
  ends    <- list_item_ends(lines)
  out     <- vapply(lines, strip_markdown_line, character(1),
                    USE.NAMES = FALSE)
  if(heading == "drop") return(out[!head_at])
  if(nzchar(end_mark)){
    close <- ends | (heading == "merge" & head_at)
    if(any(close)){
      out[close] <- vapply(out[close], add_sentence_end, character(1),
                           mark = end_mark, USE.NAMES = FALSE)
    }
    if(heading == "merge") out <- drop_blank_after(out, head_at)
  }
  out
}

#' Drop the blank lines that follow a marked line
#'
#' Internal function for [strip_markdown()].
#' A blank line starts a new paragraph, so removing the one below a
#' heading is what joins the heading to the text that follows.
#'
#' @param lines A character vector.
#' @param flag A logical vector, `TRUE` on the lines to look below.
#' @return A character vector.
#' @keywords internal
drop_blank_after <- function(lines, flag){
  blank <- !nzchar(trimws(lines))
  drop  <- logical(length(lines))
  below <- FALSE
  for(i in seq_along(lines)){
    if(flag[[i]]){
      below <- TRUE
    } else if(below && blank[[i]]){
      drop[[i]] <- TRUE
    } else {
      below <- FALSE
    }
  }
  lines[!drop]
}

#' Find the last line of each list item
#'
#' Internal function for [strip_markdown()].
#' An item may run over several lines: the lines after the marker are
#' indented and carry no marker of their own.  The terminator belongs at
#' the end of the whole item, not at the end of its first line, which
#' would cut the item in two.
#'
#' @param lines A character vector.
#' @return A logical vector, `TRUE` on the last line of each item.
#' @keywords internal
list_item_ends <- function(lines){
  start  <- grepl("^[[:blank:]]*([-*+]|[0-9]+[.)])[[:blank:]]+", lines,
                  perl = TRUE)
  blank  <- !nzchar(trimws(lines))
  indent <- grepl("^[[:blank:]]", lines, perl = TRUE)
  in_item <- logical(length(lines))
  open    <- FALSE
  for(i in seq_along(lines)){
    if(start[[i]]){
      open <- TRUE
    } else if(blank[[i]] || !indent[[i]]){
      open <- FALSE
    }
    in_item[[i]] <- open
  }
  carried <- in_item & !start          # a line that carries an item on
  after   <- c(carried[-1], FALSE)     # is the next line such a line?
  in_item & !after
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
  strip_code_spans(line)
}

#' Take the inline code spans out of a line
#'
#' Internal function for [strip_markdown()].
#' A span keeps its content and loses the backticks, unless the content
#' holds no letter and no digit, in which case the span goes away with
#' it; a bare mark left behind would be read as the end of a sentence.
#'
#' The spans are taken one pair of backticks at a time, from the left.
#' A single pattern would match from the closing backtick of one span to
#' the opening backtick of the next, and would swallow what lies between
#' them: `` `a`，`b` `` would come out as `ab`.
#'
#' @param line A string.
#' @return A string.
#' @keywords internal
strip_code_spans <- function(line){
  found <- gregexpr("`[^`]*`", line, perl = TRUE)
  spans <- regmatches(line, found)[[1]]
  if(!length(spans)) return(line)
  body <- substr(spans, 2L, nchar(spans) - 1L)
  keep <- grepl("[\\p{L}\\p{N}]", body, perl = TRUE)
  regmatches(line, found) <- list(ifelse(keep, body, ""))
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
  ends <- paste0("[", paste(sentence_marks(), collapse = ""),
                 "][", closing_marks(), "]*$")
  if(grepl(ends, body, perl = TRUE)) return(line)
  paste0(body, mark)
}
