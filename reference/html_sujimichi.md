# Write the sentences and their links as HTML

The third of the displays sketched in `design.md`: the same picture as
[`print_sujimichi()`](https://matutosi.github.io/sujimichi/reference/sujimichi_lines.md),
marked up with `<span>` so that it can be pasted into R Markdown or
Quarto.

## Usage

``` r
html_sujimichi(links, sentences, words = NULL, max_marks = 1, css = TRUE)

# S3 method for class 'sujimichi_html'
print(x, ...)
```

## Arguments

- links:

  A data.frame as returned by
  [`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).

- sentences:

  A data.frame as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md),
  with `sentence_id`, `paragraph_id` and `sentence`.

- words:

  A data.frame as returned by
  [`content_words()`](https://matutosi.github.io/sujimichi/reference/content_words.md),
  or `NULL` (the default) to mark the shared word on its own.

- max_marks:

  A number. How many shared words to mark in one line, as in
  [`format_sujimichi()`](https://matutosi.github.io/sujimichi/reference/sujimichi_lines.md).

- css:

  A logical. Put a `<style>` block in front of the lines.

- x:

  A `sujimichi_html` string.

- ...:

  Ignored.

## Value

A string of HTML, of class `sujimichi_html`.

[`print()`](https://rdrr.io/r/base/print.html): `x`, invisibly. The HTML
is written as it is, so that a chunk with `results = "asis"` renders it.

## Details

The lines are wrapped in `<pre>`, which keeps the spaces that carry the
alignment. The widths were counted with
[`stringi::stri_width()`](https://rdrr.io/pkg/stringi/man/stri_width.html),
which gives a full-width character two columns, so the alignment comes
out right in a monospaced font that draws them that way.

The shared word of each sentence is put in
`<span class="sujimichi-word">`, and a sentence that shares no word with
any other sentence of its paragraph – the dead code of
[`dead_code()`](https://matutosi.github.io/sujimichi/reference/dead_code.md)
– in `<span class="sujimichi-dead">`. With `css = TRUE` a `<style>`
block for those two classes comes with it, so that the result stands on
its own; pass `css = FALSE` and write the rules yourself when the
document already has a style sheet.

In an R Markdown chunk, use `results = "asis"`.

## Examples

``` r
sentences <- as_sentences(sample_text())
words <- data.frame(
  sentence_id = c(1, 1, 2, 2, 3),
  position    = c(1, 5, 1, 7, 1),
  word        = c("文章", "つながり", "つながり", "構造", "構造"))
links <- connect_sentences(words, sentences)
html <- html_sujimichi(links, sentences)
substr(html, 1, 60)
#> <style>
#> .sujimichi { font-family: monospace; line-height: 1.
```
