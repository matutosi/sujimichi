# Escape the characters that mean something in HTML

Internal function for
[`html_sujimichi()`](https://matutosi.github.io/sujimichi/reference/html_sujimichi.md).
The ampersand goes first, or the ampersands of the other escapes would
be escaped in their turn.

## Usage

``` r
escape_html(text)
```

## Arguments

- text:

  A character vector.

## Value

A character vector.
