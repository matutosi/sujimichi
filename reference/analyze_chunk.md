# Run the analyser over one chunk of sentences

Internal function for
[`analyze_morphemes()`](https://matutosi.github.io/sujimichi/reference/analyze_morphemes.md).
Returns `NULL` when the analysis could not be run, so that the caller
can say so once instead of once per chunk.

## Usage

``` r
analyze_chunk(sentences, method, bin_dir, iconv, ...)
```

## Arguments

- sentences:

  A character vector of sentences, or a data.frame with a `sentence`
  column as returned by
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

- ...:

  Passed to `moranajp::moranajp_all()`.

## Value

A data.frame of morphemes with a `sentence_id` column, or `NULL`.
