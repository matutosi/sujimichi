# Strip Markdown notation to plain text

Removes Markdown syntax markers while keeping the body text, so the
result can be handed to
[`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md).
A fenced code block (```` ``` ```` or `~~~`) is removed entirely, fence
lines and content alike, because code is not prose and should not be
split into sentences. A heading, a list marker and a blockquote marker
are each removed, but the text after them is kept. An inline code span
keeps its content and loses only the backticks.

## Usage

``` r
strip_markdown(text)
```

## Arguments

- text:

  A character vector, one element per line.

## Value

A character vector of lines, with Markdown notation removed.

## Examples

``` r
strip_markdown(c("# 見出し", "",
                  "本文だ．", "",
                  "- 箇条書き1", "- 箇条書き2"))
#> [1] "見出し"    ""          "本文だ．"  ""          "箇条書き1" "箇条書き2"
```
