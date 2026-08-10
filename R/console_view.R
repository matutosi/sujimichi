#' Show sentences on the console with the connecting word aligned
#'
#' Builds one line per sentence, indented so that the word it shares
#' with its earlier sentence lines up under the same word written in
#' that earlier line, and marks the word with `wrap`.  This is the
#' console display sketched in `design.md`:
#'
#' ```
#' 文章とは，単語のつながりである．
#'                (つながり)があるおかげで，文章の構造を明示できる．
#'                                               (構造)がわかれば，文章を理解しやすくなる．
#' ```
#'
#' Only the representative link of each sentence (`is_main`, from
#' [connect_sentences()]) is drawn, since one connection per line keeps
#' the picture readable; a sentence still shows the rest of its text
#' even when it has no link.  Width is counted with
#' [stringi::stri_width()], so full-width characters take two columns.
#'
#' The indent of a line is the width of the text before the word in
#' the *earlier* line, minus one column, added to that earlier line's
#' own indent -- so the mark overlaps the last column of the text it
#' points at, as in the example above.
#'
#' A word (a lemma) is looked for as a literal substring of the
#' sentence text.  When it is not found -- for example a verb whose
#' lemma differs from the form actually written -- the sentence is
#' shown as plain text, at the same indent as the sentence it links to.
#'
#' @param links A data.frame as returned by [connect_sentences()].
#' @param sentences A data.frame with `sentence_id` and `sentence`,
#'   as returned by [as_sentences()].
#' @param wrap A character vector of length 2: the marks put around
#'   the shared word.
#' @return A tibble with one row per sentence, in `sentence_id` order,
#'   and columns `sentence_id`, `indent`, `before`, `marked`, `after`.
#'   `before`, `marked` and `after` join back into the full line;
#'   `marked` is `""` when the sentence has no word to show.
#' @examples
#' sentences <- as_sentences(sample_text())
#' words <- tibble::tribble(
#'   ~sentence_id, ~position, ~word,
#'   1, 1, "文章", 1, 5, "単語", 1, 7, "つながり",
#'   2, 1, "つながり", 2, 9, "文章", 2, 11, "構造",
#'   3, 1, "構造", 3, 7, "文章")
#' links <- connect_sentences(words, sentences)
#' sujimichi_lines(links, sentences)
#'
#' @export
sujimichi_lines <- function(links, sentences, wrap = c("(", ")")){
  if(!is.data.frame(links) || !all(c("sentence_id", "word", "prev_id",
                                     "is_main") %in% colnames(links))){
    stop("`links` must be a data.frame as returned by connect_sentences().",
         call. = FALSE)
  }
  if(!is.data.frame(sentences) ||
     !all(c("sentence_id", "sentence") %in% colnames(sentences))){
    stop("`sentences` must be a data.frame with `sentence_id` and ",
         "`sentence`.", call. = FALSE)
  }
  ids  <- sort(unique(sentences[["sentence_id"]]))
  raw  <- sentences[["sentence"]][match(ids, sentences[["sentence_id"]])]
  main <- links[links[["is_main"]] %in% TRUE, , drop = FALSE]
  main <- main[match(ids, main[["sentence_id"]]), , drop = FALSE]

  plain  <- character(length(ids))
  indent <- numeric(length(ids))
  before <- character(length(ids))
  marked <- character(length(ids))
  after  <- character(length(ids))
  names(plain) <- names(indent) <- as.character(ids)

  for(k in seq_along(ids)){
    text <- raw[[k]]
    word <- main[["word"]][[k]]
    prev <- main[["prev_id"]][[k]]
    if(is.na(word) || is.na(prev)){
      plain[[k]]  <- text
      before[[k]] <- text
      after[[k]]  <- ""
      next
    }
    at <- regexpr(word, text, fixed = TRUE)
    if(at < 0){
      # the lemma is not a literal substring of the sentence
      # (for example a conjugated verb) -- show it plainly
      plain[[k]]  <- text
      before[[k]] <- text
      after[[k]]  <- ""
      indent[[k]] <- indent[[as.character(prev)]]
      next
    }
    before[[k]] <- substr(text, 1, at - 1)
    marked[[k]] <- word
    after[[k]]  <- substr(text, at + nchar(word), nchar(text))
    plain[[k]]  <- paste0(before[[k]], wrap[[1]], word, wrap[[2]], after[[k]])

    prev_plain <- plain[[as.character(prev)]]
    at_prev    <- regexpr(word, prev_plain, fixed = TRUE)
    if(at_prev < 0){
      indent[[k]] <- indent[[as.character(prev)]]
    }else{
      width <- stringi::stri_width(substr(prev_plain, 1, at_prev - 1))
      indent[[k]] <- max(indent[[as.character(prev)]] + width - 1, 0)
    }
  }
  tibble::tibble(sentence_id = ids, indent = unname(indent),
                 before = unname(before), marked = unname(marked),
                 after = unname(after))
}

#' @rdname sujimichi_lines
#' @export
format_sujimichi <- function(links, sentences, wrap = c("(", ")")){
  lines <- sujimichi_lines(links, sentences, wrap = wrap)
  marked <- ifelse(nzchar(lines[["marked"]]),
                   paste0(wrap[[1]], lines[["marked"]], wrap[[2]]), "")
  paste0(strrep(" ", lines[["indent"]]),
        lines[["before"]], marked, lines[["after"]])
}

#' @rdname sujimichi_lines
#' @param color A logical.  Colour the marked word with ANSI escapes.
#'   Defaults to [interactive()], so example runs and `R CMD check`
#'   stay free of escape codes.
#' @param file passed to [cat()]; `""` (the default) prints to the
#'   console.
#' @return `print_sujimichi()`: the plain lines, as from
#'   `format_sujimichi()`, invisibly.
#' @export
print_sujimichi <- function(links, sentences, wrap = c("(", ")"),
                            color = interactive(), file = ""){
  lines <- sujimichi_lines(links, sentences, wrap = wrap)
  marked <- ifelse(!nzchar(lines[["marked"]]), "",
                   paste0(wrap[[1]], lines[["marked"]], wrap[[2]]))
  shown <- if(color) vapply(marked, ansi_cyan, character(1)) else marked
  cat(paste0(strrep(" ", lines[["indent"]]),
            lines[["before"]], shown, lines[["after"]]), sep = "\n", file = file)
  invisible(paste0(strrep(" ", lines[["indent"]]),
                   lines[["before"]], marked, lines[["after"]]))
}

#' Colour a string cyan with ANSI escapes
#'
#' Internal function for [print_sujimichi()].
#' An empty string is left empty, so an unmarked line is not coloured.
#'
#' @param x A string.
#' @return A string.
#' @keywords internal
ansi_cyan <- function(x){
  if(!nzchar(x)) return(x)
  paste0("\033[36m", x, "\033[39m")
}
