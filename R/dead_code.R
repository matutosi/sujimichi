#' Find dead code: sentences that share no word with their paragraph
#'
#' Treats each paragraph as a graph: a sentence is a node, and a link
#' from [connect_sentences()] -- a sentence and the earlier sentence it
#' shares a word with -- is an edge between the two.  The connected
#' components of this graph are found paragraph by paragraph, as
#' decided in `design.md`.
#'
#' A sentence alone in its component -- no edge to any earlier or
#' later sentence of the paragraph -- shares no word with the rest of
#' the paragraph, and is dead code in the sense of `design.md`.
#' [broken_paragraphs()] instead looks at whole paragraphs: two or more
#' components mean the paragraph splits into parts that share no word
#' with each other, even when every sentence in it has some connection.
#'
#' @param links A data.frame as returned by [connect_sentences()].
#'   Only `sentence_id` and `prev_id` are used, so links from either
#'   `nearest = TRUE` or `FALSE` give the same components.
#' @param sentences A data.frame with `sentence_id` and
#'   `paragraph_id`, as returned by [as_sentences()].  Fixes which
#'   paragraph a sentence belongs to, and lets a sentence outside
#'   `links` still get a component of its own.
#' @return A tibble with one row per sentence and columns
#'   `sentence_id`, `paragraph_id`, `component` (numbered from 1
#'   within each paragraph) and `isolated` (`TRUE` when the sentence is
#'   the only member of its component).
#' @examples
#' sentences <- as_sentences(sample_text())
#' words <- tibble::tribble(
#'   ~sentence_id, ~position, ~word,
#'   1, 1, "文章", 1, 5, "単語", 1, 7, "つながり",
#'   2, 1, "つながり", 2, 9, "文章", 2, 11, "構造",
#'   3, 1, "構造", 3, 7, "文章")
#' links <- connect_sentences(words, sentences)
#' dead_code(links, sentences)
#'
#' @export
dead_code <- function(links, sentences){
  if(!is.data.frame(links)){
    stop("`links` must be a data.frame.", call. = FALSE)
  }
  need <- c("sentence_id", "prev_id")
  miss <- need[!need %in% colnames(links)]
  if(length(miss) > 0){
    stop("`links` has no column(s): ", paste(miss, collapse = ", "),
         ".", call. = FALSE)
  }
  if(!is.data.frame(sentences)){
    stop("`sentences` must be a data.frame.", call. = FALSE)
  }
  need <- c("sentence_id", "paragraph_id")
  miss <- need[!need %in% colnames(sentences)]
  if(length(miss) > 0){
    stop("`sentences` has no column(s): ", paste(miss, collapse = ", "),
         ".", call. = FALSE)
  }
  ids <- sentences[order(sentences[["sentence_id"]]),
                   c("sentence_id", "paragraph_id"), drop = FALSE]
  ids <- ids[!duplicated(ids[["sentence_id"]]), , drop = FALSE]
  edges <- links[!is.na(links[["prev_id"]]),
                 c("sentence_id", "prev_id"), drop = FALSE]

  component <- rep(NA_integer_, nrow(ids))
  names(component) <- as.character(ids[["sentence_id"]])
  for(p in unique(ids[["paragraph_id"]])){
    node <- ids[["sentence_id"]][ids[["paragraph_id"]] == p]
    keep <- edges[["sentence_id"]] %in% node & edges[["prev_id"]] %in% node
    component[as.character(node)] <- find_components(
      node, edges[["sentence_id"]][keep], edges[["prev_id"]][keep])
  }
  component <- unname(component[as.character(ids[["sentence_id"]])])
  key  <- paste(ids[["paragraph_id"]], component)
  size <- stats::ave(seq_along(key), key, FUN = length)

  tibble::tibble(sentence_id = ids[["sentence_id"]],
                 paragraph_id = ids[["paragraph_id"]],
                 component = component, isolated = size == 1)
}

#' Steps of dead_code()
#'
#' Internal function for [dead_code()].
#' `find_components()` runs a union-find over the sentences of one
#' paragraph, and numbers the components from 1 in the order `node`
#' first meets each of them.
#'
#' @param node A vector of sentence numbers, the nodes of one paragraph.
#' @param from,to Vectors of sentence numbers, the two ends of each
#'   edge within that paragraph.
#' @return An integer vector, named by `node`, with a component number
#'   for each.
#' @keywords internal
find_components <- function(node, from, to){
  idx    <- stats::setNames(seq_along(node), as.character(node))
  parent <- seq_along(node)
  root <- function(x){
    while(parent[[x]] != x) x <- parent[[x]]
    x
  }
  for(i in seq_along(from)){
    a <- root(idx[[as.character(from[[i]])]])
    b <- root(idx[[as.character(to[[i]])]])
    if(a != b) parent[[a]] <- b
  }
  roots <- vapply(seq_along(node), root, integer(1))
  stats::setNames(match(roots, unique(roots)), as.character(node))
}

#' @rdname dead_code
#' @param dead A data.frame as returned by [dead_code()].
#' @return `broken_paragraphs()`: the `paragraph_id` values that hold
#'   two or more components, sorted.
#' @export
broken_paragraphs <- function(dead){
  if(!is.data.frame(dead)){
    stop("`dead` must be a data.frame.", call. = FALSE)
  }
  need <- c("paragraph_id", "component")
  miss <- need[!need %in% colnames(dead)]
  if(length(miss) > 0){
    stop("`dead` has no column(s): ", paste(miss, collapse = ", "),
         ".", call. = FALSE)
  }
  count <- tapply(dead[["component"]], dead[["paragraph_id"]],
                  function(x) length(unique(x)))
  sort(as.numeric(names(count)[count >= 2]))
}
