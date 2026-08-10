# Find the last line of each list item

Internal function for
[`strip_markdown()`](https://matutosi.github.io/sujimichi/reference/strip_markdown.md).
An item may run over several lines: the lines after the marker are
indented and carry no marker of their own. The terminator belongs at the
end of the whole item, not at the end of its first line, which would cut
the item in two.

## Usage

``` r
list_item_ends(lines)
```

## Arguments

- lines:

  A character vector.

## Value

A logical vector, `TRUE` on the last line of each item.
