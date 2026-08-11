# Draw the sentences and their links with 'ggplot2'

Puts one sentence on each row and joins it to the sentence it shares a
word with by an arc, as sketched in `design.md`. A sentence that shares
no word with any other sentence of its paragraph – the dead code of
[`dead_code()`](https://matutosi.github.io/sujimichi/reference/dead_code.md)
– is drawn in a second colour, so that it can be picked out at a glance.

## Usage

``` r
plot_sujimichi(
  links,
  sentences,
  max_links = 3,
  paragraph = NULL,
  bulge = 0.5,
  label = TRUE,
  chars = 30,
  ratio = 1
)
```

## Arguments

- links:

  A data.frame as returned by
  [`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).

- sentences:

  A data.frame as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md),
  with `sentence_id`, `paragraph_id` and `sentence`.

- max_links:

  A number. How many links to draw for one sentence, counted from the
  front of the sentence. `3` follows the option in `design.md`.

- paragraph:

  A vector of `paragraph_id` to keep, or `NULL` (the default) for all of
  them. A whole book at once is unreadable, so a few paragraphs at a
  time is the usual way to look at this.

- bulge:

  A number. How far an arc bulges out, as a share of the distance it
  spans.

- label:

  A logical. Write the text of each sentence beside its row.

- chars:

  An integer. Longest label, in characters; what is left over is cut and
  marked with an ellipsis.

- ratio:

  A number, passed to `ggplot2::coord_fixed()`. One unit across the
  panel is `ratio` sentences down it, so an arc keeps the shape of the
  distance it spans; left free, the arcs stretch to fill the panel and a
  near link cannot be told from a far one. Raise it to squeeze the arcs,
  lower it to spread them out.

## Value

A 'ggplot' object, or `NULL` when 'ggplot2' is missing.

## Details

'ggplot2' is in `Suggests`: when it is not installed a message is shown
and `NULL` is returned, and the rest of the package still works.
[`sujimichi_arcs()`](https://matutosi.github.io/sujimichi/reference/sujimichi_arcs.md)
returns the same geometry as data for a reader who would rather draw it
another way.

## Examples

``` r
if (FALSE) { # \dontrun{
  # needs 'ggplot2'
  sentences <- as_sentences(sample_text())
  words <- data.frame(
    sentence_id = c(1, 1, 2, 2, 3),
    position    = c(1, 5, 1, 7, 1),
    word        = c("文章", "つながり", "つながり", "構造", "構造"))
  links <- connect_sentences(words, sentences)
  plot_sujimichi(links, sentences)
} # }
```
