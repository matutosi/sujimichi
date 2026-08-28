# Content words of the opening of 『吾輩は猫である』

The content words of the first 148 sentences of Natsume Soseki's
『吾輩は猫である』, one row per word, ready for
[`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md).
It gives a text long enough to try the package on without a
morphological analyser at hand, which the three sentences of
[`sample_text()`](https://matutosi.github.io/sujimichi/reference/sample_text.md)
are too short for.

## Usage

``` r
neko_words
```

## Format

A tibble with 910 rows and 3 columns.

- `sentence_id`: the number of the sentence, from 1 to 148.

- `position`: the place of the word among the content words of its
  sentence, counted from 1.

- `word`: the word, as a lemma.

## Source

Natsume Soseki 『吾輩は猫である』, through
<https://github.com/matutosi/moranajp>.

## Details

The words were taken with 'chamame' by way of `moranajp::neko_chamame`,
and are lemmas. The raw sentences are not kept, so the table suits
[`connect_sentences()`](https://matutosi.github.io/sujimichi/reference/connect_sentences.md)
and
[`dead_code()`](https://matutosi.github.io/sujimichi/reference/dead_code.md),
not the displays, which need the text to indent. The whole text is
treated as one paragraph, as no paragraph is recorded.

The text is out of copyright. The table was first prepared in the
anabass package, which sujimichi replaced.

## Examples

``` r
links <- connect_sentences(neko_words)
head(links)
#> # A tibble: 6 × 8
#>   sentence_id word  position prev_id distance weight is_main referred
#>         <int> <chr>    <dbl>   <dbl>    <dbl>  <dbl> <lgl>      <int>
#> 1           1 NA          NA      NA       NA     NA TRUE           1
#> 2           2 NA          NA      NA       NA     NA TRUE           1
#> 3           3 NA          NA      NA       NA     NA TRUE           1
#> 4           4 NA          NA      NA       NA     NA TRUE           4
#> 5           5 NA          NA      NA       NA     NA TRUE           2
#> 6           6 いう         4       5        1      1 TRUE           4
sentences <- data.frame(sentence_id = 1:148, paragraph_id = 1L)
head(dead_code(links, sentences))
#> # A tibble: 6 × 4
#>   sentence_id paragraph_id component isolated
#>         <int>        <int>     <int> <lgl>   
#> 1           1            1         1 FALSE   
#> 2           2            1         1 FALSE   
#> 3           3            1         1 FALSE   
#> 4           4            1         1 FALSE   
#> 5           5            1         1 FALSE   
#> 6           6            1         1 FALSE   
```
