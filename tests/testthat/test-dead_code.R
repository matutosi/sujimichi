# The three sentences of sample_text(), already analysed, all sharing
# a word with the sentence before or after -- one connected paragraph.
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
    3,            1,         "構造",
    3,            7,         "文章")
}

sample_ids <- function(n = 3){
  data.frame(paragraph_id = rep(1, n), sentence_id = seq_len(n))
}

test_that("a fully connected paragraph is one component, none isolated", {
  links <- connect_sentences(sample_words(), sample_ids())
  dead  <- dead_code(links, sample_ids())
  expect_s3_class(dead, "tbl_df")
  expect_named(dead, c("sentence_id", "paragraph_id", "component", "isolated"))
  expect_equal(dead$sentence_id, c(1, 2, 3))
  expect_equal(length(unique(dead$component)), 1)
  expect_false(any(dead$isolated))
})

test_that("a topic sentence with no backward link is not isolated", {
  # sentence 1 has nothing before it to link back to, but sentences 2
  # and 3 both refer back to it -- it must not count as dead code.
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    2,            1,         "筋道",
    3,            1,         "筋道")
  links <- connect_sentences(words, sample_ids())
  dead  <- dead_code(links, sample_ids())
  expect_false(dead$isolated[dead$sentence_id == 1])
  expect_equal(length(unique(dead$component)), 1)
})

test_that("a sentence sharing no word with its paragraph is isolated", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    3,            1,         "筋道")
  links <- connect_sentences(words, sample_ids())
  dead  <- dead_code(links, sample_ids())
  expect_true(dead$isolated[dead$sentence_id == 2])
  expect_false(dead$isolated[dead$sentence_id == 1])
  expect_false(dead$isolated[dead$sentence_id == 3])
  expect_equal(dead$component[dead$sentence_id == 1],
              dead$component[dead$sentence_id == 3])
  expect_false(dead$component[dead$sentence_id == 2] %in%
              dead$component[dead$sentence_id == 1])
})

test_that("components are numbered from 1 within each paragraph", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    3,            1,         "筋道",
    4,            1,         "文章",
    6,            1,         "文章")
  sentences <- data.frame(paragraph_id = c(1, 1, 1, 2, 2, 2),
                          sentence_id  = c(1, 2, 3, 4, 5, 6))
  links <- connect_sentences(words, sentences)
  dead  <- dead_code(links, sentences)
  expect_equal(dead$component[dead$paragraph_id == 1],
              c(1, 2, 1))
  expect_equal(dead$component[dead$paragraph_id == 2],
              c(1, 2, 1))
})

test_that("broken_paragraphs lists paragraphs with two or more components", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    3,            1,         "筋道",
    4,            1,         "文章",
    5,            1,         "文章",
    6,            1,         "文章")
  sentences <- data.frame(paragraph_id = c(1, 1, 1, 2, 2, 2),
                          sentence_id  = c(1, 2, 3, 4, 5, 6))
  links <- connect_sentences(words, sentences)
  dead  <- dead_code(links, sentences)
  expect_equal(broken_paragraphs(dead), 1)
})

test_that("a fully connected paragraph is not broken", {
  links <- connect_sentences(sample_words(), sample_ids())
  dead  <- dead_code(links, sample_ids())
  expect_equal(broken_paragraphs(dead), numeric(0))
})

test_that("a sentence with no content word still gets a component", {
  words <- tibble::tribble(
    ~sentence_id, ~position, ~word,
    1,            1,         "筋道",
    3,            1,         "筋道")
  links <- connect_sentences(words, sample_ids())
  dead  <- dead_code(links, sample_ids())
  expect_equal(nrow(dead), 3)
  expect_equal(dead$sentence_id, c(1, 2, 3))
})

test_that("dead_code errors on a table without the needed columns", {
  links <- connect_sentences(sample_words(), sample_ids())
  expect_error(dead_code(data.frame(sentence_id = 1), sample_ids()),
              "prev_id")
  expect_error(dead_code("not a table", sample_ids()), "data.frame")
  expect_error(dead_code(links, data.frame(sentence_id = 1)),
              "paragraph_id")
})

test_that("broken_paragraphs errors on a table without the needed columns", {
  expect_error(broken_paragraphs(data.frame(paragraph_id = 1)), "component")
  expect_error(broken_paragraphs("not a table"), "data.frame")
})
