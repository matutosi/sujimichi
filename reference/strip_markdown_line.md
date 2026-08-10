# Strip the Markdown notation of one line

Internal function for
[`strip_markdown()`](https://matutosi.github.io/sujimichi/reference/strip_markdown.md).

## Usage

``` r
strip_markdown_line(line, list_end = "")
```

## Arguments

- line:

  A string.

- list_end:

  A string added to the end of a list item that does not end with a
  sentence terminator. The fullwidth full stop (．) by default; `""`
  adds nothing.

## Value

A string.
