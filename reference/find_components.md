# Steps of dead_code()

Internal function for
[`dead_code()`](https://matutosi.github.io/sujimichi/reference/dead_code.md).
`find_components()` runs a union-find over the sentences of one
paragraph, and numbers the components from 1 in the order `node` first
meets each of them.

## Usage

``` r
find_components(node, from, to)
```

## Arguments

- node:

  A vector of sentence numbers, the nodes of one paragraph.

- from, to:

  Vectors of sentence numbers, the two ends of each edge within that
  paragraph.

## Value

An integer vector, named by `node`, with a component number for each.
