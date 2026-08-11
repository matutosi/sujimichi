# Points of the arcs that join the sentences

Lays the sentences out on a vertical axis, one row each, and draws the
link of each sentence as an arc back to the sentence it shares a word
with. This is the display sketched in `design.md` as the 'ggplot2' one;
it is returned as data, so that the geometry can be looked at, drawn
with something else, or tested without 'ggplot2'.

## Usage

``` r
sujimichi_arcs(
  links,
  sentences = NULL,
  max_links = 3,
  paragraph = NULL,
  bulge = 0.5,
  n = 32
)
```

## Arguments

- links:

  A data.frame as returned by
  [`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).

- sentences:

  A data.frame as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md),
  used to pick paragraphs. May be `NULL` when `paragraph` is `NULL`.

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

- n:

  An integer. Points drawn along one arc.

## Value

A tibble with one row per point and columns `link_id`, `sentence_id`,
`prev_id`, `word`, `distance`, `weight`, `x`, `y`. `link_id` groups the
points of one arc.

## Details

An arc is half an ellipse: it runs from `prev_id` up to `sentence_id` on
the y axis, and bulges out to `bulge * (distance / 2)` on the x axis. A
link that reaches further back therefore bulges further out.

## Examples

``` r
sentences <- data.frame(paragraph_id = c(1, 1, 1),
                        sentence_id  = c(1, 2, 3))
words <- data.frame(
  sentence_id = c(1, 1, 2, 2, 3),
  position    = c(1, 5, 1, 7, 1),
  word        = c("文章", "つながる", "つながる", "構造", "構造"))
links <- connect_sentences(words, sentences)
sujimichi_arcs(links, sentences)
#> # A tibble: 64 × 8
#>    link_id sentence_id prev_id word     distance weight        x     y
#>      <int>       <dbl>   <dbl> <chr>       <dbl>  <dbl>    <dbl> <dbl>
#>  1       1           2       1 つながる        1      1 1.53e-17  1   
#>  2       1           2       1 つながる        1      1 2.53e- 2  1.00
#>  3       1           2       1 つながる        1      1 5.03e- 2  1.01
#>  4       1           2       1 つながる        1      1 7.48e- 2  1.02
#>  5       1           2       1 つながる        1      1 9.86e- 2  1.04
#>  6       1           2       1 つながる        1      1 1.21e- 1  1.06
#>  7       1           2       1 つながる        1      1 1.43e- 1  1.09
#>  8       1           2       1 つながる        1      1 1.63e- 1  1.12
#>  9       1           2       1 つながる        1      1 1.81e- 1  1.16
#> 10       1           2       1 つながる        1      1 1.98e- 1  1.19
#> # ℹ 54 more rows
```
