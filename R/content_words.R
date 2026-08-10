#' Parts of speech of a content word
#'
#' `content_pos()` lists the parts of speech that carry content:
#' 名詞 (noun), 動詞 (verb), 形容詞 (adjective) and 副詞 (adverb).
#' `skipped_pos_1()` lists the sub categories that are dropped even
#' though the part of speech is a content one, such as 非自立
#' (dependent), 代名詞 (pronoun) and 数 (numeral).
#' `stop_words_ja()` lists the lemmas that appear everywhere and
#' therefore say nothing about the line of reasoning.
#'
#' These are the defaults of [pick_content_words()].
#' Pass your own vector when a text needs a different setting.
#'
#' @return A character vector.
#' @examples
#' content_pos()
#' skipped_pos_1()
#' stop_words_ja()
#'
#' @export
content_pos <- function(){
  # 名詞 動詞 形容詞 副詞
  c("\u540d\u8a5e", "\u52d5\u8a5e", "\u5f62\u5bb9\u8a5e", "\u526f\u8a5e")
}

#' @rdname content_pos
#' @export
skipped_pos_1 <- function(){
  # 非自立 非自立可能 代名詞 数 数詞 接尾 接尾辞
  c("\u975e\u81ea\u7acb", "\u975e\u81ea\u7acb\u53ef\u80fd",
    "\u4ee3\u540d\u8a5e", "\u6570", "\u6570\u8a5e",
    "\u63a5\u5c3e", "\u63a5\u5c3e\u8f9e")
}

#' @rdname content_pos
#' @export
stop_words_ja <- function(){
  # する ある なる いる できる こと もの ため よう
  c("\u3059\u308b", "\u3042\u308b", "\u306a\u308b", "\u3044\u308b",
    "\u3067\u304d\u308b", "\u3053\u3068", "\u3082\u306e",
    "\u305f\u3081", "\u3088\u3046")
}

#' Pick the content words out of a morpheme table
#'
#' Keeps the morphemes whose part of speech is in `pos`, and returns one
#' row per kept morpheme.  A word is represented by its lemma (原形), so
#' that 「つながり」 and 「つながる」 count as the same word.  The surface
#' form (表層形) is used instead when the analyser does not know the
#' lemma and writes `"*"`.
#'
#' A morpheme made only of punctuation and symbols is dropped, whatever
#' its part of speech.  MeCab with ipadic reads a symbol it does not know
#' (`**`, `(`, `/`, `:` and the like) as 名詞・サ変接続, so filtering by
#' part of speech alone lets Markdown notation through as if it were a
#' content word.
#'
#' The table may use either the Japanese column names of 'moranajp'
#' (表層形, 品詞, 品詞細分類1, 原形) or the English ones
#' (`form`, `pos`, `pos_1`, `lemma`); see [moranajp::moranajp_all()].
#'
#' @param morphemes A data.frame of morphemes, as returned by
#'   [analyze_morphemes()].
#' @param pos A character vector of parts of speech to keep.
#' @param skip_pos_1 A character vector of sub categories to drop.
#' @param stop_words A character vector of words to drop.
#' @param id_col A string.  The column that holds the sentence number.
#' @return A tibble with one row per content word and columns
#'   `sentence_id`, `position`, `word`, `pos` and `pos_1`.
#'   `position` is the place of the morpheme in its sentence, counted
#'   over all morphemes, so that an earlier word keeps a smaller number
#'   after the other morphemes are dropped.
#' @examples
#' # a morpheme table as an analyser would return it
#' morphemes <- data.frame(
#'   sentence_id = c(1, 1, 1, 1, 1),
#'   form   = c("文章", "と", "は", "つながり", "だ"),
#'   pos    = c("名詞", "助詞", "助詞", "動詞", "助動詞"),
#'   pos_1  = c("一般", "格助詞", "係助詞", "自立", ""),
#'   lemma  = c("文章", "と", "は", "つながる", "だ"))
#' pick_content_words(morphemes)
#'
#' @export
pick_content_words <- function(morphemes,
                               pos        = content_pos(),
                               skip_pos_1 = skipped_pos_1(),
                               stop_words = stop_words_ja(),
                               id_col     = "sentence_id"){
  if(!is.data.frame(morphemes)){
    stop("`morphemes` must be a data.frame.", call. = FALSE)
  }
  if(!id_col %in% colnames(morphemes)){
    stop("`morphemes` has no column `", id_col, "`.", call. = FALSE)
  }
  form  <- morpheme_col(morphemes, "form")
  word_pos <- morpheme_col(morphemes, "pos")
  if(is.null(form) || is.null(word_pos)){
    stop("`morphemes` needs a surface form and a part of speech column.",
         call. = FALSE)
  }
  lemma <- morpheme_col(morphemes, "lemma")
  pos_1 <- morpheme_col(morphemes, "pos_1")
  if(is.null(lemma)) lemma <- form
  if(is.null(pos_1)) pos_1 <- rep("", length(form))
  # "*" is what MeCab writes when it does not know the lemma
  unknown <- is.na(lemma) | lemma %in% c("", "*")
  word    <- ifelse(unknown, form, lemma)
  id      <- morphemes[[id_col]]
  out     <- tibble::tibble(
    sentence_id = id,
    position    = stats::ave(seq_along(id), id, FUN = seq_along),
    word        = as.character(word),
    pos         = as.character(word_pos),
    pos_1       = as.character(pos_1))
  keep <- out[["pos"]] %in% pos &
          !out[["pos_1"]] %in% skip_pos_1 &
          !out[["word"]] %in% stop_words &
          nzchar(out[["word"]]) &
          has_word_char(out[["word"]])
  out[keep, , drop = FALSE]
}

#' Tell whether a word holds a letter or a digit
#'
#' Internal function for [pick_content_words()].
#' A morpheme made only of punctuation and symbols carries no content,
#' and is dropped even when the analyser labelled it a noun.
#'
#' @param word A character vector.
#' @return A logical vector.
#' @keywords internal
has_word_char <- function(word){
  word <- as.character(word)
  # \p{L} letters (kanji, kana and latin alike), \p{N} digits
  out  <- grepl("[\\p{L}\\p{N}]", word, perl = TRUE)
  out[is.na(word)] <- FALSE
  out
}

#' Run a morphological analysis on sentences
#'
#' Hands the sentences to [moranajp::moranajp_all()] and renames the
#' `text_id` column to `sentence_id`.  'moranajp' runs 'MeCab',
#' 'Sudachi' or 'Ginza' on the local machine; nothing is sent over the
#' network.
#'
#' When 'moranajp' is not installed, or when the analyser cannot be run,
#' a message is shown and `NULL` is returned, so that a script does not
#' stop on a machine without an analyser.
#'
#' 'moranajp' joins the sentences with the marker `"BP"` and finds them
#' again by looking for a morpheme whose surface form is exactly `"BP"`.
#' When a sentence begins or ends with a latin word, MeCab reads the
#' marker and that word as one unknown noun (`"BPMeCab"`), the boundary
#' is lost, and every sentence after it is numbered one too low.  Each
#' sentence is therefore padded with a space, which keeps the marker a
#' morpheme of its own.  The numbering is checked afterwards, and a
#' message is shown when it still does not match.
#'
#' The sentences are handed over in chunks of at most `max_bytes` bytes,
#' because MeCab reads a line into a buffer of a fixed size and splits
#' the line when it does not fit, in the middle of a character.  See
#' [sentence_chunks()].
#'
#' MeCab on Windows reads its settings from the path it was built with,
#' and stops when the file is not there.  `analyze_morphemes()` therefore
#' looks for `mecabrc` next to `bin_dir` and points the `MECABRC`
#' environment variable at it while the analysis runs.  An `MECABRC` that
#' is already set is left alone.
#'
#' @param sentences A character vector of sentences, or a data.frame
#'   with a `sentence` column as returned by [as_sentences()].
#' @param method A string.  Passed to [moranajp::moranajp_all()]:
#'   "mecab", "ginza", "sudachi_a", "sudachi_b" or "sudachi_c".
#' @param bin_dir A string.  Directory of the analyser.
#' @param iconv A string.  Encoding conversion of the analyser output,
#'   for example "CP932_UTF-8" when MeCab was built for Shift-JIS.
#'   Leave it empty for a UTF-8 dictionary.
#' @param mecabrc A string.  Path of the `mecabrc` settings file.
#'   `NULL` (the default) looks for it next to `bin_dir`.
#'   `""` leaves the setting alone.
#' @param max_bytes An integer.  Largest number of bytes handed to the
#'   analyser at once.  Lower it when the analyser reports an overflow.
#' @param ... Passed to [moranajp::moranajp_all()].
#' @return A tibble of morphemes with a `sentence_id` column,
#'   or `NULL` when the analysis could not be run.
#' @examples
#' \dontrun{
#'   # needs 'moranajp' and a local analyser such as MeCab
#'   sentences <- as_sentences(sample_text())
#'   analyze_morphemes(sentences, bin_dir = "d:/pf/mecab/bin")
#' }
#'
#' @export
analyze_morphemes <- function(sentences, method = "mecab",
                              bin_dir = "", iconv = "",
                              mecabrc = NULL, max_bytes = 8000, ...){
  if(is.data.frame(sentences)){
    if(!"sentence" %in% colnames(sentences)){
      stop("`sentences` has no column `sentence`.", call. = FALSE)
    }
    sentences <- sentences[["sentence"]]
  }
  sentences <- as.character(sentences)
  if(!requireNamespace("moranajp", quietly = TRUE)){
    message("Package 'moranajp' is not installed, ",
            "so no morphological analysis was done.\n",
            "  remotes::install_github(\"matutosi/moranajp\")")
    return(invisible(NULL))
  }
  if(method == "mecab"){
    rc <- if(is.null(mecabrc)) find_mecabrc(bin_dir) else mecabrc
    if(nzchar(rc) && !nzchar(Sys.getenv("MECABRC"))){
      # MeCab reads the path as it is, and only takes backslashes here
      Sys.setenv(MECABRC = gsub("/", "\\\\", rc))
      on.exit(Sys.unsetenv("MECABRC"), add = TRUE)
    }
  }
  # a space on each side keeps moranajp's "BP" marker a morpheme of its
  # own, so that the sentence boundaries survive the analysis
  padded <- paste0(" ", sentences, " ")
  chunk  <- sentence_chunks(padded, max_bytes = max_bytes)
  parts  <- vector("list", max(c(chunk, 0L)))
  done   <- 0L
  failed <- FALSE
  for(g in seq_along(parts)){
    take <- chunk == g
    part <- analyze_chunk(padded[take], method = method, bin_dir = bin_dir,
                          iconv = iconv, ...)
    if(is.null(part)){
      failed <- TRUE
      break
    }
    part[["sentence_id"]] <- part[["sentence_id"]] + done
    done       <- done + sum(take)
    parts[[g]] <- part
  }
  morphemes <- if(failed || !length(parts)) NULL else do.call(rbind, parts)
  if(is.null(morphemes)){
    message("Morphological analysis by '", method, "' failed, ",
            "so NULL was returned.\n",
            "  Check that '", method, "' is installed and that ",
            "`bin_dir` points to it.")
    return(invisible(NULL))
  }
  if(!nrow(morphemes)){
    message("Morphological analysis by '", method, "' gave nothing back, ",
            "so NULL was returned.")
    return(invisible(NULL))
  }
  check_sentence_ids(morphemes, length(sentences))
  morphemes
}

#' Run the analyser over one chunk of sentences
#'
#' Internal function for [analyze_morphemes()].
#' Returns `NULL` when the analysis could not be run, so that the caller
#' can say so once instead of once per chunk.
#'
#' @inheritParams analyze_morphemes
#' @return A data.frame of morphemes with a `sentence_id` column,
#'   or `NULL`.
#' @keywords internal
analyze_chunk <- function(sentences, method, bin_dir, iconv, ...){
  morphemes <- try(
    moranajp::moranajp_all(tibble::tibble(text = sentences),
      text_col = "text", method = method,
      bin_dir = bin_dir, iconv = iconv, ...),
    silent = TRUE)
  if(inherits(morphemes, "try-error") || is.null(morphemes)) return(NULL)
  if(!nrow(morphemes)) return(NULL)
  colnames(morphemes)[colnames(morphemes) == "text_id"] <- "sentence_id"
  morphemes
}

#' Group sentences into chunks the analyser can swallow
#'
#' Internal function for [analyze_morphemes()].
#' MeCab reads one line at a time into a buffer of a fixed size, in
#' bytes, and splits the line when it does not fit; the split falls in
#' the middle of a character and the text after it is unusable.
#' 'moranajp' joins the sentences into one line and groups them by the
#' number of characters, which is not the same thing: a Japanese
#' character takes three bytes in UTF-8, so a group well inside its
#' character limit can still be far over the buffer.
#'
#' A sentence longer than `max_bytes` on its own is left in a chunk of
#' its own rather than dropped.
#'
#' @param sentences A character vector.
#' @param max_bytes An integer.  Largest chunk, counted in bytes.
#' @return An integer vector, the chunk number of each sentence.
#' @keywords internal
sentence_chunks <- function(sentences, max_bytes = 8000){
  # 2 for the "BP" marker moranajp puts between the sentences
  size  <- nchar(sentences, type = "bytes") + 2L
  chunk <- integer(length(sentences))
  group <- 1L
  used  <- 0L
  for(i in seq_along(size)){
    if(used > 0L && used + size[[i]] > max_bytes){
      group <- group + 1L
      used  <- 0L
    }
    chunk[[i]] <- group
    used       <- used + size[[i]]
  }
  chunk
}

#' Warn when the sentence numbers do not match the sentences
#'
#' Internal function for [analyze_morphemes()].
#' 'moranajp' numbers the sentences by counting its `"BP"` markers, and
#' the count is short when a marker was swallowed by the word next to it.
#' Everything after such a place would be linked to the wrong sentence,
#' so it is better to say so than to return a table that looks fine.
#'
#' @param morphemes A data.frame with a `sentence_id` column.
#' @param n An integer.  The number of sentences that were sent.
#' @return `morphemes`, invisibly.
#' @keywords internal
check_sentence_ids <- function(morphemes, n){
  if(!"sentence_id" %in% colnames(morphemes)) return(invisible(morphemes))
  found <- length(unique(morphemes[["sentence_id"]]))
  if(found != n){
    message("The analyser gave back ", found, " sentences for ", n,
            " that were sent, so the numbering may be shifted.\n",
            "  Check the sentences that hold a word the analyser ",
            "does not know.")
  }
  invisible(morphemes)
}

#' Content words of a text
#'
#' Splits a text into sentences, runs a morphological analysis and picks
#' the content words.  A shortcut for [as_sentences()],
#' [analyze_morphemes()] and [pick_content_words()] in a row.
#'
#' @inheritParams analyze_morphemes
#' @param text A character vector of lines, or a data.frame of sentences
#'   as returned by [as_sentences()].
#' @param pos A character vector of parts of speech to keep.
#' @param skip_pos_1 A character vector of sub categories to drop.
#' @param stop_words A character vector of words to drop.
#' @return A tibble as returned by [pick_content_words()],
#'   or `NULL` when the analysis could not be run.
#'   Join it to the table of [as_sentences()] by `sentence_id`.
#' @examples
#' \dontrun{
#'   # needs 'moranajp' and a local analyser such as MeCab
#'   content_words(sample_text(), bin_dir = "d:/pf/mecab/bin")
#' }
#'
#' @export
content_words <- function(text, method = "mecab", bin_dir = "", iconv = "",
                          pos        = content_pos(),
                          skip_pos_1 = skipped_pos_1(),
                          stop_words = stop_words_ja(), ...){
  sentences <- if(is.data.frame(text)) text else as_sentences(text)
  morphemes <- analyze_morphemes(sentences, method = method,
                                 bin_dir = bin_dir, iconv = iconv, ...)
  if(is.null(morphemes)) return(invisible(NULL))
  pick_content_words(morphemes, pos = pos, skip_pos_1 = skip_pos_1,
                     stop_words = stop_words)
}

#' Look for the settings file of MeCab
#'
#' Internal function for [analyze_morphemes()].
#' MeCab keeps `mecabrc` in the `etc` directory beside `bin`, so the
#' file is looked for there first.
#'
#' @param bin_dir A string.  Directory of the analyser.
#' @return A string.  The path of the file, or `""` when it is not
#'   found.
#' @keywords internal
find_mecabrc <- function(bin_dir){
  if(!nzchar(bin_dir)) return("")
  here <- c(file.path(dirname(bin_dir), "etc", "mecabrc"),
            file.path(bin_dir, "mecabrc"),
            file.path(bin_dir, "etc", "mecabrc"))
  found <- here[file.exists(here)]
  if(length(found) == 0) "" else found[[1]]
}

#' Take a column out of a morpheme table
#'
#' Internal function for [pick_content_words()].
#' Looks for the English column name first, then for the Japanese one
#' used by 'moranajp'.
#'
#' @param morphemes A data.frame of morphemes.
#' @param name A string: "form", "pos", "pos_1" or "lemma".
#' @return A vector, or `NULL` when the column is missing.
#' @keywords internal
morpheme_col <- function(morphemes, name){
  jp <- c(form  = "\u8868\u5c64\u5f62",              # 表層形
          pos   = "\u54c1\u8a5e",                    # 品詞
          pos_1 = "\u54c1\u8a5e\u7d30\u5206\u985e1", # 品詞細分類1
          lemma = "\u539f\u5f62")                    # 原形
  cols <- colnames(morphemes)
  if(name %in% cols)     return(morphemes[[name]])
  if(jp[[name]] %in% cols) return(morphemes[[jp[[name]]]])
  NULL
}
