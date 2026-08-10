# Find dead code: sentences that share no word with their paragraph

Treats each paragraph as a graph: a sentence is a node, and a link from
[`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md)
– a sentence and the earlier sentence it shares a word with – is an edge
between the two. The connected components of this graph are found
paragraph by paragraph, as decided in `design.md`.

## Usage

``` r
dead_code(links, sentences)

broken_paragraphs(dead)
```

## Arguments

- links:

  A data.frame as returned by
  [`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).
  Only `sentence_id` and `prev_id` are used, so links from either
  `nearest = TRUE` or `FALSE` give the same components.

- sentences:

  A data.frame with `sentence_id` and `paragraph_id`, as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md).
  Fixes which paragraph a sentence belongs to, and lets a sentence
  outside `links` still get a component of its own.

- dead:

  A data.frame as returned by `dead_code()`.

## Value

A tibble with one row per sentence and columns `sentence_id`,
`paragraph_id`, `component` (numbered from 1 within each paragraph) and
`isolated` (`TRUE` when the sentence is the only member of its
component).

`broken_paragraphs()`: the `paragraph_id` values that hold two or more
components, sorted.

## Details

A sentence alone in its component – no edge to any earlier or later
sentence of the paragraph – shares no word with the rest of the
paragraph, and is dead code in the sense of `design.md`.
`broken_paragraphs()` instead looks at whole paragraphs: two or more
components mean the paragraph splits into parts that share no word with
each other, even when every sentence in it has some connection.

## Examples

``` r
sentences <- as_sentences(sample_text())
words <- tibble::tribble(
  ~sentence_id, ~position, ~word,
  1, 1, "文章", 1, 5, "単語", 1, 7, "つながり",
  2, 1, "つながり", 2, 9, "文章", 2, 11, "構造",
  3, 1, "構造", 3, 7, "文章")
links <- connect_sentences(words, sentences)
dead_code(links, sentences)
#> # A tibble: 3 × 4
#>   sentence_id paragraph_id component isolated
#>         <int>        <int>     <int> <lgl>   
#> 1           1            1         1 FALSE   
#> 2           2            1         1 FALSE   
#> 3           3            1         1 FALSE   
```
