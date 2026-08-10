# Widen a word over the nouns beside it

Internal function for
[`sujimichi_lines()`](https://matutosi.github.io/sujimichi/reference/sujimichi_lines.md).
An analyser splits a compound word it does not know, and the pieces sit
next to each other as nouns. The run of nouns around `position` is put
back together, and taken only when it reads in the sentence as it
stands; a lemma that differs from what was written would otherwise
produce a string that is nowhere in the text.

## Usage

``` r
widen_to_compound(words, sentence_id, position, word, text)
```

## Arguments

- words:

  A data.frame as returned by
  [`content_words()`](https://matutosi.github.io/sujimichi/reference/content_words.md).

- sentence_id:

  The sentence the word is in.

- position:

  The place of the word among the morphemes.

- word:

  A string. The shared word itself.

- text:

  A string. The sentence as written.

## Value

A string: the compound, or `word` when there is none.
