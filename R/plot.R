utils::globalVariables(c("x", "y", "link_id", "weight", "isolated",
                         "label", "sentence_id"))

#' Points of the arcs that join the sentences
#'
#' Lays the sentences out on a vertical axis, one row each, and draws
#' the link of each sentence as an arc back to the sentence it shares a
#' word with.  This is the display sketched in `design.md` as the
#' 'ggplot2' one; it is returned as data, so that the geometry can be
#' looked at, drawn with something else, or tested without 'ggplot2'.
#'
#' An arc is half an ellipse: it runs from `prev_id` up to
#' `sentence_id` on the y axis, and bulges out to
#' `bulge * (distance / 2)` on the x axis.  A link that reaches further
#' back therefore bulges further out.
#'
#' @param links A data.frame as returned by [connect_sentences()].
#' @param sentences A data.frame as returned by [as_sentences()], used
#'   to pick paragraphs.  May be `NULL` when `paragraph` is `NULL`.
#' @param max_links A number.  How many links to draw for one sentence,
#'   counted from the front of the sentence.  `3` follows the option in
#'   `design.md`.
#' @param paragraph A vector of `paragraph_id` to keep, or `NULL` (the
#'   default) for all of them.  A whole book at once is unreadable, so
#'   a few paragraphs at a time is the usual way to look at this.
#' @param bulge A number.  How far an arc bulges out, as a share of the
#'   distance it spans.
#' @param n An integer.  Points drawn along one arc.
#' @return A tibble with one row per point and columns `link_id`,
#'   `sentence_id`, `prev_id`, `word`, `distance`, `weight`, `x`, `y`.
#'   `link_id` groups the points of one arc.
#' @examples
#' sentences <- data.frame(paragraph_id = c(1, 1, 1),
#'                         sentence_id  = c(1, 2, 3))
#' words <- data.frame(
#'   sentence_id = c(1, 1, 2, 2, 3),
#'   position    = c(1, 5, 1, 7, 1),
#'   word        = c("文章", "つながる", "つながる", "構造", "構造"))
#' links <- connect_sentences(words, sentences)
#' sujimichi_arcs(links, sentences)
#'
#' @export
sujimichi_arcs <- function(links, sentences = NULL, max_links = 3,
                           paragraph = NULL, bulge = 0.5, n = 32){
  links <- check_links(links)
  links <- in_paragraph(links, sentences, paragraph)
  drawn <- links[!is.na(links[["prev_id"]]), , drop = FALSE]
  drawn <- drawn[order(drawn[["sentence_id"]], drawn[["position"]]), ,
                 drop = FALSE]
  if(nrow(drawn) > 0){
    rank  <- stats::ave(seq_len(nrow(drawn)), drawn[["sentence_id"]],
                        FUN = seq_along)
    drawn <- drawn[rank <= max_links, , drop = FALSE]
  }
  empty <- tibble::tibble(link_id = integer(0), sentence_id = numeric(0),
                          prev_id = numeric(0), word = character(0),
                          distance = numeric(0), weight = numeric(0),
                          x = numeric(0), y = numeric(0))
  if(nrow(drawn) == 0) return(empty)
  n <- max(as.integer(n), 2L)
  t <- seq(-pi / 2, pi / 2, length.out = n)
  parts <- lapply(seq_len(nrow(drawn)), function(i){
    from <- drawn[["prev_id"]][[i]]
    to   <- drawn[["sentence_id"]][[i]]
    span <- (to - from) / 2
    tibble::tibble(
      link_id     = i,
      sentence_id = to,
      prev_id     = from,
      word        = as.character(drawn[["word"]][[i]]),
      distance    = drawn[["distance"]][[i]],
      weight      = if("weight" %in% colnames(drawn))
                      drawn[["weight"]][[i]] else NA_real_,
      x           = bulge * span * cos(t),
      y           = (from + to) / 2 + span * sin(t))
  })
  do.call(rbind, parts)
}

#' Draw the sentences and their links with 'ggplot2'
#'
#' Puts one sentence on each row and joins it to the sentence it shares
#' a word with by an arc, as sketched in `design.md`.  A sentence that
#' shares no word with any other sentence of its paragraph -- the dead
#' code of [dead_code()] -- is drawn in a second colour, so that it can
#' be picked out at a glance.
#'
#' 'ggplot2' is in `Suggests`: when it is not installed a message is
#' shown and `NULL` is returned, and the rest of the package still
#' works.  [sujimichi_arcs()] returns the same geometry as data for a
#' reader who would rather draw it another way.
#'
#' @inheritParams sujimichi_arcs
#' @param sentences A data.frame as returned by [as_sentences()], with
#'   `sentence_id`, `paragraph_id` and `sentence`.
#' @param label A logical.  Write the text of each sentence beside its
#'   row.
#' @param chars An integer.  Longest label, in characters; what is left
#'   over is cut and marked with an ellipsis.
#' @param ratio A number, passed to [ggplot2::coord_fixed()].  One unit
#'   across the panel is `ratio` sentences down it, so an arc keeps the
#'   shape of the distance it spans; left free, the arcs stretch to fill
#'   the panel and a near link cannot be told from a far one.  Raise it
#'   to squeeze the arcs, lower it to spread them out.
#' @return A 'ggplot' object, or `NULL` when 'ggplot2' is missing.
#' @examples
#' \dontrun{
#'   # needs 'ggplot2'
#'   sentences <- as_sentences(sample_text())
#'   words <- data.frame(
#'     sentence_id = c(1, 1, 2, 2, 3),
#'     position    = c(1, 5, 1, 7, 1),
#'     word        = c("文章", "つながり", "つながり", "構造", "構造"))
#'   links <- connect_sentences(words, sentences)
#'   plot_sujimichi(links, sentences)
#' }
#'
#' @export
plot_sujimichi <- function(links, sentences, max_links = 3,
                           paragraph = NULL, bulge = 0.5,
                           label = TRUE, chars = 30, ratio = 1){
  if(!requireNamespace("ggplot2", quietly = TRUE)){
    message("Package 'ggplot2' is not installed, so no plot was drawn.\n",
            "  install.packages(\"ggplot2\")")
    return(invisible(NULL))
  }
  arcs <- sujimichi_arcs(links, sentences, max_links = max_links,
                         paragraph = paragraph, bulge = bulge)
  rows <- sentence_rows(links, sentences, paragraph = paragraph,
                        chars = chars)
  # the text goes on the y axis, where 'ggplot2' makes room for it;
  # drawn inside the panel it would be cut off at the edge
  scale_y <- if(label){
    ggplot2::scale_y_reverse(breaks = rows[["y"]], labels = rows[["label"]])
  }else{
    ggplot2::scale_y_reverse()
  }
  plot <- ggplot2::ggplot() +
    ggplot2::geom_path(data = arcs,
      ggplot2::aes(x = x, y = y, group = link_id, alpha = weight),
      linewidth = 0.4, na.rm = TRUE) +
    ggplot2::geom_point(data = rows,
      ggplot2::aes(x = x, y = y, colour = isolated), size = 1.6) +
    scale_y +
    ggplot2::scale_alpha_continuous(range = c(0.25, 1),
                                    name = "\u8fd1\u3055") +   # 近さ
    ggplot2::scale_colour_manual(
      values = c(`FALSE` = "grey30", `TRUE` = "firebrick"),
      name = "\u5b64\u7acb\u6587") +            # 孤立文
    ggplot2::labs(x = NULL, y = NULL) +
    # one unit across is one sentence down, so an arc keeps the shape of
    # the distance it spans instead of being stretched to fill the panel
    ggplot2::coord_fixed(ratio = ratio, clip = "off") +
    ggplot2::theme_minimal() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   axis.text.x = ggplot2::element_blank(),
                   axis.ticks  = ggplot2::element_blank(),
                   axis.text.y = ggplot2::element_text(size = 7))
  plot
}

#' One row per sentence, for the plot
#'
#' Internal function for [plot_sujimichi()].
#' Marks the sentences that share no word with any other sentence of
#' their paragraph, and cuts the text down to a label.
#'
#' @inheritParams plot_sujimichi
#' @return A tibble with `sentence_id`, `x`, `y`, `isolated` and
#'   `label`.
#' @keywords internal
sentence_rows <- function(links, sentences, paragraph = NULL, chars = 30){
  dead <- dead_code(links, sentences)
  dead <- in_paragraph(dead, sentences, paragraph)
  text <- rep("", nrow(dead))
  if(is.data.frame(sentences) && "sentence" %in% colnames(sentences)){
    at   <- match(dead[["sentence_id"]], sentences[["sentence_id"]])
    text <- as.character(sentences[["sentence"]][at])
    text[is.na(text)] <- ""
  }
  long <- nchar(text) > chars
  text[long] <- paste0(substr(text[long], 1, chars), "\u2026")
  tibble::tibble(sentence_id = dead[["sentence_id"]],
                 x        = 0,
                 y        = dead[["sentence_id"]],
                 isolated = dead[["isolated"]],
                 label    = text)
}

#' Steps of the plot
#'
#' Internal functions for [sujimichi_arcs()] and [plot_sujimichi()].
#'
#' * `check_links()` makes sure the table of links can be used.
#' * `in_paragraph()` keeps the rows of the chosen paragraphs.
#'
#' @inheritParams sujimichi_arcs
#' @param rows A data.frame with a `sentence_id` column.
#' @return A data.frame.
#' @keywords internal
check_links <- function(links){
  need <- c("sentence_id", "position", "prev_id", "distance")
  if(!is.data.frame(links) || !all(need %in% colnames(links))){
    stop("`links` must be a data.frame as returned by connect_sentences().",
         call. = FALSE)
  }
  links
}

#' @rdname check_links
#' @keywords internal
in_paragraph <- function(rows, sentences = NULL, paragraph = NULL){
  if(is.null(paragraph)) return(rows)
  if(!is.data.frame(sentences) ||
     !all(c("sentence_id", "paragraph_id") %in% colnames(sentences))){
    stop("`sentences` needs `sentence_id` and `paragraph_id` to pick ",
         "a paragraph.", call. = FALSE)
  }
  keep <- sentences[["sentence_id"]][
            sentences[["paragraph_id"]] %in% paragraph]
  rows[rows[["sentence_id"]] %in% keep, , drop = FALSE]
}
