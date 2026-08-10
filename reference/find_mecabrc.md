# Look for the settings file of MeCab

Internal function for
[`analyze_morphemes()`](https://matutosi.github.io/sujimichi/reference/analyze_morphemes.md).
MeCab keeps `mecabrc` in the `etc` directory beside `bin`, so the file
is looked for there first.

## Usage

``` r
find_mecabrc(bin_dir)
```

## Arguments

- bin_dir:

  A string. Directory of the analyser.

## Value

A string. The path of the file, or `""` when it is not found.
