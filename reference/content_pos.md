# Parts of speech of a content word

`content_pos()` lists the parts of speech that carry content: 名詞
(noun), 動詞 (verb), 形容詞 (adjective) and 副詞 (adverb).
`skipped_pos_1()` lists the sub categories that are dropped even though
the part of speech is a content one, such as 非自立 (dependent), 代名詞
(pronoun) and 数 (numeral). `stop_words_ja()` lists the lemmas that
appear everywhere and therefore say nothing about the line of reasoning.

## Usage

``` r
content_pos()

skipped_pos_1()

stop_words_ja()
```

## Value

A character vector.

## Details

These are the defaults of
[`pick_content_words()`](https://matutosi.github.io/sujimichi/reference/pick_content_words.md).
Pass your own vector when a text needs a different setting.

## Examples

``` r
content_pos()
#> [1] "名詞"   "動詞"   "形容詞" "副詞"  
skipped_pos_1()
#> [1] "非自立"     "非自立可能" "代名詞"     "数"         "数詞"      
#> [6] "接尾"       "接尾辞"    
stop_words_ja()
#> [1] "する"   "ある"   "なる"   "いる"   "できる" "こと"   "もの"   "ため"  
#> [9] "よう"  
```
