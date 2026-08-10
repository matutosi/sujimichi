# Group sentences into chunks the analyser can swallow

Internal function for
[`analyze_morphemes()`](https://matutosi.github.io/sujimichi/reference/analyze_morphemes.md).
MeCab reads one line at a time into a buffer of a fixed size, in bytes,
and splits the line when it does not fit; the split falls in the middle
of a character and the text after it is unusable. 'moranajp' joins the
sentences into one line and groups them by the number of characters,
which is not the same thing: a Japanese character takes three bytes in
UTF-8, so a group well inside its character limit can still be far over
the buffer.

## Usage

``` r
sentence_chunks(sentences, max_bytes = 8000)
```

## Arguments

- sentences:

  A character vector.

- max_bytes:

  An integer. Largest chunk, counted in bytes.

## Value

An integer vector, the chunk number of each sentence.

## Details

A sentence longer than `max_bytes` on its own is left in a chunk of its
own rather than dropped.
