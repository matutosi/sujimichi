# Steps of the plot

Internal functions for
[`sujimichi_arcs()`](https://matutosi.github.io/sujimichi/reference/sujimichi_arcs.md)
and
[`plot_sujimichi()`](https://matutosi.github.io/sujimichi/reference/plot_sujimichi.md).

## Usage

``` r
check_links(links)

in_paragraph(rows, sentences = NULL, paragraph = NULL)
```

## Arguments

- links:

  A data.frame as returned by
  [`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).

- rows:

  A data.frame with a `sentence_id` column.

- sentences:

  A data.frame as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md),
  used to pick paragraphs. May be `NULL` when `paragraph` is `NULL`.

- paragraph:

  A vector of `paragraph_id` to keep, or `NULL` (the default) for all of
  them. A whole book at once is unreadable, so a few paragraphs at a
  time is the usual way to look at this.

## Value

A data.frame.

## Details

- `check_links()` makes sure the table of links can be used.

- `in_paragraph()` keeps the rows of the chosen paragraphs.
