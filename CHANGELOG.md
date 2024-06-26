## 0.3.0 (2024-06-25)

- Ecto distance functions no longer cast lists to vectors
- Added support for `halfvec` and `sparsevec` types
- Added support for `bit` type to Ecto
- Added `Pgvector.extensions/0` function
- Added `l1_distance`, `hamming_distance`, and `jaccard_distance` functions for Ecto
- Dropped support for Elixir < 1.13

## 0.2.1 (2023-09-25)

- Added support for `Pgvector` to `Pgvector.new/1`

## 0.2.0 (2023-05-31)

- Vectors are now returned as `Pgvector` structs instead of lists
- Added support for Nx tensors
- Dropped support for Elixir < 1.11

## 0.1.3 (2023-01-25)

- Fixed composition with distance functions for Ecto

## 0.1.2 (2022-08-26)

- Added distance functions for Ecto

## 0.1.1 (2022-08-05)

- Added support for Ecto

## 0.1.0 (2022-08-04)

- First release
