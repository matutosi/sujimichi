# Take the inline code spans out of a line

Internal function for
[`strip_markdown()`](https://matutosi.github.io/sujimichi/reference/strip_markdown.md).
A span keeps its content and loses the backticks, unless the content
holds no letter and no digit, in which case the span goes away with it;
a bare mark left behind would be read as the end of a sentence.

## Usage

``` r
strip_code_spans(line)
```

## Arguments

- line:

  A string.

## Value

A string.

## Details

The spans are taken one pair of backticks at a time, from the left. A
single pattern would match from the closing backtick of one span to the
opening backtick of the next, and would swallow what lies between them:
`` `a`，`b` `` would come out as `ab`.
