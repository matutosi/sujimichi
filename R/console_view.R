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
#' An analyser splits a compound word that is not in its dictionary:
#' MeCab with ipadic reads 「畦畔」 as 「畦」 and 「畔」, and marking
#' 「(畦)畔」 reads oddly even though the link itself is sound.  Give
#' `words` and the mark is widened over the nouns next to the shared
#' one, so that the whole compound is marked.  Only the mark changes;
#' the links were worked out in [connect_sentences()] and are untouched.
#'
#' @param links A data.frame as returned by [connect_sentences()].
#' @param sentences A data.frame with `sentence_id` and `sentence`,
#'   as returned by [as_sentences()].
#' @param words A data.frame as returned by [content_words()], or
#'   `NULL` (the default) to mark the shared word on its own.
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
sujimichi_lines <- function(links, sentences, words = NULL,
                            wrap = c("(", ")")){
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
    shown <- if(is.null(words)) word else
             widen_to_compound(words, main[["sentence_id"]][[k]],
                               main[["position"]][[k]], word, text)
    at <- regexpr(shown, text, fixed = TRUE)
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
    marked[[k]] <- shown
    after[[k]]  <- substr(text, at + nchar(shown), nchar(text))
    plain[[k]]  <- paste0(before[[k]], wrap[[1]], shown, wrap[[2]], after[[k]])

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

#' Widen a word over the nouns beside it
#'
#' Internal function for [sujimichi_lines()].
#' An analyser splits a compound word it does not know, and the pieces
#' sit next to each other as nouns.  The run of nouns around `position`
#' is put back together, and taken only when it reads in the sentence as
#' it stands; a lemma that differs from what was written would otherwise
#' produce a string that is nowhere in the text.
#'
#' @param words A data.frame as returned by [content_words()].
#' @param sentence_id The sentence the word is in.
#' @param position The place of the word among the morphemes.
#' @param word A string.  The shared word itself.
#' @param text A string.  The sentence as written.
#' @return A string: the compound, or `word` when there is none.
#' @keywords internal
widen_to_compound <- function(words, sentence_id, position, word, text){
  cols <- c("sentence_id", "position", "word", "pos")
  if(!is.data.frame(words) || !all(cols %in% colnames(words))) return(word)
  if(is.na(position)) return(word)
  here <- words[words[["sentence_id"]] %in% sentence_id, , drop = FALSE]
  here <- here[order(here[["position"]]), , drop = FALSE]
  at   <- match(position, here[["position"]])
  if(is.na(at)) return(word)
  noun <- here[["pos"]] == content_pos()[[1]]   # 名詞
  if(!isTRUE(noun[[at]])) return(word)
  place <- here[["position"]]
  from  <- at
  to    <- at
  while(from > 1L && isTRUE(noun[[from - 1L]]) &&
        place[[from - 1L]] == place[[from]] - 1L) from <- from - 1L
  while(to < nrow(here) && isTRUE(noun[[to + 1L]]) &&
        place[[to + 1L]] == place[[to]] + 1L) to <- to + 1L
  if(from == to) return(word)
  run <- paste(here[["word"]][from:to], collapse = "")
  if(regexpr(run, text, fixed = TRUE) > 0) run else word
}

#' @rdname sujimichi_lines
#' @param max_marks A number.  How many shared words to mark in one
#'   line.  `1` (the default) marks the representative alone; `3`
#'   follows the option in `design.md`.  The others are marked where
#'   they stand after the representative, and the indent is worked out
#'   from the representative as before.
#' @export
format_sujimichi <- function(links, sentences, words = NULL,
                             wrap = c("(", ")"), max_marks = 1){
  lines <- sujimichi_lines(links, sentences, words = words, wrap = wrap)
  marked <- ifelse(nzchar(lines[["marked"]]),
                   paste0(wrap[[1]], lines[["marked"]], wrap[[2]]), "")
  after <- mark_more(lines, links, words = words, wrap = wrap,
                     max_marks = max_marks)
  paste0(strrep(" ", lines[["indent"]]),
        lines[["before"]], marked, after)
}

#' Mark the other shared words of a line
#'
#' Internal function for [format_sujimichi()].
#' `design.md` asks for an option to show up to three connections.  The
#' representative settles the indent and is marked by
#' [sujimichi_lines()]; the others are marked here, in the text that
#' follows it, so that the alignment worked out from the text before the
#' representative is left alone.  A word that is not written as its
#' lemma says is passed over.
#'
#' The other words are widened over a split compound in the same way as
#' the representative, and a word that the widening has already brought
#' into an earlier mark is passed over, so that 「畦」 and 「畔」 give
#' one 「(畦畔)」 rather than 「(畦)(畔)」.
#'
#' @param lines A data.frame as returned by [sujimichi_lines()].
#' @param links A data.frame as returned by [connect_sentences()].
#' @param words A data.frame as returned by [content_words()], or `NULL`.
#' @param wrap A character vector of length 2.
#' @param max_marks A number.
#' @return A character vector, the `after` part of each line.
#' @keywords internal
mark_more <- function(lines, links, words = NULL, wrap = c("(", ")"),
                      max_marks = 1){
  after <- lines[["after"]]
  if(!is.finite(max_marks) || max_marks <= 1) return(after)
  more <- links[!links[["is_main"]] %in% TRUE &
                !is.na(links[["prev_id"]]), , drop = FALSE]
  if(nrow(more) == 0) return(after)
  more <- more[order(more[["sentence_id"]], more[["position"]]), ,
               drop = FALSE]
  for(k in seq_along(after)){
    take <- which(more[["sentence_id"]] %in% lines[["sentence_id"]][[k]])
    if(!length(take)) next
    shown <- lines[["marked"]][[k]]
    shown <- shown[nzchar(shown)]
    for(i in take){
      if(length(shown) >= max_marks) break
      word <- as.character(more[["word"]][[i]])
      if(is.null(words)){
        wide <- word
      }else{
        wide <- widen_to_compound(words, more[["sentence_id"]][[i]],
                                  more[["position"]][[i]], word, after[[k]])
      }
      if(any(vapply(shown, overlaps, logical(1), b = wide))) next
      at <- regexpr(wide, after[[k]], fixed = TRUE)
      if(at < 0) next
      after[[k]] <- paste0(substr(after[[k]], 1, at - 1),
                           wrap[[1]], wide, wrap[[2]],
                           substr(after[[k]], at + nchar(wide),
                                  nchar(after[[k]])))
      shown <- c(shown, wide)
    }
  }
  after
}

#' Tell whether one string holds the other
#'
#' Internal function for [mark_more()].
#'
#' @param a,b Strings.
#' @return A logical.
#' @keywords internal
overlaps <- function(a, b){
  grepl(a, b, fixed = TRUE) || grepl(b, a, fixed = TRUE)
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
print_sujimichi <- function(links, sentences, words = NULL,
                            wrap = c("(", ")"), max_marks = 1,
                            color = interactive(), file = ""){
  lines <- sujimichi_lines(links, sentences, words = words, wrap = wrap)
  marked <- ifelse(!nzchar(lines[["marked"]]), "",
                   paste0(wrap[[1]], lines[["marked"]], wrap[[2]]))
  after <- mark_more(lines, links, words = words, wrap = wrap,
                     max_marks = max_marks)
  shown <- if(color) vapply(marked, ansi_cyan, character(1)) else marked
  cat(paste0(strrep(" ", lines[["indent"]]),
            lines[["before"]], shown, after), sep = "\n", file = file)
  invisible(paste0(strrep(" ", lines[["indent"]]),
                   lines[["before"]], marked, after))
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
