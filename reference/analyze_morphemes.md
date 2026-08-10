# Run a morphological analysis on sentences

Hands the sentences to `moranajp::moranajp_all()` and renames the
`text_id` column to `sentence_id`. 'moranajp' runs 'MeCab', 'Sudachi' or
'Ginza' on the local machine; nothing is sent over the network.

## Usage

``` r
analyze_morphemes(
  sentences,
  method = "mecab",
  bin_dir = "",
  iconv = "",
  mecabrc = NULL,
  ...
)
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

- mecabrc:

  A string. Path of the `mecabrc` settings file. `NULL` (the default)
  looks for it next to `bin_dir`. `""` leaves the setting alone.

- ...:

  Passed to `moranajp::moranajp_all()`.

## Value

A tibble of morphemes with a `sentence_id` column, or `NULL` when the
analysis could not be run.

## Details

When 'moranajp' is not installed, or when the analyser cannot be run, a
message is shown and `NULL` is returned, so that a script does not stop
on a machine without an analyser.

'moranajp' joins the sentences with the marker `"BP"` and finds them
again by looking for a morpheme whose surface form is exactly `"BP"`.
When a sentence begins or ends with a latin word, MeCab reads the marker
and that word as one unknown noun (`"BPMeCab"`), the boundary is lost,
and every sentence after it is numbered one too low. Each sentence is
therefore padded with a space, which keeps the marker a morpheme of its
own. The numbering is checked afterwards, and a message is shown when it
still does not match.

MeCab on Windows reads its settings from the path it was built with, and
stops when the file is not there. `analyze_morphemes()` therefore looks
for `mecabrc` next to `bin_dir` and points the `MECABRC` environment
variable at it while the analysis runs. An `MECABRC` that is already set
is left alone.

## Examples

``` r
if (FALSE) { # \dontrun{
  # needs 'moranajp' and a local analyser such as MeCab
  sentences <- as_sentences(sample_text())
  analyze_morphemes(sentences, bin_dir = "d:/pf/mecab/bin")
} # }
```
