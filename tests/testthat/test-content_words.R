# A morpheme table as MeCab would return it through moranajp,
# with the English column names.
#   文章とは，単語のつながりである．
#   それをする．
morphemes_en <- function(){
  tibble::tribble(
    ~sentence_id, ~form,     ~pos,     ~pos_1,   ~lemma,
    1,            "文章",     "名詞",    "一般",    "文章",
    1,            "と",       "助詞",    "格助詞",  "と",
    1,            "は",       "助詞",    "係助詞",  "は",
    1,            "，",       "記号",    "読点",    "，",
    1,            "単語",     "名詞",    "一般",    "単語",
    1,            "の",       "助詞",    "連体化",  "の",
    1,            "つながり", "動詞",    "自立",    "つながる",
    1,            "で",       "助動詞",  "*",      "だ",
    1,            "ある",     "助動詞",  "*",      "ある",
    1,            "．",       "記号",    "句点",    "．",
    2,            "それ",     "名詞",    "代名詞",  "それ",
    2,            "を",       "助詞",    "格助詞",  "を",
    2,            "する",     "動詞",    "自立",    "する",
    2,            "．",       "記号",    "句点",    "．")
}

test_that("only content words are kept", {
  words <- pick_content_words(morphemes_en())
  expect_named(words, c("sentence_id", "position", "word", "pos", "pos_1"))
  expect_equal(words$word, c("文章", "単語", "つながる"))
})

test_that("a morpheme of symbols only is dropped", {
  # MeCab (ipadic) reads a symbol it does not know as 名詞・サ変接続,
  # so the part of speech alone does not keep Markdown notation out.
  morphemes <- tibble::tribble(
    ~sentence_id, ~form, ~pos,     ~pos_1,      ~lemma,
    1,            "**",  "名詞",    "サ変接続",   "*",
    1,            "強調", "名詞",    "サ変接続",   "強調",
    1,            "**",  "名詞",    "サ変接続",   "*",
    1,            "(",   "名詞",    "サ変接続",   "*",
    1,            "/",   "名詞",    "サ変接続",   "*",
    1,            "：",  "名詞",    "サ変接続",   "*",
    1,            "R",   "名詞",    "一般",      "*",
    1,            "4",   "名詞",    "一般",      "*")
  expect_equal(pick_content_words(morphemes)$word, c("強調", "R", "4"))
})

test_that("sentence_chunks() groups by bytes, not by characters", {
  # 日本語は1文字3バイトなので，文字数で数えると MeCab のバッファを超える
  ja <- strrep("あ", 100)          # 300 バイト
  expect_equal(sentence_chunks(rep(ja, 3), max_bytes = 700), c(1, 1, 2))
  expect_equal(sentence_chunks(rep(ja, 3), max_bytes = 10000), c(1, 1, 1))
})

test_that("sentence_chunks() keeps a sentence that is too long on its own", {
  long <- strrep("あ", 1000)
  expect_equal(sentence_chunks(c("短い．", long, "短い．"), max_bytes = 100),
               c(1, 2, 3))
})

test_that("check_sentence_ids() says so when the numbering is short", {
  # moranajp counts its "BP" markers; a swallowed marker merges two
  # sentences and shifts every sentence_id after it
  morphemes <- tibble::tibble(sentence_id = c(1, 1, 2, 2))
  expect_message(check_sentence_ids(morphemes, 3), "may be shifted")
  expect_silent(check_sentence_ids(morphemes, 2))
})

test_that("has_word_char() sees letters and digits of any script", {
  expect_true(all(has_word_char(c("文章", "kanji", "R", "4", "第1章"))))
  expect_false(any(has_word_char(c("**", "(", "/", "：", "…", "", NA))))
})

test_that("a word is represented by its lemma", {
  words <- pick_content_words(morphemes_en())
  # 「つながり」 is stored as 「つながる」
  expect_true("つながる" %in% words$word)
  expect_false("つながり" %in% words$word)
})

test_that("the surface form is used when the lemma is unknown", {
  morphemes <- morphemes_en()
  morphemes$lemma[[1]] <- "*"     # MeCab writes "*" for an unknown lemma
  expect_equal(pick_content_words(morphemes)$word[[1]], "文章")
  morphemes$lemma[[1]] <- NA
  expect_equal(pick_content_words(morphemes)$word[[1]], "文章")
})

test_that("pronouns and other dependent words are dropped", {
  words <- pick_content_words(morphemes_en())
  expect_false("それ" %in% words$word)   # 名詞-代名詞
})

test_that("stop words are dropped", {
  words <- pick_content_words(morphemes_en())
  expect_false("する" %in% words$word)
  # and can be kept by emptying the list
  kept <- pick_content_words(morphemes_en(), stop_words = character(0))
  expect_true("する" %in% kept$word)
})

test_that("position counts over all morphemes of the sentence", {
  words <- pick_content_words(morphemes_en())
  # 文章 is the 1st, 単語 the 5th and つながり the 7th morpheme
  expect_equal(words$position, c(1, 5, 7))
  expect_equal(words$sentence_id, c(1, 1, 1))
})

test_that("Japanese column names of moranajp are understood", {
  morphemes <- morphemes_en()
  colnames(morphemes) <- c("sentence_id", "表層形", "品詞",
                           "品詞細分類1", "原形")
  expect_equal(pick_content_words(morphemes)$word,
               c("文章", "単語", "つながる"))
})

test_that("a table without a lemma column falls back to the surface form", {
  morphemes <- morphemes_en()
  morphemes$lemma <- NULL
  expect_equal(pick_content_words(morphemes)$word,
               c("文章", "単語", "つながり"))
})

test_that("pos and skip_pos_1 can be changed", {
  words <- pick_content_words(morphemes_en(), pos = "名詞")
  expect_equal(words$word, c("文章", "単語"))
  kept <- pick_content_words(morphemes_en(), skip_pos_1 = character(0))
  expect_true("それ" %in% kept$word)
})

test_that("a table without the id column is an error", {
  morphemes <- morphemes_en()
  morphemes$sentence_id <- NULL
  expect_error(pick_content_words(morphemes), "sentence_id")
  expect_error(pick_content_words("not a table"), "data.frame")
})

test_that("analyze_morphemes() fails gently without moranajp", {
  skip_if(requireNamespace("moranajp", quietly = TRUE),
          "moranajp is installed")
  expect_message(out <- analyze_morphemes(sample_text()), "moranajp")
  expect_null(out)
  expect_message(out <- content_words(sample_text()), "moranajp")
  expect_null(out)
})

test_that("analyze_morphemes() checks its input", {
  expect_error(analyze_morphemes(data.frame(text = "a")), "sentence")
})
