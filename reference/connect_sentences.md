# Connect each sentence to the earlier sentences it shares a word with

Walks through the content words of a text and looks back for an earlier
sentence that holds the same word. One row is returned per link, that is
per pair of a word and the earlier sentence it points to. A sentence
that shares no word with any earlier sentence of its paragraph gets one
row with `NA` in `word` and `prev_id`, so that every sentence appears in
the table.

## Usage

``` r
connect_sentences(
  words,
  sentences = NULL,
  nearest = TRUE,
  max_links = Inf,
  weight = c("inverse", "distance")
)
```

## Arguments

- words:

  A data.frame of content words with columns `sentence_id`, `position`
  and `word`, as returned by
  [`pick_content_words()`](https://matutosi.github.io/sujimichi/reference/pick_content_words.md)
  or
  [`content_words()`](https://matutosi.github.io/sujimichi/reference/content_words.md).

- sentences:

  A data.frame of sentences with columns `sentence_id` and
  `paragraph_id`, as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md).
  It fixes the paragraph a sentence belongs to, and lets a sentence
  without any content word appear in the table.

- nearest:

  A logical. `TRUE` (the default) keeps only the nearest earlier
  sentence for each word. `FALSE` keeps every earlier sentence that
  holds the word.

- max_links:

  A number. The largest number of links kept for one sentence, counted
  from the front of the sentence. `Inf` (the default) keeps them all;
  `3` follows the option in `design.md`. Over a review paper of 461
  sentences a sentence had five links in the middle of the range, and
  cutting at three threw away half of them, which is why the default
  keeps them all and the cut is left to the display.

- weight:

  One of `"inverse"` (the default) or `"distance"`, the two ways
  `design.md` leaves open for turning the distance into a weight.
  `"inverse"` gives `1 / distance`, so that a nearer sentence weighs
  more and the number reads the same way round as the other measures;
  `"distance"` gives the distance itself.

## Value

A tibble with one row per link and these columns.

- `sentence_id`: the sentence that looks back.

- `word`: the shared word, as a lemma. `NA` when the sentence shares no
  word.

- `position`: the place of the word in its sentence, counted over all
  morphemes. The smaller, the closer to the front.

- `prev_id`: the earlier sentence that holds the same word.

- `distance`: `sentence_id - prev_id`. The smaller, the closer.

- `weight`: the distance turned into a weight, see `weight`. Over a
  review paper 69 per cent of the links ran to the sentence right
  before, so the weight is close to 1 most of the time and a link
  reaching further back stands out.

- `is_main`: whether the row is the representative of its sentence.

- `referred`: how many later sentences look back at `sentence_id`. A
  high count marks a sentence that the rest of the paragraph leans on,
  such as a topic sentence.

## Details

Only the earlier sentences of the same paragraph are searched, as
decided in `design.md`. When `sentences` is not given, the whole text is
treated as one paragraph.

The word that comes first in a sentence is taken as the representative
of that sentence, and gets `is_main = TRUE`. A tie is settled by the
nearer earlier sentence.

## Examples

``` r
sentences <- data.frame(
  paragraph_id = c(1, 1, 1),
  sentence_id  = c(1, 2, 3))
words <- data.frame(
  sentence_id = c(1, 1, 2, 2, 3),
  position    = c(1, 5, 1, 7, 1),
  word        = c("文章", "つながる", "つながる", "構造", "構造"))
connect_sentences(words, sentences)
#> # A tibble: 3 × 8
#>   sentence_id word     position prev_id distance weight is_main referred
#>         <dbl> <chr>       <dbl>   <dbl>    <dbl>  <dbl> <lgl>      <int>
#> 1           1 NA             NA      NA       NA     NA TRUE           1
#> 2           2 つながる        1       1        1      1 TRUE           1
#> 3           3 構造            1       2        1      1 TRUE           0
```
