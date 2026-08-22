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

## check の生成物の後始末

- **`R CMD check` などで作られる `*.tar.gz` は，役割が終わったら削除する**．
  結果を確認し終えたら (CRAN へ出す場合は提出が済んだら) 消してよい．
  DESCRIPTION とソースから何度でも作り直せるため，残しておく理由がない．
- 同じ理由で，`*.Rcheck/` (check の作業ディレクトリ) も確認が済んだら消す．
- 補足: `*.tar.gz` を作るのは `R CMD build` / `devtools::build()` で，
  `devtools::check()` は既定で一時ディレクトリに作るためプロジェクト直下には残らない．
  プロジェクト直下に残るのは `R CMD build` を直接実行したときが多い．
  どちらの経路でできたものでも，見つけたら消す．

## 詳しくはこちら (本体には要点だけ置く)

| ファイル | 中身 |
|---|---|
| [.claude/notes/history.md](notes/history.md) | 段階1(手順1〜5)の実装の進捗履歴 |
| [.claude/notes/functions.md](notes/functions.md) | 実装した関数の一覧と使い方 |
| [.claude/notes/design_decisions.md](notes/design_decisions.md) | design.md の未決事項を実装しながら決めた記録 |

## 進捗状況

### 現在の状態

(2026-08-11 更新)

段階1(手順1〜5: 文の分割・内容語の取り出し・つながりの計算・
コンソール表示・デッドコード検出)を最小構成で実装し，`R CMD check` は
0 errors / 0 warnings / 0 notes，テスト131件すべて通過を確認済み．
ggplot2 による図・HTML 表示・pkgdown サイト
(<https://matutosi.github.io/sujimichi/>) も揃った．
実データ(学術論文の総説)にかけて，文分割・文番号ずれ・記号混入などの
不具合を見つけて直し，複合語の割れは表示側だけで吸収する方針にした．
詳しい経緯は [notes/history.md](notes/history.md)，実装した関数は
[notes/functions.md](notes/functions.md)，設計判断は
[notes/design_decisions.md](notes/design_decisions.md) を見る．

### TODO / 今後の候補

- (未着手) 段階3のラベル付けの手段の決定(同上)
- (未着手) **辞書を Sudachi に替えられるようにする**(複合語の割れの根治)．
  `D:\pf\sudachi` に導入済みで，直接動かすと **`畦畔` は1語**，
  `多様性` も B/C モードでは1語になる(MeCab(ipadic)では割れる)．
  ただし**現状 moranajp 経由では動かない**．`make_cmd()` が
  `paste0(bin_dir, "/", cmd)` として `d:/pf/sudachi/java -jar sudachi.jar`
  という存在しないパスを作るため．moranajp 側の修正が要る
  (あわせて出力が CP932 なので `iconv = "CP932_UTF-8"` が要る)．
  なお `半自然草原`・`圃場整備` は Sudachi の C(最長単位)でもまとまらない．
- (未着手) 語の正規化を強めるかの検討．実データで確かめたところ，
  「つながり」(名詞・一般)・「つながる」(動詞・自立)・「つなげる」は
  別の3語になり，design.md の例が期待する統合は起きない．
  上の複合語の件とあわせて方針を決める．
- (未着手) 書籍の原稿や申請書にもかけてみる
  (総説1本では，分野や文体による違いが分からない)．
