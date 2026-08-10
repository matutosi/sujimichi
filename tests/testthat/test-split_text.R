test_that("sentences are split at the three terminators", {
  expect_equal(
    split_sentences("文章とは，単語のつながりである．"),
    "文章とは，単語のつながりである．")
  expect_equal(
    split_sentences("一つ目。二つ目．three."),
    c("一つ目。", "二つ目．", "three."))
})

test_that("the terminator stays with its sentence", {
  sentences <- split_sentences("あるね。ないよ。")
  expect_equal(sentences, c("あるね。", "ないよ。"))
})

test_that("a text without a terminator is one sentence", {
  expect_equal(split_sentences("終わりの印がない"), "終わりの印がない")
})

test_that("an ASCII period between digits is not a terminator", {
  expect_equal(split_sentences("平均は0.5である．"), "平均は0.5である．")
  # 語の中のピリオドは区切りにしない
  expect_equal(split_sentences("ui.R と server.R がある．"),
               "ui.R と server.R がある．")
  expect_equal(split_sentences("経緯は.claude/done.md にある．"),
               "経緯は.claude/done.md にある．")
  expect_equal(split_sentences("幅は stringi::stri_width() で測る．"),
               "幅は stringi::stri_width() で測る．")
  # 文末・空白の前・閉じ括弧の前では区切る
  expect_equal(split_sentences("a test. next one."),
               c("a test.", "next one."))
  expect_equal(split_sentences("(a test.)次．"), c("(a test.)", "次．"))
  expect_equal(
    split_sentences("値は1.5だ．次は2.25だ．"),
    c("値は1.5だ．", "次は2.25だ．"))
})

test_that("a closing bracket stays in the sentence it ends", {
  expect_equal(
    split_sentences("「これは筋道だ。」と書いた。"),
    c("「これは筋道だ。」", "と書いた。"))
  expect_equal(
    split_sentences("彼は(そうだ。)と書いた。"),
    c("彼は(そうだ。)", "と書いた。"))
})

test_that("lines in a paragraph are joined before the split", {
  lines <- c("つながりがあるおかげで，",
             "文章の構造を明示できる．")
  expect_equal(
    split_sentences(lines),
    "つながりがあるおかげで，文章の構造を明示できる．")
})

test_that("a space is kept between two ASCII words", {
  expect_equal(split_sentences(c("use R", "for text.")), "use R for text.")
  # but not around a Japanese character
  expect_equal(split_sentences(c("日本語は", "詰める．")), "日本語は詰める．")
})

test_that("paragraphs are split at a blank line", {
  lines <- c("一段落目．", "", "二段落目．")
  expect_equal(split_paragraphs(lines), c("一段落目．", "二段落目．"))
})

test_that("several blank lines and blank space make one break", {
  lines <- c("一段落目．", "", "  ", "", "二段落目．")
  expect_equal(split_paragraphs(lines), c("一段落目．", "二段落目．"))
})

test_that("CRLF is handled like LF", {
  expect_equal(split_paragraphs("一段落目．\r\n\r\n二段落目．"),
               c("一段落目．", "二段落目．"))
})

test_that("as_sentences() numbers paragraphs and sentences", {
  sentences <- as_sentences(c(sample_text(), "", "別の段落．続き．"))
  expect_s3_class(sentences, "tbl_df")
  expect_named(sentences, c("paragraph_id", "sentence_id", "sentence"))
  expect_equal(nrow(sentences), 5)
  expect_equal(sentences$paragraph_id, c(1, 1, 1, 2, 2))
  # sentence_id runs through the whole text
  expect_equal(sentences$sentence_id, 1:5)
  expect_equal(sentences$sentence[[1]], sample_text()[[1]])
})

test_that("an empty text gives an empty table", {
  sentences <- as_sentences(c("", "   "))
  expect_equal(nrow(sentences), 0)
  expect_named(sentences, c("paragraph_id", "sentence_id", "sentence"))
  expect_type(sentences$sentence, "character")
})

test_that("sep can be narrowed to one terminator", {
  expect_equal(
    split_sentences("一つ目。二つ目．", sep = "。"),
    c("一つ目。", "二つ目．"))
})

test_that("sample_text() has three sentences in one paragraph", {
  sentences <- as_sentences(sample_text())
  expect_equal(nrow(sentences), 3)
  expect_true(all(sentences$paragraph_id == 1))
})
