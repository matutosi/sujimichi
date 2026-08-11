#' Connect each sentence to the earlier sentences it shares a word with
#'
#' Walks through the content words of a text and looks back for an
#' earlier sentence that holds the same word.  One row is returned per
#' link, that is per pair of a word and the earlier sentence it points
#' to.  A sentence that shares no word with any earlier sentence of its
#' paragraph gets one row with `NA` in `word` and `prev_id`, so that
#' every sentence appears in the table.
#'
#' Only the earlier sentences of the same paragraph are searched, as
#' decided in `design.md`.  When `sentences` is not given, the whole text
#' is treated as one paragraph.
#'
#' The word that comes first in a sentence is taken as the
#' representative of that sentence, and gets `is_main = TRUE`.
#' A tie is settled by the nearer earlier sentence.
#'
#' @param words A data.frame of content words with columns
#'   `sentence_id`, `position` and `word`, as returned by
#'   [pick_content_words()] or [content_words()].
#' @param sentences A data.frame of sentences with columns
#'   `sentence_id` and `paragraph_id`, as returned by [as_sentences()].
#'   It fixes the paragraph a sentence belongs to, and lets a sentence
#'   without any content word appear in the table.
#' @param nearest A logical.  `TRUE` (the default) keeps only the
#'   nearest earlier sentence for each word.  `FALSE` keeps every
#'   earlier sentence that holds the word.
#' @param max_links A number.  The largest number of links kept for one
#'   sentence, counted from the front of the sentence.  `Inf` (the
#'   default) keeps them all; `3` follows the option in `design.md`.
#'   Over a review paper of 461 sentences a sentence had five links in
#'   the middle of the range, and cutting at three threw away half of
#'   them, which is why the default keeps them all and the cut is left
#'   to the display.
#' @param weight One of `"inverse"` (the default) or `"distance"`,
#'   the two ways `design.md` leaves open for turning the distance into
#'   a weight.  `"inverse"` gives `1 / distance`, so that a nearer
#'   sentence weighs more and the number reads the same way round as
#'   the other measures; `"distance"` gives the distance itself.
#' @return A tibble with one row per link and these columns.
#'   * `sentence_id`: the sentence that looks back.
#'   * `word`: the shared word, as a lemma.  `NA` when the sentence
#'     shares no word.
#'   * `position`: the place of the word in its sentence, counted over
#'     all morphemes.  The smaller, the closer to the front.
#'   * `prev_id`: the earlier sentence that holds the same word.
#'   * `distance`: `sentence_id - prev_id`.  The smaller, the closer.
#'   * `weight`: the distance turned into a weight, see `weight`.
#'     Over a review paper 69 per cent of the links ran to the sentence
#'     right before, so the weight is close to 1 most of the time and a
#'     link reaching further back stands out.
#'   * `is_main`: whether the row is the representative of its sentence.
#'   * `referred`: how many later sentences look back at `sentence_id`.
#'     A high count marks a sentence that the rest of the paragraph
#'     leans on, such as a topic sentence.
#' @examples
#' sentences <- data.frame(
#'   paragraph_id = c(1, 1, 1),
#'   sentence_id  = c(1, 2, 3))
#' words <- data.frame(
#'   sentence_id = c(1, 1, 2, 2, 3),
#'   position    = c(1, 5, 1, 7, 1),
#'   word        = c("文章", "つながる", "つながる", "構造", "構造"))
#' connect_sentences(words, sentences)
#'
#' @export
connect_sentences <- function(words, sentences = NULL,
                              nearest = TRUE, max_links = Inf,
                              weight = c("inverse", "distance")){
  weight <- match.arg(weight)
  words <- check_words(words)
  ids   <- sentence_ids(words, sentences)
  para  <- ids[["paragraph_id"]]
  names(para) <- as.character(ids[["sentence_id"]])

  linked <- link_rows(words, para, nearest = nearest)
  linked <- keep_first_links(linked, max_links = max_links)
  linked <- add_lonely_rows(linked, ids[["sentence_id"]])
  linked[["weight"]]   <- link_weight(linked[["distance"]], weight)
  linked[["referred"]] <- count_referred(linked)
  cols <- c("sentence_id", "word", "position",
            "prev_id", "distance", "weight", "is_main", "referred")
  linked <- linked[order(linked[["sentence_id"]],
                         !linked[["is_main"]],
                         linked[["position"]]), cols, drop = FALSE]
  tibble::as_tibble(linked)
}

#' Steps of connect_sentences()
#'
#' Internal functions for [connect_sentences()].
#'
#' * `check_words()` makes sure the table of content words can be used,
#'   and sorts it by sentence and by place in the sentence.
#' * `sentence_ids()` settles which sentences to walk through and which
#'   paragraph each belongs to.
#' * `link_rows()` builds one row per link.
#' * `keep_first_links()` keeps at most `max_links` rows per sentence,
#'   counted from the front of the sentence, and marks the first of them
#'   as the representative.
#' * `add_lonely_rows()` adds an empty row for a sentence without a link.
#' * `link_weight()` turns the distance into a weight.
#' * `count_referred()` counts, for each sentence, the later sentences
#'   that look back at it.
#'
#' @inheritParams connect_sentences
#' @param para A named vector of paragraph numbers, named by sentence
#'   number.
#' @param linked A data.frame of links.
#' @param all_ids A vector of every sentence number.
#' @return A data.frame, or a vector for `count_referred()`.
#' @keywords internal
check_words <- function(words){
  if(!is.data.frame(words)){
    stop("`words` must be a data.frame.", call. = FALSE)
  }
  need <- c("sentence_id", "position", "word")
  miss <- need[!need %in% colnames(words)]
  if(length(miss) > 0){
    stop("`words` has no column(s): ", paste(miss, collapse = ", "),
         ".", call. = FALSE)
  }
  words <- as.data.frame(words[need])
  words[order(words[["sentence_id"]], words[["position"]]), , drop = FALSE]
}

#' @rdname check_words
#' @keywords internal
sentence_ids <- function(words, sentences = NULL){
  if(is.null(sentences)){
    ids <- sort(unique(words[["sentence_id"]]))
    return(data.frame(sentence_id = ids,
                      paragraph_id = rep(1L, length(ids))))
  }
  if(!is.data.frame(sentences) ||
     !"sentence_id" %in% colnames(sentences)){
    stop("`sentences` must be a data.frame with a `sentence_id` column.",
         call. = FALSE)
  }
  ids <- sentences[["sentence_id"]]
  par <- if("paragraph_id" %in% colnames(sentences)){
           sentences[["paragraph_id"]]
         }else{
           rep(1L, length(ids))
         }
  out <- data.frame(sentence_id = ids, paragraph_id = par)
  out[order(out[["sentence_id"]]), , drop = FALSE]
}

#' @rdname check_words
#' @keywords internal
link_rows <- function(words, para, nearest = TRUE){
  empty <- data.frame(sentence_id = numeric(0), word = character(0),
                      position = numeric(0), prev_id = numeric(0),
                      distance = numeric(0))
  if(nrow(words) == 0) return(empty)
  id      <- words[["sentence_id"]]
  word    <- as.character(words[["word"]])
  in_para <- unname(para[as.character(id)])
  rows    <- vector("list", length(id))
  for(i in seq_along(id)){
    if(is.na(in_para[[i]])) next
    same <- id < id[[i]] & word == word[[i]] & in_para %in% in_para[[i]]
    prev <- unique(id[same])
    if(length(prev) == 0) next
    if(nearest) prev <- max(prev)
    rows[[i]] <- data.frame(
      sentence_id = id[[i]], word = word[[i]], position = words[["position"]][[i]],
      prev_id = prev, distance = id[[i]] - prev)
  }
  rows <- do.call(rbind, rows)
  if(is.null(rows)) empty else rows
}

#' @rdname check_words
#' @keywords internal
keep_first_links <- function(linked, max_links = Inf){
  linked <- linked[order(linked[["sentence_id"]], linked[["position"]],
                         linked[["distance"]]), , drop = FALSE]
  if(nrow(linked) == 0){
    linked[["is_main"]] <- logical(0)
    return(linked)
  }
  rank   <- stats::ave(seq_len(nrow(linked)), linked[["sentence_id"]],
                       FUN = seq_along)
  linked <- linked[rank <= max_links, , drop = FALSE]
  linked[["is_main"]] <- rank[rank <= max_links] == 1
  linked
}

#' @rdname check_words
#' @keywords internal
add_lonely_rows <- function(linked, all_ids){
  lonely <- all_ids[!all_ids %in% linked[["sentence_id"]]]
  if(length(lonely) == 0) return(linked)
  rbind(linked, data.frame(
    sentence_id = lonely,
    word        = NA_character_,
    position    = NA_real_,
    prev_id     = NA_real_,
    distance    = NA_real_,
    is_main     = TRUE))
}

#' @rdname check_words
#' @param distance A numeric vector.
#' @param how A string: `"inverse"` or `"distance"`.
#' @keywords internal
link_weight <- function(distance, how = "inverse"){
  distance <- as.numeric(distance)
  if(how == "distance") return(distance)
  1 / distance
}

#' @rdname check_words
#' @keywords internal
count_referred <- function(linked){
  zero <- rep(0L, nrow(linked))
  has  <- !is.na(linked[["prev_id"]])
  if(!any(has)) return(zero)
  pairs <- unique(linked[has, c("sentence_id", "prev_id")])
  count <- table(pairs[["prev_id"]])
  out   <- as.integer(count[as.character(linked[["sentence_id"]])])
  ifelse(is.na(out), 0L, out)
}
