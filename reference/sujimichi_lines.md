# Show sentences on the console with the connecting word aligned

Builds one line per sentence, indented so that the word it shares with
its earlier sentence lines up under the same word written in that
earlier line, and marks the word with `wrap`. This is the console
display sketched in `design.md`:

## Usage

``` r
sujimichi_lines(links, sentences, words = NULL, wrap = c("(", ")"))

format_sujimichi(links, sentences, words = NULL, wrap = c("(", ")"))

print_sujimichi(
  links,
  sentences,
  words = NULL,
  wrap = c("(", ")"),
  color = interactive(),
  file = ""
)
```

## Arguments

- links:

  A data.frame as returned by
  [`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).

- sentences:

  A data.frame with `sentence_id` and `sentence`, as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md).

- words:

  A data.frame as returned by
  [`content_words()`](https://matutosi.github.io/sujimichi/reference/content_words.md),
  or `NULL` (the default) to mark the shared word on its own.

- wrap:

  A character vector of length 2: the marks put around the shared word.

- color:

  A logical. Colour the marked word with ANSI escapes. Defaults to
  [`interactive()`](https://rdrr.io/r/base/interactive.html), so example
  runs and `R CMD check` stay free of escape codes.

- file:

  passed to [`cat()`](https://rdrr.io/r/base/cat.html); `""` (the
  default) prints to the console.

## Value

A tibble with one row per sentence, in `sentence_id` order, and columns
`sentence_id`, `indent`, `before`, `marked`, `after`. `before`, `marked`
and `after` join back into the full line; `marked` is `""` when the
sentence has no word to show.

`print_sujimichi()`: the plain lines, as from `format_sujimichi()`,
invisibly.

## Details

    文章とは，単語のつながりである．
                   (つながり)があるおかげで，文章の構造を明示できる．
                                                  (構造)がわかれば，文章を理解しやすくなる．

Only the representative link of each sentence (`is_main`, from
[`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md))
is drawn, since one connection per line keeps the picture readable; a
sentence still shows the rest of its text even when it has no link.
Width is counted with
[`stringi::stri_width()`](https://rdrr.io/pkg/stringi/man/stri_width.html),
so full-width characters take two columns.

The indent of a line is the width of the text before the word in the
*earlier* line, minus one column, added to that earlier line's own
indent – so the mark overlaps the last column of the text it points at,
as in the example above.

A word (a lemma) is looked for as a literal substring of the sentence
text. When it is not found – for example a verb whose lemma differs from
the form actually written – the sentence is shown as plain text, at the
same indent as the sentence it links to.

An analyser splits a compound word that is not in its dictionary: MeCab
with ipadic reads 「畦畔」 as 「畦」 and 「畔」, and marking 「(畦)畔」
reads oddly even though the link itself is sound. Give `words` and the
mark is widened over the nouns next to the shared one, so that the whole
compound is marked. Only the mark changes; the links were worked out in
[`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md)
and are untouched.

## Examples

``` r
sentences <- as_sentences(sample_text())
words <- tibble::tribble(
  ~sentence_id, ~position, ~word,
  1, 1, "文章", 1, 5, "単語", 1, 7, "つながり",
  2, 1, "つながり", 2, 9, "文章", 2, 11, "構造",
  3, 1, "構造", 3, 7, "文章")
links <- connect_sentences(words, sentences)
sujimichi_lines(links, sentences)
#> # A tibble: 3 × 5
#>   sentence_id indent before                             marked     after        
#>         <int>  <dbl> <chr>                              <chr>      <chr>        
#> 1           1      0 "文章とは，単語のつながりである．" ""         ""           
#> 2           2     15 ""                                 "つながり" "があるおかげで，文章の…
#> 3           3     46 ""                                 "構造"     "がわかれば，文章を理解…
```
