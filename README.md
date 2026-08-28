
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sujimichi

sujimichi(筋道)は，文章の筋道が通っているかを見る R パッケージです．

各文を，共通の単語をもつ先行文につなげて表示します．
つながりが見えると，文章の論理的な構造がわかります．
どの文ともつながらない文は，プログラミングでのデッドコードと同じものとして報告します．

    文章とは，単語のつながりである．
                   (つながり)があるおかげで，文章の構造を明示できる．
                                                  (構造)がわかれば，文章を理解しやすくなる．

## 状態, Status

**主な機能はひととおり動きます**
(文の分割・内容語の取り出し・つながりの計算・ コンソール表示・ggplot2
の図・HTML 出力・デッドコード検出)． API はまだ変わることがあります．

## Installation, インストール

``` r
if(!require("remotes")) install.packages("remotes")
remotes::install_github("matutosi/sujimichi")
```

## 使い方, Usage

原稿を渡すと，文に切り，形態素解析にかけ，内容語でつなぎます．
形態素解析には [moranajp](https://github.com/matutosi/moranajp) と MeCab
が要ります．

``` r
library(sujimichi)

text <- readLines("manuscript.md")
text <- drop_citations(strip_markdown(text))  # 引用文献と Markdown の記号を外す

sentences <- as_sentences(text)               # 段落と文に切る
words     <- content_words(text)              # 形態素解析して内容語を取り出す
links     <- connect_sentences(words, sentences)

print_sujimichi(links, sentences)             # コンソールに表示する
plot_sujimichi(links, sentences)              # ggplot2 でアーク図を描く
dead_code(links, sentences)                   # どこともつながらない文を挙げる
```

形態素解析器が無くても，内容語の表を自分で渡せば動きます．
上の例の3文を手で並べると，つながりはこう表示されます．

``` r
library(sujimichi)

sentences <- as_sentences(sample_text())
words <- tibble::tribble(
  ~sentence_id, ~position, ~word,
  1,            1,         "文章",
  1,            7,         "つながり",
  2,            1,         "つながり",
  2,            11,        "構造",
  3,            1,         "構造")

links <- connect_sentences(words, sentences)
print_sujimichi(links, sentences)
#> 文章とは，単語のつながりである．
#>                (つながり)があるおかげで，文章の構造を明示できる．
#>                                               (構造)がわかれば，文章を理解しやすくなる．
```

つながりの表には，どの文がどの文を見ているか，その距離と重み，
その文が後ろの文からいくつ参照されているか (`referred`) が入ります．

``` r
links
#> # A tibble: 3 × 8
#>   sentence_id word     position prev_id distance weight is_main referred
#>         <dbl> <chr>       <dbl>   <dbl>    <dbl>  <dbl> <lgl>      <int>
#> 1           1 <NA>           NA      NA       NA     NA TRUE           1
#> 2           2 つながり        1       1        1      1 TRUE           1
#> 3           3 構造            1       2        1      1 TRUE           0
```

まとまった量で試すには，同梱の `neko_words` (『吾輩は猫である』の冒頭
148 文) が使えます．

``` r
links <- connect_sentences(neko_words)
head(links, 3)
#> # A tibble: 3 × 8
#>   sentence_id word  position prev_id distance weight is_main referred
#>         <int> <chr>    <dbl>   <dbl>    <dbl>  <dbl> <lgl>      <int>
#> 1           1 <NA>        NA      NA       NA     NA TRUE           1
#> 2           2 <NA>        NA      NA       NA     NA TRUE           1
#> 3           3 <NA>        NA      NA       NA     NA TRUE           1

# どこともつながらない文 (デッドコード)
sentences <- data.frame(sentence_id = 1:148, paragraph_id = 1L)
head(dead_code(links, sentences), 3)
#> # A tibble: 3 × 4
#>   sentence_id paragraph_id component isolated
#>         <int>        <int>     <int> <lgl>   
#> 1           1            1         1 FALSE   
#> 2           2            1         1 FALSE   
#> 3           3            1         1 FALSE
```

## 設計の方針

- 同じ単語かどうかは，形態素解析で内容語の原形にそろえてから比べます．
- 段落内のすべての先行文を対象とし，近い文とのつながりほど良いものとして扱います．
- 形態素解析は [moranajp](https://github.com/matutosi/moranajp) に任せ，
  ローカルで実行します．ネットワークには依存しません．
- 当面は日本語のみを対象とします．

## Citation, 引用

Toshikazu Matsumura (2026) sujimichi: Visualize the logical structure of
Japanese text. <https://github.com/matutosi/sujimichi> .
