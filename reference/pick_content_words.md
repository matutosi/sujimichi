# Pick the content words out of a morpheme table

Keeps the morphemes whose part of speech is in `pos`, and returns one
row per kept morpheme. A word is represented by its lemma (原形), so
that 「つながり」 and 「つながる」 count as the same word. The surface
form (表層形) is used instead when the analyser does not know the lemma
and writes `"*"`.

## Usage

``` r
pick_content_words(
  morphemes,
  pos = content_pos(),
  skip_pos_1 = skipped_pos_1(),
  stop_words = stop_words_ja(),
  id_col = "sentence_id"
)
```

## Arguments

- morphemes:

  A data.frame of morphemes, as returned by
  [`analyze_morphemes()`](https://matutosi.github.io/sujimichi/reference/analyze_morphemes.md).

- pos:

  A character vector of parts of speech to keep.

- skip_pos_1:

  A character vector of sub categories to drop.

- stop_words:

  A character vector of words to drop.

- id_col:

  A string. The column that holds the sentence number.

## Value

A tibble with one row per content word and columns `sentence_id`,
`position`, `word`, `pos` and `pos_1`. `position` is the place of the
morpheme in its sentence, counted over all morphemes, so that an earlier
word keeps a smaller number after the other morphemes are dropped.

## Details

The table may use either the Japanese column names of 'moranajp'
(表層形, 品詞, 品詞細分類1, 原形) or the English ones (`form`, `pos`,
`pos_1`, `lemma`); see `moranajp::moranajp_all()`.

## Examples

``` r
# a morpheme table as an analyser would return it
morphemes <- data.frame(
  sentence_id = c(1, 1, 1, 1, 1),
  form   = c("文章", "と", "は", "つながり", "だ"),
  pos    = c("名詞", "助詞", "助詞", "動詞", "助動詞"),
  pos_1  = c("一般", "格助詞", "係助詞", "自立", ""),
  lemma  = c("文章", "と", "は", "つながる", "だ"))
pick_content_words(morphemes)
#> # A tibble: 2 × 5
#>   sentence_id position word     pos   pos_1
#>         <dbl>    <int> <chr>    <chr> <chr>
#> 1           1        1 文章     名詞  一般 
#> 2           1        4 つながる 動詞  自立 
```
