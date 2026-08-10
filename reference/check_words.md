# Steps of connect_sentences()

Internal functions for
[`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).

## Usage

``` r
check_words(words)

sentence_ids(words, sentences = NULL)

link_rows(words, para, nearest = TRUE)

keep_first_links(linked, max_links = Inf)

add_lonely_rows(linked, all_ids)

count_referred(linked)
```

## Arguments

- words:

  A data.frame of content words with columns `sentence_id`, `position`
  and `word`, as returned by
  [`pick_content_words()`](https://matutosi.github.io/sujimichi/reference/pick_content_words.md)
  or
  [`content_words()`](https://matutosi.github.io/sujimichi/reference/content_words.md).

- sentences:

  A data.frame of sentences with columns `sentence_id` and
  `paragraph_id`, as returned by
  [`as_sentences()`](https://matutosi.github.io/sujimichi/reference/as_sentences.md).
  It fixes the paragraph a sentence belongs to, and lets a sentence
  without any content word appear in the table.

- para:

  A named vector of paragraph numbers, named by sentence number.

- nearest:

  A logical. `TRUE` (the default) keeps only the nearest earlier
  sentence for each word. `FALSE` keeps every earlier sentence that
  holds the word.

- linked:

  A data.frame of links.

- max_links:

  A number. The largest number of links kept for one sentence, counted
  from the front of the sentence. `Inf` (the default) keeps them all;
  `3` follows the option in `design.md`.

- all_ids:

  A vector of every sentence number.

## Value

A data.frame, or a vector for `count_referred()`.

## Details

- `check_words()` makes sure the table of content words can be used, and
  sorts it by sentence and by place in the sentence.

- `sentence_ids()` settles which sentences to walk through and which
  paragraph each belongs to.

- `link_rows()` builds one row per link.

- `keep_first_links()` keeps at most `max_links` rows per sentence,
  counted from the front of the sentence, and marks the first of them as
  the representative.

- `add_lonely_rows()` adds an empty row for a sentence without a link.

- `count_referred()` counts, for each sentence, the later sentences that
  look back at it.
