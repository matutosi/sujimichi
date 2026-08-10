test_that("a heading marker is removed and the text is kept", {
  expect_equal(strip_markdown("# 見出し", end_mark = ""), "見出し")
  expect_equal(strip_markdown("### 三段見出し", end_mark = ""), "三段見出し")
})

test_that("a list marker is removed and the text is kept", {
  expect_equal(strip_markdown("- 箇条書き", end_mark = ""), "箇条書き")
  expect_equal(strip_markdown("* 箇条書き", end_mark = ""), "箇条書き")
  expect_equal(strip_markdown("1. 番号付き", end_mark = ""), "番号付き")
  expect_equal(strip_markdown("  - 入れ子の箇条書き", end_mark = ""),
               "入れ子の箇条書き")
})

test_that("a heading joins the paragraph below it", {
  lines <- c("# 目的", "", "この節では目的を述べる．")
  expect_equal(strip_markdown(lines),
               c("目的．", "この節では目的を述べる．"))
  sentences <- as_sentences(strip_markdown(lines))
  expect_equal(sentences$paragraph_id, c(1, 1))
  expect_equal(sentences$sentence, c("目的．", "この節では目的を述べる．"))
})

test_that("heading = 'keep' leaves the heading as its own paragraph", {
  lines <- c("# 目的", "", "この節では目的を述べる．")
  sentences <- as_sentences(strip_markdown(lines, heading = "keep"))
  expect_equal(sentences$paragraph_id, c(1, 2))
  expect_equal(sentences$sentence, c("目的", "この節では目的を述べる．"))
})

test_that("heading = 'drop' takes the headings out", {
  lines <- c("# 目的", "", "この節では目的を述べる．")
  expect_equal(strip_markdown(lines, heading = "drop"),
               c("", "この節では目的を述べる．"))
})

test_that("a list item is closed so that it stands as one sentence", {
  # 句点で終わらない行は次の行につながれるので，項目が1文に融合してしまう
  expect_equal(strip_markdown(c("- 項目1", "- 項目2")),
               c("項目1．", "項目2．"))
  expect_equal(strip_markdown("1. 番号付き"), "番号付き．")
  expect_equal(strip_markdown("  - 入れ子"), "入れ子．")
})

test_that("a list item that runs over lines is closed only at its end", {
  lines <- c("1. 最初に作る．自分の文章から段落を選び，",
             "   ラベルを手で付ける",
             "2. 次にする")
  expect_equal(strip_markdown(lines),
               c("最初に作る．自分の文章から段落を選び，",
                 "ラベルを手で付ける．",
                 "次にする．"))
})

test_that("a list item that already ends with a terminator is left alone", {
  expect_equal(strip_markdown("- 項目だ．"), "項目だ．")
  expect_equal(strip_markdown("- 項目だ。"), "項目だ。")
  expect_equal(strip_markdown("- 項目だ(補足．)"), "項目だ(補足．)")
})

test_that("a plain line and a blockquote are not closed", {
  expect_equal(strip_markdown("本文だ"), "本文だ")
  expect_equal(strip_markdown("> 引用文"), "引用文")
})

test_that("the items of a list become separate sentences", {
  lines <- c("段階は次のとおり．", "", "1. 完成させる", "2. 移植する",
             "3. 判定する")
  sentences <- as_sentences(strip_markdown(lines))
  expect_equal(sentences$sentence,
               c("段階は次のとおり．", "完成させる．", "移植する．", "判定する．"))
})

test_that("a blockquote marker is removed and the text is kept", {
  expect_equal(strip_markdown("> 引用文"), "引用文")
  expect_equal(strip_markdown("> > 二重引用"), "二重引用")
})

test_that("a fenced code block is removed entirely", {
  lines <- c("本文1．", "```r", "1 + 1", "```", "本文2．")
  expect_equal(strip_markdown(lines), c("本文1．", "本文2．"))
})

test_that("an unclosed fenced code block drops everything after the fence", {
  lines <- c("本文1．", "```r", "1 + 1")
  expect_equal(strip_markdown(lines), "本文1．")
})

test_that("an inline code span keeps its content and loses the backticks", {
  expect_equal(strip_markdown("`sujimichi` パッケージ．"), "sujimichi パッケージ．")
})

test_that("an inline code span of marks only is dropped with its content", {
  # 記法だけ外すと，裸になった「．」が文末と読まれてしまう
  # 区切りの空白は残るが，文末と読まれる裸の「．」は消える
  expect_equal(strip_markdown("区切りは(`.` `．` `。`)．"), "区切りは(  )．")
  expect_equal(strip_markdown("`+` は足し算．"), " は足し算．")
})

test_that("what lies between two code spans is kept", {
  # 1つの正規表現だと，前の span の閉じから次の span の開きまでを
  # 拾ってしまい，間の「，」ごと消える
  expect_equal(strip_markdown("`shiritori`，`renbun`．"), "shiritori，renbun．")
  expect_equal(strip_markdown("`ui.R`/`server.R` は別だ．"),
               "ui.R/server.R は別だ．")
  # 記号だけの span は消え，その周りの空白は残る
  expect_equal(strip_markdown("`+` と `-` と `a`．"), " と  と a．")
})

test_that("emphasis marks are removed and the text is kept", {
  expect_equal(strip_markdown("**強調**した．"), "強調した．")
  expect_equal(strip_markdown("*強調*した．"), "強調した．")
  expect_equal(strip_markdown("__強調__した．"), "強調した．")
  expect_equal(strip_markdown("**前**と**後**．"), "前と後．")
})

test_that("a lone underscore is left alone", {
  expect_equal(strip_markdown("列は sentence_id だ．"), "列は sentence_id だ．")
})

test_that("a link keeps its text and loses the address", {
  expect_equal(strip_markdown("[表示](https://example.com)する．"), "表示する．")
  expect_equal(strip_markdown("[表示][ref]する．"), "表示する．")
})

test_that("an image and an autolink are removed entirely", {
  expect_equal(strip_markdown("![図1](img/a.png)本文．"), "本文．")
  expect_equal(strip_markdown("場所は<https://example.com>だ．"), "場所はだ．")
})

test_that("a plain line without notation is unchanged", {
  expect_equal(strip_markdown("ふつうの文．"), "ふつうの文．")
})

test_that("strip_markdown() output can be handed to as_sentences()", {
  lines <- c("# 見出し", "", "本文だ．", "", "- 箇条書き1．", "- 箇条書き2．")
  sentences <- as_sentences(strip_markdown(lines))
  expect_equal(sentences$sentence,
               c("見出し．", "本文だ．", "箇条書き1．", "箇条書き2．"))
})
