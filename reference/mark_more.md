# Mark the other shared words of a line

Internal function for
[`format_sujimichi()`](https://matutosi.github.io/sujimichi/reference/sujimichi_lines.md).
`design.md` asks for an option to show up to three connections. The
representative settles the indent and is marked by
[`sujimichi_lines()`](https://matutosi.github.io/sujimichi/reference/sujimichi_lines.md);
the others are marked here, in the text that follows it, so that the
alignment worked out from the text before the representative is left
alone. A word that is not written as its lemma says is passed over.

## Usage

``` r
mark_more(lines, links, words = NULL, wrap = c("(", ")"), max_marks = 1)
```

## Arguments

- lines:

  A data.frame as returned by
  [`sujimichi_lines()`](https://matutosi.github.io/sujimichi/reference/sujimichi_lines.md).

- links:

  A data.frame as returned by
  [`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).

- words:

  A data.frame as returned by
  [`content_words()`](https://matutosi.github.io/sujimichi/reference/content_words.md),
  or `NULL`.

- wrap:

  A character vector of length 2.

- max_marks:

  A number.

## Value

A character vector, the `after` part of each line.

## Details

The other words are widened over a split compound in the same way as the
representative, and a word that the widening has already brought into an
earlier mark is passed over, so that 「畦」 and 「畔」 give one
「(畦畔)」 rather than 「(畦)(畔)」.
