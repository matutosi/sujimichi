html_pieces <- function(){
  sentences <- as_sentences(sample_text())
  # 2文目は「つながり」で1文目につながり，「文章」も共有している
  words <- data.frame(
    sentence_id = c(1, 1, 1, 2, 2, 2, 3, 3),
    position    = c(1, 5, 7, 1, 9, 11, 1, 7),
    word        = c("文章", "単語", "つながり",
                    "つながり", "文章", "構造",
                    "構造", "文章"))
  list(sentences = sentences, links = connect_sentences(words, sentences))
}

test_that("the lines come back inside a pre block", {
  p    <- html_pieces()
  html <- html_sujimichi(p$links, p$sentences)
  expect_s3_class(html, "sujimichi_html")
  expect_length(html, 1)
  expect_true(grepl("<pre class=\"sujimichi\">", html, fixed = TRUE))
  expect_true(grepl("</pre>", html, fixed = TRUE))
})

test_that("the shared word is put in a span", {
  p    <- html_pieces()
  html <- html_sujimichi(p$links, p$sentences)
  expect_true(grepl("<span class=\"sujimichi-word\">つながり</span>",
                    html, fixed = TRUE))
})

test_that("max_marks puts the other shared words in spans too", {
  p    <- html_pieces()
  one   <- html_sujimichi(p$links, p$sentences)
  three <- html_sujimichi(p$links, p$sentences, max_marks = 3)
  count <- function(x) lengths(gregexpr("sujimichi-word", x, fixed = TRUE))
  expect_true(count(three) > count(one))
})

test_that("an isolated sentence is put in its own span", {
  sentences <- as_sentences(c("あの話をする．", "あの話は続く．", "無関係だ．"))
  words <- data.frame(
    sentence_id = c(1, 2, 3),
    position    = c(1, 1, 1),
    word        = c("話", "話", "無関係"))
  links <- connect_sentences(words, sentences)
  html  <- html_sujimichi(links, sentences)
  expect_true(grepl("<span class=\"sujimichi-dead\">無関係だ．</span>",
                    html, fixed = TRUE))
  # つながっている文は包まない
  expect_false(grepl("sujimichi-dead\">あの話をする", html, fixed = TRUE))
})

test_that("what means something in HTML is escaped", {
  sentences <- as_sentences(c("<span>と&が出る．", "<span>はタグだ．"))
  words <- data.frame(sentence_id = c(1, 2), position = c(1, 1),
                      word = c("span", "span"))
  links <- connect_sentences(words, sentences)
  html  <- html_sujimichi(links, sentences)
  expect_true(grepl("&lt;span&gt;", html, fixed = TRUE))
  expect_true(grepl("&amp;", html, fixed = TRUE))
  # 本文の < がタグとして残っていない
  expect_false(grepl("<span>と", html, fixed = TRUE))
})

test_that("escape_html() takes the ampersand first", {
  expect_equal(escape_html("&lt;"), "&amp;lt;")
  expect_equal(escape_html(c("a<b", "c>d")), c("a&lt;b", "c&gt;d"))
})

test_that("css = FALSE leaves the style block out", {
  p <- html_pieces()
  expect_true(grepl("<style>", html_sujimichi(p$links, p$sentences),
                    fixed = TRUE))
  expect_false(grepl("<style>",
                     html_sujimichi(p$links, p$sentences, css = FALSE),
                     fixed = TRUE))
})

test_that("the indent of the console display is kept", {
  p     <- html_pieces()
  plain <- format_sujimichi(p$links, p$sentences)
  html  <- html_sujimichi(p$links, p$sentences, css = FALSE)
  lines <- strsplit(unclass(html), "\n", fixed = TRUE)[[1]]
  # 2行目の字下げ(先頭の空白の数)がコンソール表示と同じ
  spaces <- function(x) nchar(sub("[^ ].*$", "", x))
  expect_equal(spaces(lines[[3]]), spaces(plain[[2]]))
})

test_that("printing writes the HTML as it is", {
  p <- html_pieces()
  html <- html_sujimichi(p$links, p$sentences)
  expect_output(print(html), "<pre class=\"sujimichi\">", fixed = TRUE)
})

test_that("no control character is left in the output", {
  p    <- html_pieces()
  html <- html_sujimichi(p$links, p$sentences, max_marks = 3)
  expect_false(grepl(intToUtf8(0x0011), html, fixed = TRUE))
  expect_false(grepl(intToUtf8(0x0012), html, fixed = TRUE))
})
