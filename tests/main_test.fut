import "../lib/github.com/ArulselvanMadhavan/thuli/tensor"

module I64Tensor = NdTensor {type t = i64}

entry flat_offset_2d (sh: [2]i64) (idx: [2]i64) : i64 =
  I64Tensor.flat_offset sh idx

entry flat_offset_3d (sh: [3]i64) (idx: [3]i64) : i64 =
  I64Tensor.flat_offset sh idx

entry unflat_offset_2d (sh: [2]i64) (flat_idx: i64) : [2]i64 =
  I64Tensor.unflat_offset sh flat_idx

entry unflat_offset_3d (sh: [3]i64) (flat_idx: i64) : [3]i64 =
  I64Tensor.unflat_offset sh flat_idx

entry roundtrip_3d (sh: [3]i64) (idx: [3]i64) : [3]i64 =
  I64Tensor.unflat_offset sh (I64Tensor.flat_offset sh idx)

-- flat_offset 2d origin
-- ==
-- entry: flat_offset_2d
-- input { [3i64, 4i64] [0i64, 0i64] } output { 0i64 }

-- flat_offset 2d row-major
-- ==
-- entry: flat_offset_2d
-- input { [3i64, 4i64] [1i64, 2i64] } output { 6i64 }

-- flat_offset 2d last element
-- ==
-- entry: flat_offset_2d
-- input { [3i64, 4i64] [2i64, 3i64] } output { 11i64 }

-- flat_offset 3d
-- ==
-- entry: flat_offset_3d
-- input { [2i64, 3i64, 4i64] [1i64, 2i64, 3i64] } output { 23i64 }

-- unflat_offset 2d
-- ==
-- entry: unflat_offset_2d
-- input { [3i64, 4i64] 6i64 } output { [1i64, 2i64] }

-- unflat_offset 3d
-- ==
-- entry: unflat_offset_3d
-- input { [2i64, 3i64, 4i64] 23i64 } output { [1i64, 2i64, 3i64] }

-- unflat_offset then flat_offset roundtrip
-- ==
-- entry: roundtrip_3d
-- input { [2i64, 3i64, 4i64] [1i64, 2i64, 3i64] } output { [1i64, 2i64, 3i64] }
