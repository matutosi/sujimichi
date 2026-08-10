# Split a text into paragraphs and sentences

`split_paragraphs()` splits a text at blank lines, `split_sentences()`
splits a paragraph at sentence terminators, and `as_sentences()` does
both and returns a table.

## Usage

``` r
as_sentences(text, sep = sentence_marks())

split_paragraphs(text)

split_sentences(text, sep = sentence_marks())
```

## Arguments

- text:

  A character vector. Elements are treated as lines and are pasted
  together with a line break.

- sep:

  A character vector of sentence terminators. Each element is one
  character and is used as a literal.

## Value

- `split_paragraphs()`: a character vector of paragraphs.

- `split_sentences()`: a character vector of sentences.

- `as_sentences()`: a tibble with columns `paragraph_id`, `sentence_id`
  and `sentence`. `sentence_id` runs through the whole text and does not
  restart in each paragraph.

## Details

Lines inside a paragraph are joined before the split into sentences,
because a Japanese manuscript often breaks a line at a sentence end or
at a phrase boundary. A space is kept only where an ASCII word would
otherwise be glued to the next one.

An ASCII full stop ends a sentence only at the end of a paragraph, or
before a space or a closing bracket. A full stop inside a word is part
of it, so that "0.5", "ui.R" and ".claude/done.md" stay in one piece. A
terminator followed by a closing bracket or quotation mark keeps the
bracket in the same sentence.

## Examples

``` r
as_sentences(sample_text())
#> # A tibble: 3 × 3
#>   paragraph_id sentence_id sentence                                        
#>          <int>       <int> <chr>                                           
#> 1            1           1 文章とは，単語のつながりである．                
#> 2            1           2 つながりがあるおかげで，文章の構造を明示できる．
#> 3            1           3 構造がわかれば，文章を理解しやすくなる．        

# a blank line starts a new paragraph
as_sentences(c(sample_text(), "", sample_text()))
#> # A tibble: 6 × 3
#>   paragraph_id sentence_id sentence                                        
#>          <int>       <int> <chr>                                           
#> 1            1           1 文章とは，単語のつながりである．                
#> 2            1           2 つながりがあるおかげで，文章の構造を明示できる．
#> 3            1           3 構造がわかれば，文章を理解しやすくなる．        
#> 4            2           4 文章とは，単語のつながりである．                
#> 5            2           5 つながりがあるおかげで，文章の構造を明示できる．
#> 6            2           6 構造がわかれば，文章を理解しやすくなる．        
```
