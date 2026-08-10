# Warn when the sentence numbers do not match the sentences

Internal function for
[`analyze_morphemes()`](https://matutosi.github.io/sujimichi/reference/analyze_morphemes.md).
'moranajp' numbers the sentences by counting its `"BP"` markers, and the
count is short when a marker was swallowed by the word next to it.
Everything after such a place would be linked to the wrong sentence, so
it is better to say so than to return a table that looks fine.

## Usage

``` r
check_sentence_ids(morphemes, n)
```

## Arguments

- morphemes:

  A data.frame with a `sentence_id` column.

- n:

  An integer. The number of sentences that were sent.

## Value

`morphemes`, invisibly.
