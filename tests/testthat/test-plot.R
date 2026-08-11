# 3文が「つながる」「構造」で鎖のようにつながる例
sample_pieces <- function(){
  sentences <- as_sentences(sample_text())
  words <- data.frame(
    sentence_id = c(1, 1, 2, 2, 3),
    position    = c(1, 5, 1, 7, 1),
    word        = c("文章", "つながり", "つながり", "構造", "構造"))
  list(sentences = sentences, links = connect_sentences(words, sentences))
}

test_that("one arc is returned per link", {
  p    <- sample_pieces()
  arcs <- sujimichi_arcs(p$links, p$sentences, n = 8)
  expect_named(arcs, c("link_id", "sentence_id", "prev_id", "word",
                       "distance", "weight", "x", "y"))
  expect_equal(length(unique(arcs$link_id)), sum(!is.na(p$links$prev_id)))
  expect_equal(nrow(arcs), length(unique(arcs$link_id)) * 8)
})

test_that("an arc starts at prev_id and ends at sentence_id", {
  p    <- sample_pieces()
  arcs <- sujimichi_arcs(p$links, p$sentences, n = 8)
  one  <- arcs[arcs$link_id == 1, ]
  expect_equal(one$y[[1]], one$prev_id[[1]])
  expect_equal(one$y[[nrow(one)]], one$sentence_id[[1]])
  # 両端は軸の上にあり，まん中がいちばん膨らむ
  expect_equal(one$x[[1]], 0)
  expect_equal(one$x[[nrow(one)]], 0)
  expect_true(max(one$x) > 0)
})

test_that("a link reaching further back bulges further out", {
  sentences <- data.frame(paragraph_id = rep(1, 4), sentence_id = 1:4)
  words <- data.frame(
    sentence_id = c(1, 2, 4),
    position    = c(1, 1, 1),
    word        = c("語", "語", "語"))
  links <- connect_sentences(words, sentences, nearest = FALSE)
  arcs  <- sujimichi_arcs(links, sentences, n = 8)
  near  <- arcs[arcs$distance == 1, ]
  far   <- arcs[arcs$distance == 2, ]
  expect_true(max(far$x) > max(near$x))
})

test_that("max_links cuts the arcs from the front of the sentence", {
  sentences <- data.frame(paragraph_id = rep(1, 2), sentence_id = 1:2)
  words <- data.frame(
    sentence_id = c(1, 1, 1, 2, 2, 2),
    position    = c(1, 2, 3, 1, 2, 3),
    word        = c("あ", "い", "う", "あ", "い", "う"))
  links <- connect_sentences(words, sentences)
  expect_equal(length(unique(sujimichi_arcs(links, sentences)$word)), 3)
  arcs <- sujimichi_arcs(links, sentences, max_links = 2)
  expect_equal(sort(unique(arcs$word)), c("あ", "い"))
})

test_that("a paragraph can be picked out", {
  sentences <- data.frame(paragraph_id = c(1, 1, 2, 2),
                          sentence_id  = 1:4)
  words <- data.frame(
    sentence_id = c(1, 2, 3, 4),
    position    = rep(1, 4),
    word        = c("あ", "あ", "い", "い"))
  links <- connect_sentences(words, sentences)
  all_  <- sujimichi_arcs(links, sentences)
  one   <- sujimichi_arcs(links, sentences, paragraph = 2)
  expect_equal(length(unique(all_$link_id)), 2)
  expect_equal(unique(one$sentence_id), 4)
})

test_that("a text without a link gives no arc", {
  sentences <- data.frame(paragraph_id = c(1, 1), sentence_id = 1:2)
  words <- data.frame(sentence_id = c(1, 2), position = c(1, 1),
                      word = c("あ", "い"))
  links <- connect_sentences(words, sentences)
  arcs  <- sujimichi_arcs(links, sentences)
  expect_equal(nrow(arcs), 0)
  expect_named(arcs, c("link_id", "sentence_id", "prev_id", "word",
                       "distance", "weight", "x", "y"))
})

test_that("a table that is not a link table is refused", {
  expect_error(sujimichi_arcs(data.frame(a = 1)), "connect_sentences")
})

test_that("sentence_rows() marks the isolated sentences", {
  sentences <- as_sentences(c("あの話をする．", "あの話は続く．", "無関係だ．"))
  words <- data.frame(
    sentence_id = c(1, 2, 3),
    position    = c(1, 1, 1),
    word        = c("話", "話", "無関係"))
  links <- connect_sentences(words, sentences)
  rows  <- sentence_rows(links, sentences)
  expect_equal(rows$isolated, c(FALSE, FALSE, TRUE))
  expect_equal(rows$y, rows$sentence_id)
})

test_that("a long sentence is cut down to a label", {
  sentences <- as_sentences(c("あ", strrep("い", 50), "．"))
  words <- data.frame(sentence_id = 1, position = 1, word = "あ")
  links <- connect_sentences(words, sentences)
  rows  <- sentence_rows(links, sentences, chars = 10)
  expect_true(all(nchar(rows$label) <= 11))
})

test_that("plot_sujimichi() gives a ggplot when 'ggplot2' is there", {
  skip_if_not_installed("ggplot2")
  p <- sample_pieces()
  expect_s3_class(plot_sujimichi(p$links, p$sentences), "ggplot")
  expect_s3_class(plot_sujimichi(p$links, p$sentences, label = FALSE),
                  "ggplot")
})
