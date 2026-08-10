# Take a column out of a morpheme table

Internal function for
[`pick_content_words()`](https://matutosi.github.io/sujimichi/reference/pick_content_words.md).
Looks for the English column name first, then for the Japanese one used
by 'moranajp'.

## Usage

``` r
morpheme_col(morphemes, name)
```

## Arguments

- morphemes:

  A data.frame of morphemes.

- name:

  A string: "form", "pos", "pos_1" or "lemma".

## Value

A vector, or `NULL` when the column is missing.
