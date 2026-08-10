# sujimichi

sujimichi(筋道)は，文章の筋道が通っているかを見る R パッケージです．

各文を，共通の単語をもつ先行文につなげて表示します．
つながりが見えると，文章の論理的な構造がわかります．
どの文ともつながらない文は，プログラミングでのデッドコードと同じものとして報告します．

``` R
文章とは，単語のつながりである．
               (つながり)があるおかげで，文章の構造を明示できる．
                                              (構造)がわかれば，文章を理解しやすくなる．
```

**このパッケージは作りはじめたところで，まだ使える関数はありません．**

## 設計の方針

- 同じ単語かどうかは，形態素解析で内容語の原形にそろえてから比べます．
- 段落内のすべての先行文を対象とし，近い文とのつながりほど良いものとして扱います．
- 形態素解析は [moranajp](https://github.com/matutosi/moranajp) に任せ，
  ローカルで実行します．ネットワークには依存しません．
- 当面は日本語のみを対象とします．

## Installation, インストール

``` r

if(!require("remotes")) install.packages("remotes")
remotes::install_github("matutosi/sujimichi")
```

## Citation, 引用

Toshikazu Matsumura (2026) sujimichi: Visualize the logical structure of
Japanese text. <https://github.com/matutosi/sujimichi> .
