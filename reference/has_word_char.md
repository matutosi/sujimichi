# Tell whether a word holds a letter or a digit

Internal function for
[`pick_content_words()`](https://matutosi.github.io/sujimichi/reference/pick_content_words.md).
A morpheme made only of punctuation and symbols carries no content, and
is dropped even when the analyser labelled it a noun.

## Usage

``` r
has_word_char(word)
```

## Arguments

- word:

  A character vector.

## Value

A logical vector.
