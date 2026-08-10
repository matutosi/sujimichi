# Content words of a text

Splits a text into sentences, runs a morphological analysis and picks
the content words. A shortcut for
[`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md),
[`analyze_morphemes()`](https://matutosi.github.io/sujimichi/reference/analyze_morphemes.md)
and
[`pick_content_words()`](https://matutosi.github.io/sujimichi/reference/pick_content_words.md)
in a row.

## Usage

``` r
content_words(
  text,
  method = "mecab",
  bin_dir = "",
  iconv = "",
  pos = content_pos(),
  skip_pos_1 = skipped_pos_1(),
  stop_words = stop_words_ja(),
  ...
)
```

## Arguments

- text:

  A character vector of lines, or a data.frame of sentences as returned
  by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md).

- method:

  A string. Passed to `moranajp::moranajp_all()`: "mecab", "ginza",
  "sudachi_a", "sudachi_b" or "sudachi_c".

- bin_dir:

  A string. Directory of the analyser.

- iconv:

  A string. Encoding conversion of the analyser output, for example
  "CP932_UTF-8" when MeCab was built for Shift-JIS. Leave it empty for a
  UTF-8 dictionary.

- pos:

  A character vector of parts of speech to keep.

- skip_pos_1:

  A character vector of sub categories to drop.

- stop_words:

  A character vector of words to drop.

- ...:

  Passed to `moranajp::moranajp_all()`.

## Value

A tibble as returned by
[`pick_content_words()`](https://matutosi.github.io/sujimichi/reference/pick_content_words.md),
or `NULL` when the analysis could not be run. Join it to the table of
[`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md)
by `sentence_id`.

## Examples

``` r
if (FALSE) { # \dontrun{
  # needs 'moranajp' and a local analyser such as MeCab
  content_words(sample_text(), bin_dir = "d:/pf/mecab/bin")
} # }
```
