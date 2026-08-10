# Add a sentence terminator to the end of a line

Internal function for
[`strip_markdown()`](https://matutosi.github.io/sujimichi/reference/strip_markdown.md).
Nothing is added to an empty line, or to a line that already ends with a
terminator, possibly followed by a closing bracket.

## Usage

``` r
add_sentence_end(line, mark)
```

## Arguments

- line:

  A string.

- mark:

  A string. `""` adds nothing.

## Value

A string.
