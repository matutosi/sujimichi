# 実装した関数

`R/split_text.R` (手順1)

- `sentence_marks()` 文の区切り(`。` `．` `.`)
- `sample_text()` README と同じ3文のサンプル
- `split_paragraphs()` 空行で段落に分ける
- `split_sentences()` 段落を文に分ける
- `as_sentences()` 両方を行い `paragraph_id / sentence_id / sentence` を返す
- (内部) `join_lines()` `move_mark_after_close()`

`R/content_words.R` (手順2)

- `content_pos()` `skipped_pos_1()` `stop_words_ja()` 既定の絞り込み条件
- `pick_content_words()` **形態素表から内容語を選ぶ**(解析器に依存しない)
- `analyze_morphemes()` moranajp を呼ぶ(無ければ `message()` して `NULL`)
- `content_words()` 手順1から手順2までをまとめた入口
- (内部) `morpheme_col()` 日英どちらの列名でも読む．
  `find_mecabrc()` MeCab の `mecabrc` を `bin_dir` の隣から探す．
  `has_word_char()` 表層に文字か数字があるか(記号だけの形態素を落とす)．
  `check_sentence_ids()` 文番号の数が合わないときに `message()` で知らせる．
  `sentence_chunks()` 解析器のバッファに収まるバイト数で文をまとめる．
  `analyze_chunk()` 1かたまりを解析器に渡す

`R/connect_sentences.R` (手順3)

- `connect_sentences()` 各文を，同じ内容語をもつ先行文につなぐ．
  返す表は `sentence_id / word / position / prev_id / distance /
  weight / is_main / referred`．`weight` は距離の重み
  (既定は逆数．`weight = "distance"` で距離そのもの)
- (内部) `check_words()` `sentence_ids()` `link_rows()`
  `keep_first_links()` `add_lonely_rows()` `link_weight()`
  `count_referred()`

`R/console_view.R` (手順4)

- `sujimichi_lines()` 文ごとに `indent / before / marked / after` を返す
  (表示用の下ごしらえ．データを返す設計)．`words` を渡すと，
  印を隣接する名詞まで広げる(`(畦)畔` → `(畦畔)`)
- `format_sujimichi()` 上を1行の文字列(字下げ込み)にまとめる
- `print_sujimichi()` 端末に出力する．既定で ANSI 色付け
  (`color = interactive()`)
- (内部) `ansi_cyan()`．`widen_to_compound()` 印を隣接する名詞まで広げる
  (解析器が割った複合語をつなぎ直す．本文に無い並びになったら元の語に戻す)．
  `mark_more()` 代表以外の共有語にも印を付ける(`max_marks`)．
  `overlaps()` 片方が他方を含むか

`R/html.R` (手順4の HTML)

- `html_sujimichi()` `<pre>` の中に `<span>` で色を付けた HTML を返す．
  共有語は `.sujimichi-word`，孤立文は `.sujimichi-dead`．
  `css = TRUE`(既定)で `<style>` も付ける
- `print.sujimichi_html()` そのまま出力する
  (R Markdown の `results = "asis"` 用)
- (内部) `sujimichi_css()` `escape_html()`

`R/plot.R` (手順4の図)

- `sujimichi_arcs()` 弧の座標をデータで返す(`link_id / sentence_id /
  prev_id / word / distance / weight / x / y`)．ggplot2 が無くても動く
- `plot_sujimichi()` 文を行に並べ，つながりを弧で描く ggplot を返す．
  孤立文は赤．`paragraph` で段落を選び，`max_links` で1文あたりの弧を絞る
- (内部) `sentence_rows()` 文ごとの点とラベル．
  `check_links()` `in_paragraph()`

`R/dead_code.R` (手順5)

- `dead_code()` 段落を「単語の共有グラフ」とみなし，`sentence_id / paragraph_id /
  component / isolated` を返す(1文1行)．`isolated` はその文が
  段落内のどの文とも(前方・後方どちらにも)つながっていないこと
- `broken_paragraphs()` `dead_code()` の結果から，連結成分が2つ以上ある
  (話が繋がらない箇所で割れている)`paragraph_id` を挙げる
- (内部) `find_components()` 段落ごとの union-find

`R/citations.R`

- `drop_citations()` 文献引用を落とす(`as_sentences()` の前段で使う)．
  **4桁の西暦(1800-2099)を含む丸括弧**を引用とみなす．全角・半角の
  どちらの括弧にも効く．西暦の無い括弧(「(以下，畦畔草原という)」)と，
  括弧の外の西暦(「2011年の調査では」)は残す

`R/markdown.R`

- `strip_markdown()` Markdown をプレーンテキストに変換する
  (`as_sentences()` の前段で使う想定)．見出し・箇条書き・引用の
  記法は外して本文を残し，コードブロックは丸ごと除外する
- (内部) `drop_code_blocks()` フェンス(` ``` `／`~~~`)で囲まれた
  行を丸ごと落とす．`strip_markdown_line()` 1行分の記法を外す
  (引用・見出し・箇条書きの行頭記号，インラインコードの `` ` ``)

使い方は次のとおり(段落の情報が要るので `sentences` を渡す)．

```r
sentences <- as_sentences(text)
words     <- content_words(sentences, bin_dir = "d:/pf/mecab/bin")
links     <- connect_sentences(words, sentences)
print_sujimichi(links, sentences, words, max_marks = 3)
#   words   を渡すと印が複合語に広がる
#   max_marks で1行に付ける印の数(既定1)
dead      <- dead_code(links, sentences)
broken_paragraphs(dead)
```
