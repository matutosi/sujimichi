# The three sentences of sample_text(), already analysed.
#   1 文章とは，単語のつながりである．
#   2 つながりがあるおかげで，文章の構造を明示できる．
#   3 構造がわかれば，文章を理解しやすくなる．
sample_words <- function(){
  tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "文章",
    1,            5,         "単語",
    1,            7,         "つながる",
    2,            1,         "つながる",
    2,            9,         "文章",
    2,            11,        "構造",
    2,            13,        "明示",
    3,            1,         "構造",
    3,            7,         "文章",
    3,            9,         "理解")
}

sample_ids <- function(n = 3){
  data.frame(paragraph_id = rep(1, n), sentence_id = seq_len(n))
}

test_that("a sentence is linked to the earlier sentence sharing a word", {
  links <- connect_sentences(sample_words(), sample_ids())
  expect_s3_class(links, "tbl_df")
  expect_named(links, c("sentence_id", "word", "position",
                        "prev_id", "distance", "is_main", "referred"))
  # 構造 and 明示 appear for the first time, so they make no row
  second <- links[links$sentence_id == 2, ]
  expect_equal(second$word, c("つながる", "文章"))
  expect_equal(second$prev_id, c(1, 1))
})

test_that("the word nearest the front of the sentence is the representative", {
  links <- connect_sentences(sample_words(), sample_ids())
  main  <- links[links$is_main, ]
  expect_equal(nrow(main), 3)                    # one per sentence
  expect_equal(main$word, c(NA, "つながる", "構造"))
  expect_equal(main$position, c(NA, 1, 1))
})

test_that("distance is the number of sentences looked back", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    3,            1,         "筋道")
  links <- connect_sentences(words, sample_ids())
  expect_equal(links$distance[links$sentence_id == 3], 2)
})

test_that("only the earlier sentences of the same paragraph are searched", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    2,            1,         "筋道")
  same  <- connect_sentences(words, data.frame(paragraph_id = c(1, 1),
                                               sentence_id  = c(1, 2)))
  other <- connect_sentences(words, data.frame(paragraph_id = c(1, 2),
                                               sentence_id  = c(1, 2)))
  expect_equal(same$prev_id[same$sentence_id == 2], 1)
  expect_true(is.na(other$prev_id[other$sentence_id == 2]))
})

test_that("a sentence sharing no word gets one row of NA", {
  links <- connect_sentences(sample_words(), sample_ids())
  first <- links[links$sentence_id == 1, ]
  expect_equal(nrow(first), 1)
  expect_true(is.na(first$word))
  expect_true(is.na(first$prev_id))
  expect_true(is.na(first$distance))
  expect_true(first$is_main)
})

test_that("a sentence without a content word still appears", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    3,            1,         "筋道")
  links <- connect_sentences(words, sample_ids())
  expect_equal(sort(unique(links$sentence_id)), c(1, 2, 3))
  expect_true(is.na(links$word[links$sentence_id == 2]))
})

test_that("nearest keeps one link, and FALSE keeps every earlier sentence", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    2,            1,         "筋道",
    3,            1,         "筋道")
  near <- connect_sentences(words, sample_ids())
  all  <- connect_sentences(words, sample_ids(), nearest = FALSE)
  expect_equal(near$prev_id[near$sentence_id == 3], 2)
  expect_equal(sort(all$prev_id[all$sentence_id == 3]), c(1, 2))
  # the nearer one is the representative
  expect_equal(all$prev_id[all$sentence_id == 3 & all$is_main], 2)
})

test_that("max_links keeps the links nearest the front of the sentence", {
  links <- connect_sentences(sample_words(), sample_ids(), max_links = 1)
  third <- links[links$sentence_id == 3, ]
  expect_equal(nrow(third), 1)
  expect_equal(third$word, "構造")
  expect_true(third$is_main)
})

test_that("referred counts the later sentences that look back", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    2,            1,         "筋道",
    3,            1,         "筋道")
  links <- connect_sentences(words, sample_ids(), nearest = FALSE)
  referred <- links[!duplicated(links$sentence_id), ]
  expect_equal(referred$referred, c(2, 1, 0))
})

test_that("referred counts a sentence once, not once per shared word", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    1,            3,         "文章",
    2,            1,         "筋道",
    2,            3,         "文章")
  links <- connect_sentences(words, sample_ids(2))
  expect_equal(unique(links$referred[links$sentence_id == 1]), 1)
})

test_that("the whole text is one paragraph when sentences is not given", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    2,            1,         "筋道")
  links <- connect_sentences(words)
  expect_equal(links$prev_id[links$sentence_id == 2], 1)
})

test_that("an empty table of words gives one NA row per sentence", {
  words <- data.frame(sentence_id = numeric(0), position = numeric(0),
                      word = character(0))
  links <- connect_sentences(words, sample_ids())
  expect_equal(nrow(links), 3)
  expect_true(all(is.na(links$prev_id)))
  expect_true(all(links$referred == 0))
})

test_that("a table without the needed columns is an error", {
  expect_error(connect_sentences(data.frame(sentence_id = 1)), "position")
  expect_error(connect_sentences("not a table"), "data.frame")
  expect_error(connect_sentences(sample_words(), data.frame(a = 1)),
               "sentence_id")
})
