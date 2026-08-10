test_that("a bracket holding a year is removed", {
  expect_equal(drop_citations("畦畔は重要である（丑丸2012）．"),
               "畦畔は重要である．")
  expect_equal(drop_citations("as reported (Smith 2002)."),
               "as reported .")
})

test_that("a citation of several sources is removed as one", {
  expect_equal(
    drop_citations("複雑で多様な生態系であり（LeCoeuretal.2002;Tscharntkeetal.2005）．"),
    "複雑で多様な生態系であり．")
})

test_that("what follows the year inside the bracket goes with it", {
  expect_equal(drop_citations("基本的なものである（山口・梅本1996，図1）．"),
               "基本的なものである．")
})

test_that("a bracket without a year is kept", {
  expect_equal(drop_citations("草原(以下，畦畔草原という)を扱う．"),
               "草原(以下，畦畔草原という)を扱う．")
  expect_equal(drop_citations("3つの部分（まえあぜ・平坦面・傾斜面）．"),
               "3つの部分（まえあぜ・平坦面・傾斜面）．")
})

test_that("a year outside a bracket is part of the prose", {
  expect_equal(drop_citations("2011年における面積は約14万haである．"),
               "2011年における面積は約14万haである．")
  expect_equal(drop_citations("1990年代に入るまでは少なかった．"),
               "1990年代に入るまでは少なかった．")
})

test_that("several citations in one line are all removed", {
  expect_equal(
    drop_citations("佐竹ほか編（1981）および岩槻（1992）に従った．"),
    "佐竹ほか編および岩槻に従った．")
})

test_that("a text without a citation is unchanged", {
  expect_equal(drop_citations("ふつうの文．"), "ふつうの文．")
  expect_equal(drop_citations(character(0)), character(0))
})

test_that("drop_citations() takes a vector of lines", {
  lines <- c("畦畔は重要である（丑丸2012）．", "ふつうの文．")
  expect_equal(drop_citations(lines), c("畦畔は重要である．", "ふつうの文．"))
})
