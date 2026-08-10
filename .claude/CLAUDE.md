# sujimichi プロジェクト

## 概要

文章の**筋道**が通っているかを見る R パッケージ．
各文を，共通の内容語をもつ先行文につなげて表示し，
どの文ともつながらない文をデッドコードとして検出する．

- リポジトリ: <https://github.com/matutosi/sujimichi> (未作成)
- 形態素解析は [moranajp](https://github.com/matutosi/moranajp) に任せる
  (ローカル実行．ネットワークに依存しない)
- 構想と決定事項: [design.md](design.md)

将来は Python へ移植する(Streamlit)．名前は CRAN・PyPI とも空きを確認済み．

## ディレクトリ構成

```
R/            パッケージのソース
tests/        testthat (edition 3)
DESCRIPTION   メタデータ
NAMESPACE     roxygen2 が生成する(手で編集しない)
.claude/      プロジェクト管理(このファイル・design.md)
```

## 作業上の注意

- **NAMESPACE と man/ は roxygen2 が生成する**．
  `devtools::document()` で更新し，手で編集しない．
- **文字コード**: 日本語を含む R ファイルは **BOM なしの UTF-8** で保存する
  (textmining で BOM により `source()` が失敗した実例がある)．
- **ネットワークに依存しない**．インターネット資源を使う処理を足すときは，
  穏当に失敗させる(`message()` して `NULL` を返す)．
  Examples でネットワークに触れない．
  これを守らなかったために moranajp は CRAN からアーカイブされた．
- **README**: `README.Rmd` を編集し，`devtools::build_readme()` で
  `README.md` を生成する(`README.md` を直接編集しない)．
- **R のバージョン**: 開発は R 4.5.1．`Depends: R (>= 4.2.0)`．

## 進捗状況

### 現在の状態

(2026-08-10 更新)

- `usethis::create_package()` でパッケージの骨組みを作成．
  DESCRIPTION・NAMESPACE・LICENSE(MIT)・`R/`・`tests/testthat/`・
  `sujimichi.Rproj` を用意した．**コードはまだ1行も無い**．
- textmining プロジェクトで練った構想を [design.md](design.md) として移した．
- Imports はまだ空にしてある．
  使う段になって `usethis::use_package()` で足す
  (使っていないパッケージを Imports に書くと `R CMD check` が NOTE を出すため)．

### TODO / 今後の候補

- (未着手) **段階1の最小構成**．次の順で作る．
  1. テキストを段落・文に分ける(`.` `．` `。` で区切る)
  2. moranajp で形態素解析し，内容語を原形で取り出す
  3. 各文から先行文へのつながりを求め，
     `文番号 / 語 / 先行文番号 / 距離 / 代表か / 被参照数` の表を返す
  4. コンソール表示(インデント揃え + 色)
  5. デッドコードの検出(孤立文 + 連結成分)
- (未着手) GitHub リポジトリ `matutosi/sujimichi` を作って push する
- (未着手) 表示方法の決定([design.md](design.md) の「提案(未決)」)
- (未着手) 段階3のラベル付けの手段の決定(同上)
