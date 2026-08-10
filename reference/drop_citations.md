# Remove the citations from a text

A citation names an author and a year, and says nothing about the line
of reasoning of the text itself. Left in, the author names and the years
become content words and link sentences that have nothing in common but
a source.

## Usage

``` r
drop_citations(text)
```

## Arguments

- text:

  A character vector.

## Value

A character vector, with the citations removed.

## Details

A bracket is read as a citation when it holds a year, that is four
digits from 1800 to 2099. Fullwidth brackets (（）) and ASCII ones are
both removed. A bracket without a year is kept, so that a note such as
「(以下，畦畔草原という)」 stays in the text. A year that stands outside
a bracket, as in 「2011年の調査では」, is part of the prose and is kept.

Use it before
[`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md),
next to
[`strip_markdown()`](https://matutosi.github.io/sujimichi/reference/strip_markdown.md).

## Examples

``` r
drop_citations("畦畔は重要である（丑丸2012）．")
#> [1] "畦畔は重要である．"

# a bracket without a year is a note, and stays
drop_citations("畦畔法面に成立する草原(以下，畦畔草原という)を扱う．")
#> [1] "畦畔法面に成立する草原(以下，畦畔草原という)を扱う．"
```
