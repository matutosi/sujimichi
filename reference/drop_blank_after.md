# Drop the blank lines that follow a marked line

Internal function for
[`strip_markdown()`](https://matutosi.github.io/sujimichi/reference/strip_markdown.md).
A blank line starts a new paragraph, so removing the one below a heading
is what joins the heading to the text that follows.

## Usage

``` r
drop_blank_after(lines, flag)
```

## Arguments

- lines:

  A character vector.

- flag:

  A logical vector, `TRUE` on the lines to look below.

## Value

A character vector.
