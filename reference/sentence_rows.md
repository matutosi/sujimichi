# One row per sentence, for the plot

Internal function for
[`plot_sujimichi()`](https://matutosi.github.io/sujimichi/reference/plot_sujimichi.md).
Marks the sentences that share no word with any other sentence of their
paragraph, and cuts the text down to a label.

## Usage

``` r
sentence_rows(links, sentences, paragraph = NULL, chars = 30)
```

## Arguments

- links:

  A data.frame as returned by
  [`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).

- sentences:

  A data.frame as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md),
  with `sentence_id`, `paragraph_id` and `sentence`.

- paragraph:

  A vector of `paragraph_id` to keep, or `NULL` (the default) for all of
  them. A whole book at once is unreadable, so a few paragraphs at a
  time is the usual way to look at this.

- chars:

  An integer. Longest label, in characters; what is left over is cut and
  marked with an ellipsis.

## Value

A tibble with `sentence_id`, `x`, `y`, `isolated` and `label`.
