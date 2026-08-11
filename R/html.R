#' Write the sentences and their links as HTML
#'
#' The third of the displays sketched in `design.md`: the same picture
#' as [print_sujimichi()], marked up with `<span>` so that it can be
#' pasted into R Markdown or Quarto.
#'
#' The lines are wrapped in `<pre>`, which keeps the spaces that carry
#' the alignment.  The widths were counted with [stringi::stri_width()],
#' which gives a full-width character two columns, so the alignment
#' comes out right in a monospaced font that draws them that way.
#'
#' The shared word of each sentence is put in
#' `<span class="sujimichi-word">`, and a sentence that shares no word
#' with any other sentence of its paragraph -- the dead code of
#' [dead_code()] -- in `<span class="sujimichi-dead">`.  With
#' `css = TRUE` a `<style>` block for those two classes comes with it,
#' so that the result stands on its own; pass `css = FALSE` and write
#' the rules yourself when the document already has a style sheet.
#'
#' In an R Markdown chunk, use `results = "asis"`.
#'
#' @inheritParams sujimichi_lines
#' @param sentences A data.frame as returned by [as_sentences()], with
#'   `sentence_id`, `paragraph_id` and `sentence`.
#' @param max_marks A number.  How many shared words to mark in one
#'   line, as in [format_sujimichi()].
#' @param css A logical.  Put a `<style>` block in front of the lines.
#' @return A string of HTML, of class `sujimichi_html`.
#' @examples
#' sentences <- as_sentences(sample_text())
#' words <- data.frame(
#'   sentence_id = c(1, 1, 2, 2, 3),
#'   position    = c(1, 5, 1, 7, 1),
#'   word        = c("文章", "つながり", "つながり", "構造", "構造"))
#' links <- connect_sentences(words, sentences)
#' html <- html_sujimichi(links, sentences)
#' substr(html, 1, 60)
#'
#' @export
html_sujimichi <- function(links, sentences, words = NULL,
                           max_marks = 1, css = TRUE){
  # markers that never appear in a manuscript, put where the marks go
  # and swapped for tags once the text has been escaped
  open  <- intToUtf8(0x0011)
  close <- intToUtf8(0x0012)
  lines <- sujimichi_lines(links, sentences, words = words,
                           wrap = c(open, close))
  after <- mark_more(lines, links, words = words, wrap = c(open, close),
                     max_marks = max_marks)
  marked <- ifelse(nzchar(lines[["marked"]]),
                   paste0(open, lines[["marked"]], close), "")
  body <- paste0(strrep(" ", lines[["indent"]]),
                 lines[["before"]], marked, after)
  body <- escape_html(body)
  body <- gsub(open, "<span class=\"sujimichi-word\">", body, fixed = TRUE)
  body <- gsub(close, "</span>", body, fixed = TRUE)

  dead <- dead_code(links, sentences)
  gone <- dead[["isolated"]][match(lines[["sentence_id"]],
                                   dead[["sentence_id"]])]
  gone <- !is.na(gone) & gone
  body[gone] <- paste0("<span class=\"sujimichi-dead\">", body[gone],
                       "</span>")

  out <- paste0("<pre class=\"sujimichi\">\n",
                paste(body, collapse = "\n"), "\n</pre>")
  if(css) out <- paste0(sujimichi_css(), "\n", out)
  structure(out, class = c("sujimichi_html", "character"))
}

#' @rdname html_sujimichi
#' @param x A `sujimichi_html` string.
#' @param ... Ignored.
#' @return `print()`: `x`, invisibly.  The HTML is written as it is, so
#'   that a chunk with `results = "asis"` renders it.
#' @export
print.sujimichi_html <- function(x, ...){
  cat(unclass(x), sep = "\n")
  invisible(x)
}

#' The style block that comes with the HTML
#'
#' Internal function for [html_sujimichi()].
#' Two rules only, one per class, so that a document with its own style
#' sheet can override them without a fight.
#'
#' @return A string.
#' @keywords internal
sujimichi_css <- function(){
  paste0("<style>\n",
         ".sujimichi { font-family: monospace; line-height: 1.6; ",
         "overflow-x: auto; }\n",
         ".sujimichi-word { color: #0b7285; font-weight: bold; }\n",
         ".sujimichi-dead { color: #c92a2a; }\n",
         "</style>")
}

#' Escape the characters that mean something in HTML
#'
#' Internal function for [html_sujimichi()].
#' The ampersand goes first, or the ampersands of the other escapes
#' would be escaped in their turn.
#'
#' @param text A character vector.
#' @return A character vector.
#' @keywords internal
escape_html <- function(text){
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;",  text, fixed = TRUE)
  gsub(">", "&gt;", text, fixed = TRUE)
}
