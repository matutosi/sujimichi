test_that("a heading marker is removed and the text is kept", {
  expect_equal(strip_markdown("# 見出し"), "見出し")
  expect_equal(strip_markdown("### 三段見出し"), "三段見出し")
})

test_that("a list marker is removed and the text is kept", {
  expect_equal(strip_markdown("- 箇条書き"), "箇条書き")
  expect_equal(strip_markdown("* 箇条書き"), "箇条書き")
  expect_equal(strip_markdown("1. 番号付き"), "番号付き")
  expect_equal(strip_markdown("  - 入れ子の箇条書き"), "入れ子の箇条書き")
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

test_that("a plain line without notation is unchanged", {
  expect_equal(strip_markdown("ふつうの文．"), "ふつうの文．")
})

test_that("strip_markdown() output can be handed to as_sentences()", {
  lines <- c("# 見出し", "", "本文だ．", "", "- 箇条書き1．", "- 箇条書き2．")
  sentences <- as_sentences(strip_markdown(lines))
  expect_equal(sentences$sentence, c("見出し", "本文だ．", "箇条書き1．", "箇条書き2．"))
})
