# Strip Markdown notation to plain text

Removes Markdown syntax markers while keeping the body text, so the
result can be handed to
[`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md).
A fenced code block (```` ``` ```` or `~~~`) is removed entirely, fence
lines and content alike, because code is not prose and should not be
split into sentences. A heading, a list marker and a blockquote marker
are each removed, but the text after them is kept. An inline code span
keeps its content and loses only the backticks, unless the content holds
no letter and no digit (`` `.` ``), in which case the span goes away
with it; a bare mark left behind would otherwise be read as the end of a
sentence.

## Usage

``` r
strip_markdown(text, list_end = sentence_marks()[[2]])
```

## Arguments

- text:

  A character vector, one element per line.

- list_end:

  A string added to the end of a list item that does not end with a
  sentence terminator. The fullwidth full stop (．) by default; `""`
  adds nothing.

## Value

A character vector of lines, with Markdown notation removed.

## Details

A link (`[text](url)`) keeps its text and loses the address, since the
text is part of the prose while the address is not. An image
(`![alt](url)`) is removed as a whole, and so is an autolink
(`<https://example.com>`). Emphasis marks (`**`, `*`, `__`) are removed
and the text between them is kept. A lone `_` is left alone, because it
is more often part of a name such as `sentence_id` than a mark of
emphasis.

A list item is a sentence of its own, but it rarely ends with a full
stop.
[`split_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md)
joins the lines of a paragraph, because a Japanese manuscript breaks a
line in the middle of a sentence, so the items of a list would otherwise
be run together into one long sentence. A terminator is therefore added
to an item that does not already end with one. Pass `list_end = ""` to
leave the items as they are.

## Examples

``` r
strip_markdown(c("# 見出し", "",
                  "本文だ．", "",
                  "- 箇条書き1", "- 箇条書き2"))
#> [1] "見出し"      ""            "本文だ．"    ""            "箇条書き1．"
#> [6] "箇条書き2．"
strip_markdown("**強調**した[リンク](https://example.com)．")
#> [1] "強調したリンク．"

# a list item becomes a sentence of its own
strip_markdown(c("- 箇条書き1", "- 箇条書き2"))
#> [1] "箇条書き1．" "箇条書き2．"
```
