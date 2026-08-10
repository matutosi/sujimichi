# The three sentences of sample_text(), linked as design.md's example:
#   1 文章とは，単語のつながりである．
#   2 つながりがあるおかげで，文章の構造を明示できる．(links to 1 via つながり)
#   3 構造がわかれば，文章を理解しやすくなる．        (links to 2 via 構造)
sample_links <- function(){
  sentences <- as_sentences(sample_text())
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "文章",
    1,            5,         "単語",
    1,            7,         "つながり",
    2,            1,         "つながり",
    2,            9,         "文章",
    2,            11,        "構造",
    3,            1,         "構造",
    3,            7,         "文章")
  connect_sentences(words, sentences)
}

test_that("the mark is widened over a compound split by the analyser", {
  # MeCab(ipadic)は「畦畔」を「畦」と「畔」に割る
  sentences <- as_sentences(c("畦畔は水を保持する．", "畦畔には草原が成立する．"))
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word, ~pos,   ~pos_1,
    1,            1,         "畦",   "名詞", "一般",
    1,            2,         "畔",   "名詞", "一般",
    1,            4,         "水",   "名詞", "一般",
    2,            1,         "畦",   "名詞", "一般",
    2,            2,         "畔",   "名詞", "一般",
    2,            5,         "草原", "名詞", "一般")
  links <- connect_sentences(words, sentences)
  expect_equal(sujimichi_lines(links, sentences)$marked[[2]], "畦")
  expect_equal(sujimichi_lines(links, sentences, words)$marked[[2]], "畦畔")
})

test_that("a word with no noun beside it is left as it is", {
  sentences <- as_sentences(c("草原が成立する．", "草原は重要だ．"))
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,   ~pos,   ~pos_1,
    1,            1,         "草原",   "名詞", "一般",
    2,            1,         "草原",   "名詞", "一般")
  links <- connect_sentences(words, sentences)
  expect_equal(sujimichi_lines(links, sentences, words)$marked[[2]], "草原")
})

test_that("widen_to_compound() gives the word back when it cannot widen", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word, ~pos,   ~pos_1,
    1,            1,         "見る", "動詞", "自立",
    1,            2,         "空",   "名詞", "一般")
  # 動詞なので広げない
  expect_equal(widen_to_compound(words, 1, 1, "見る", "空を見る．"), "見る")
  # その位置の語が表に無ければ元の語に戻す
  expect_equal(widen_to_compound(words, 1, 9, "空", "空を見る．"), "空")
  # 語の表でなければ元の語に戻す
  expect_equal(widen_to_compound(data.frame(a = 1), 1, 1, "空", "空．"), "空")
})

test_that("sujimichi_lines() returns one row per sentence", {
  lines <- sujimichi_lines(sample_links(), as_sentences(sample_text()))
  expect_s3_class(lines, "tbl_df")
  expect_equal(lines$sentence_id, c(1, 2, 3))
  expect_equal(lines$marked, c("", "つながり", "構造"))
})

test_that("the first sentence has no mark and no indent", {
  lines <- sujimichi_lines(sample_links(), as_sentences(sample_text()))
  first <- lines[lines$sentence_id == 1, ]
  expect_equal(first$indent, 0)
  expect_equal(first$marked, "")
  expect_equal(first$before, sample_text()[[1]])
})

test_that("format_sujimichi() matches the design.md example", {
  lines <- format_sujimichi(sample_links(), as_sentences(sample_text()))
  expect_equal(lines[[1]], "文章とは，単語のつながりである．")
  expect_equal(
    lines[[2]],
    paste0(strrep(" ", 15), "(つながり)があるおかげで，文章の構造を明示できる．"))
  expect_equal(
    lines[[3]],
    paste0(strrep(" ", 46), "(構造)がわかれば，文章を理解しやすくなる．"))
})

test_that("a custom wrap mark is used", {
  lines <- format_sujimichi(sample_links(), as_sentences(sample_text()),
                            wrap = c("[", "]"))
  expect_match(lines[[2]], "^\\s*\\[つながり\\]")
})

test_that("a sentence without a link is shown unindented and unmarked", {
  sentences <- as_sentences(c(sample_text(), "", "別の話．"))
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1, 1, "文章", 1, 7, "つながり", 2, 1, "つながり")
  links <- connect_sentences(words, sentences)
  lines <- format_sujimichi(links, sentences)
  expect_equal(lines[[4]], "別の話．")
})

test_that("a lemma that is not a literal substring falls back gracefully", {
  sentences <- data.frame(sentence_id = c(1, 2),
                          sentence = c("それはつながる。", "それも同じだ。"))
  # the surface "つながる" appears in sentence 1, but the "word" here
  # is a lemma that was never written out, so it cannot be found
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1, 1, "つながる", 2, 1, "つながる")
  links <- connect_sentences(words, sentences)
  expect_no_error(lines <- sujimichi_lines(links, sentences))
  second <- lines[lines$sentence_id == 2, ]
  expect_equal(second$marked, "")
  expect_equal(second$before, "それも同じだ。")
})

test_that("print_sujimichi() writes the plain lines without color", {
  expect_output(
    out <- print_sujimichi(sample_links(), as_sentences(sample_text()),
                           color = FALSE),
    "つながり")
  expect_equal(out, format_sujimichi(sample_links(), as_sentences(sample_text())))
})

test_that("print_sujimichi() adds ANSI colour around the mark when asked", {
  expect_output(
    print_sujimichi(sample_links(), as_sentences(sample_text()), color = TRUE),
    "\033\\[36m\\(つながり\\)\033\\[39m")
})

test_that("sujimichi_lines() checks its input", {
  expect_error(sujimichi_lines("not a table", as_sentences(sample_text())),
               "links")
  expect_error(sujimichi_lines(sample_links(), "not a table"), "sentences")
})
