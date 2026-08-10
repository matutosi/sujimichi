# sujimichi プロジェクト

## 概要

文章の**筋道**が通っているかを見る R パッケージ．
各文を，共通の内容語をもつ先行文につなげて表示し，
どの文ともつながらない文をデッドコードとして検出する．

- リポジトリ: <https://github.com/matutosi/sujimichi> (作成済み．`origin` 登録済み．push 済み)
- 形態素解析は [moranajp](https://github.com/matutosi/moranajp) に任せる
  (ローカル実行．ネットワークに依存しない)
- 構想と決定事項: [design.md](design.md)

将来は Python へ移植する(Streamlit)．名前は CRAN・PyPI とも空きを確認済み．

## 作業上の注意

- **文字コード**: 日本語を含む R ファイルは **BOM なしの UTF-8** で保存する
  (textmining で BOM により `source()` が失敗した実例がある)．
- **ネットワークに依存しない**．インターネット資源を使う処理を足すときは，
  穏当に失敗させる(`message()` して `NULL` を返す)．
  Examples でネットワークに触れない．
  これを守らなかったために moranajp は CRAN からアーカイブされた．
- **R のバージョン**: 開発は R 4.5.1．`Depends: R (>= 4.2.0)`．

## 進捗状況

### 現在の状態

(2026-08-11 更新)

- **箇条書きの各項目を1文として扱うようにした**．
  `strip_markdown()` が箇条書きの項目に文の区切り(`．`)を足す
  (`list_end = ""` で止められる)．design.md では文数 83→98 になり，
  「段階」の3項目が1文に融合していたのが解消した．
- **実データ(このリポジトリの `.claude/design.md`)にかけて，不具合を3つ見つけて直した**
  (design.md の「進める順序」にある「実際の原稿にかけてみるのが先」の実行)．
  1. **記号が内容語として通っていた**．MeCab(ipadic)は未知の半角記号を
     「名詞・サ変接続」と解析するので，品詞だけで絞ると `**` `(` `/` `:`
     `](` が内容語になる．頻度上位20語のうち7語が記号だった．
  2. **文の境界が失われ，`sentence_id` がずれていた**(いちばん重い)．
     moranajp は文どうしを文字列 `BP` で連結し，`表層形 == "BP"` の行を
     `cumsum()` して `text_id` を振る．次の文が英字で始まると MeCab が
     `BPMeCab`・`BPR` のように1語にしてしまい，**そこから後ろの文番号が
     すべて1つずつ手前にずれる**．design.md では5か所で起きていた．
  3. **強調・リンクの記法が本文に残っていた**(TODO の「未確認」を実データで確認)．
- 直した結果，design.md では内容語の延べ数 697→545(異なり 355→329)，
  文数 86→83(記号だけのインラインコードで割れていた分)，
  孤立文 37→35，割れている段落 8→7 になり，
  頻度上位20語から記号が消えて意味のある語だけになった．
- **pkgdown のサイトを GitHub Actions で自動デプロイするようにした**．
  `.github/workflows/pkgdown.yaml` を追加し，`main` への push で
  `gh-pages` に配信される．実行が成功し，
  <https://matutosi.github.io/sujimichi/> が公開されていることを確認した．
- パッケージの骨組み(DESCRIPTION・LICENSE(MIT)・`R/`・`tests/testthat/`・
  `sujimichi.Rproj`)．構想は [design.md](design.md)．
- **段階1の手順1(文の分割)・手順2(内容語の取り出し)・
  手順3(つながりの計算)・手順4(コンソール表示)・
  手順5(デッドコード検出)を実装した**．これで段階1が最小構成で揃った．
- **Markdown をプレーンテキストに変換する `strip_markdown()` を実装した**
  (design.md の「未確認の論点」への対応．下記「実装した関数」参照)．
- **`R CMD check` が手順4・5・`strip_markdown()` を含めて 0 errors /
  0 warnings / 0 notes で通ることを確認した**．
  テストは 131 件がすべて通る(130 PASS・moranajp が入っている環境では
  「無いときの穏当な失敗」テスト1件が意図通り skip になる)．
- Imports は `stats`・`tibble` だけ．moranajp は **Suggests** に置き，
  `requireNamespace()` で確かめてから使う
  (GitHub 配布のパッケージなので Imports にはしない)．
- **MeCab を `D:\pf\MeCab` に導入し，moranajp をローカル clone
  (`d:/Dropbox/todo/moranajp`)から `devtools::install()` した**．
  手順1→2→3を実データで通しで確認済み(下記「決めたこと」参照)．

#### 実装した関数

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
  `check_sentence_ids()` 文番号の数が合わないときに `message()` で知らせる

`R/connect_sentences.R` (手順3)

- `connect_sentences()` 各文を，同じ内容語をもつ先行文につなぐ．
  返す表は `sentence_id / word / position / prev_id / distance /
  is_main / referred`
- (内部) `check_words()` `sentence_ids()` `link_rows()`
  `keep_first_links()` `add_lonely_rows()` `count_referred()`

`R/console_view.R` (手順4)

- `sujimichi_lines()` 文ごとに `indent / before / marked / after` を返す
  (表示用の下ごしらえ．データを返す設計)
- `format_sujimichi()` 上を1行の文字列(字下げ込み)にまとめる
- `print_sujimichi()` 端末に出力する．既定で ANSI 色付け
  (`color = interactive()`)
- (内部) `ansi_cyan()`

`R/dead_code.R` (手順5)

- `dead_code()` 段落を「単語の共有グラフ」とみなし，`sentence_id / paragraph_id /
  component / isolated` を返す(1文1行)．`isolated` はその文が
  段落内のどの文とも(前方・後方どちらにも)つながっていないこと
- `broken_paragraphs()` `dead_code()` の結果から，連結成分が2つ以上ある
  (話が繋がらない箇所で割れている)`paragraph_id` を挙げる
- (内部) `find_components()` 段落ごとの union-find

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
print_sujimichi(links, sentences)
dead      <- dead_code(links, sentences)
broken_paragraphs(dead)
```

#### 決めたこと(実装しながら)

- **moranajp を呼ぶ部分と，形態素表から内容語を選ぶ部分を分けた**．
  `pick_content_words()` は data.frame を受けるだけなので，
  MeCab の無い環境でもテストできる．段階2の Python 移植でも同じ切り方が効く．
- **語の代表は原形(`原形`)**．`*`(解析器が原形を知らない)のときは表層形に落とす．
- **`position` は文中の全形態素での位置**．助詞などを落としたあとも
  「文の中でより前方に現れる語」の順序が保てる(design.md の代表の選び方に使う)．
- **列名は日英どちらでもよい**(`表層形/品詞/品詞細分類1/原形` と
  `form/pos/pos_1/lemma`)．moranajp の `col_lang` がどちらでも動く．
- **`R/` の文字列リテラルは `\u` エスケープにする**(`R CMD check` の
  non-ASCII NOTE 対策)．コメント・roxygen・`tests/` は日本語のままでよい
  (check は「コメントは可」としているため)．
- 数字にはさまれた `.` は文末としない(`0.5` を割らない)．
  文末の直後の閉じ括弧はその文に含める．
- **つながりが1つも無い文も，`NA` の行として表に残す**．
  こうすると全文が表に現れ，手順5のデッドコード検出が
  `is.na(prev_id)` を見るだけで済む．
  ただし**語ごとに先行文が無いだけなら行は作らない**
  (その文に他のつながりがあるなら，初出の語は行にしない)．
- **既定は最も近い先行文だけ**(`nearest = TRUE`)．
  design.md の「段落内のすべての先行文」は `nearest = FALSE` で得られる．
  「近い文とのつながりほど良い」を既定に採った．
- **`referred` はその行の `sentence_id` の被参照数**
  (後続の何文から参照されたか．同じ文からは何語で繋がっても1と数える)．
  段階3のトピックセンテンス推定に使う．
- **`max_links` の既定は `Inf`**．
  design.md の「最大3つまで」は表示側の都合なので，
  コアは全部返して表示関数で絞る(`max_links = 3`)．
- **Windows の MeCab は `mecabrc` の場所を自分では見つけられない**
  (ビルド時のパスを固定で見にいき，環境によっては存在しない)．
  `analyze_morphemes()` が `bin_dir` の隣の `etc/mecabrc` を探し，
  `MECABRC` 環境変数を**バックスラッシュの絶対パス**でセットしてから呼ぶ
  (フォワードスラッシュだと MeCab 側が見つけられなかった)．
  すでに `MECABRC` が設定されているときは触らない．
- **moranajp の実際の出力では「つながり」は名詞・一般として解析され，
  原形も「つながり」のまま**(動詞「つながる」には正規化されない)．
  design.md の例が期待する「つながり／つながる の統合」は
  MeCab(ipadic)の実際の分割とは一致しない場合がある．
  実データでの見え方は，語の正規化を強めるか検討する材料として残す．
- **pkgdown を `usethis::use_pkgdown()` で導入した**．
  `_pkgdown.yml`(`url:` は DESCRIPTION の `URL:` と同じ
  `https://matutosi.github.io/sujimichi/` に合わせた)を追加し，
  `docs/` を `.gitignore`・`.Rbuildignore` の両方に登録済み．
  `pkgdown::build_site()` でローカル生成できることを確認した．
  GitHub Actions での自動デプロイは，リポジトリを作ってから設定する．
- **字下げは `stringi::stri_width()` で全角幅を測る**．ある文の字下げは，
  1つ前につながる文の「語の手前までの幅 - 1」を，その前の文の字下げに
  積み上げて決める(design.md の例の字下げに実測で一致することを確認)．
  「-1」は語の印が前の語の最後の1桁に重なる，design.md の見た目に合わせた分．
- **語(原形)は文の中の文字列として素朴に探す**(`regexpr(word, text,
  fixed = TRUE)`)．動詞の原形が実際の表記と違う等で見つからないときは，
  印を付けず，字下げも1つ前の文と同じ値にする(穏当に諦める)．
  形態素ごとの文字位置は手順2の返り値に無いため，この単純な探索にした．
- **色は既定で `interactive()` のときだけ付ける**．Examples や
  `R CMD check` の実行時に ANSI エスケープが出力に混ざらないようにする．
- **字下げ・印の計算はプレーンな文字列で行い，色付けは最後に重ねる**．
  ANSI エスケープは表示幅を持たないので，色を付けても後続の文の
  字下げがずれない．
- **「孤立文」は `is.na(prev_id)` だけでは決めない**．前の TODO に書いた
  素朴な案(`prev_id` が `NA` なら孤立)だと，段落の1文目
  (design.md の例で言えばトピックセンテンス)は前方につながる先が
  そもそも無いので，後方から何文参照されていても孤立扱いになってしまう．
  そこで `dead_code()` は段落を「語を共有する文どうしの無向グラフ」とみなし，
  **連結成分が自分1文だけ(前方にも後方にもつながりが無い)ときだけ孤立**
  と判定する(design.md の連結成分の案をそのまま孤立文の判定にも使う形)．
  グラフの成分分けは外部パッケージに頼らず，`R/dead_code.R` 内の
  `find_components()`(素朴な union-find)で行う．
- **`broken_paragraphs()` は段落単位**．成分が2つ以上の段落は，
  文どうしはどこかしらつながっていても，段落全体としては話が
  繋がらない箇所で割れている(design.md の「連結成分」の判定)．
- **`strip_markdown()` は design.md の「暫定」方針どおり実装した**．
  記法(見出しの `#`・箇条書きの `-`/`*`/`+`/番号・引用の `>`)だけを
  外し，本文はそのまま解析対象に残す．コードブロック(フェンス)は
  fence 行ごと丸ごと除外する．インラインコードの `` ` `` も外すことにした
  (design.md には明記が無いが，バッククォートが残ると形態素解析を
  邪魔するため，「記法だけ外す」の自然な延長として追加)．
  リンク(`[text](url)`)・強調(`**`/`_`)は最初は対象にしていなかったが，
  実データで困ったので下記のとおり足した．
- **`strip_markdown()` にリンク・画像・強調・記号だけのインラインコードを足した**
  (実データで困ったので TODO の「未確認」を決着させた)．
  リンクは本文であるテキストを残して URL を落とす．画像(`![alt](url)`)と
  オートリンク(`<https://…>`)は本文でないので丸ごと落とす．
  強調は `**`・`*`・`__` を外し，**単独の `_` は触らない**
  (`sentence_id` のような名前を壊すほうが害が大きい)．
  中身に文字も数字も無いインラインコード(`` `.` ``)は**span ごと落とす**．
  バッククォートだけ外すと裸の `．` が残り，文末と読まれて文が割れるため．
- **箇条書きの項目には文の区切りを足す**(`strip_markdown()` の `list_end`，
  既定は `．`)．`split_sentences()` の行つなぎは「日本語の原稿は文の途中で
  改行する」ことに合わせた仕様なので，そこは変えない．
  かわりに，**箇条書きだと分かっている `strip_markdown()` の側で**
  項目を1文に閉じる．すでに区切り(閉じ括弧が続く場合も含む)で
  終わっている項目には足さない．見出しと引用には足さない
  (見出しの扱いは別の論点として TODO に残す)．
- **`R/markdown.R` の閉じ括弧の集合は `intToUtf8()` で書く**．
  `move_mark_after_close()` と同じ文字だが，`\u` エスケープの
  文字列リテラルを足すよりコードポイントを並べるほうが読み間違えにくい．
- **記号だけの形態素は品詞によらず落とす**(`has_word_char()`)．
  MeCab(ipadic)は未知の半角記号を「名詞・サ変接続」と解析するので，
  品詞での絞り込みだけでは design.md の決定事項「助詞・記号は無視する」を
  満たせない．判定は Unicode の文字種(`\p{L}` `\p{N}`)で行うので，
  漢字・かな・ラテン文字・数字のどれかがあれば残る．
- **moranajp に渡す文は前後に半角空白を付ける**．moranajp は文どうしを
  文字列 `BP` で連結し，`表層形 == "BP"` の行を数えて文番号を振るので，
  英字で始まる(終わる)文があると MeCab が `BP` を巻き込んで1語にし，
  **それ以降の文番号がすべてずれる**．空白を挟めば `BP` は単独の形態素になる．
  あわせて `check_sentence_ids()` で文の数が合うかを確かめ，
  合わなければ `message()` で知らせる(黙ってずれた表を返さない)．

### TODO / 今後の候補

- (未着手) 表示方法の決定([design.md](design.md) の「提案(未決)」)
- (未着手) 段階3のラベル付けの手段の決定(同上)
- (未着手) 語の正規化を強めるかの検討．実データで確かめたところ，
  「つながり」(名詞・一般)・「つながる」(動詞・自立)・「つなげる」は
  別の3語になり，design.md の例が期待する統合は起きない．
  手順3のつながりの拾い方に効くので，段階2に進む前に方針を決める．
- (未着手) 見出しをどう扱うか．見出しは前後の文と語を共有しにくいので，
  孤立文(デッドコード)として大量に挙がる(design.md では98文中45文が孤立文で，
  その多くが見出し)．解析から外すか，段落の題として別に扱うか決める．
- (未着手) 「近さの重み」と「最大3つ」の調整．
  design.md が「実データを見てから決める」としていた項目で，
  データが揃ったので決められる．
