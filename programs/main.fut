import "../lib/github.com/ArulselvanMadhavan/thuli/tensor"
import "../lib/github.com/ArulselvanMadhavan/thuli/types"

module Complex64Tensor = NdTensor {type t = c64}

entry main =
  let t =
    Complex64Tensor.make [2i64, 2i64] (replicate 4 (0f32, 0f32))
  in Complex64Tensor.flat_offset (Complex64Tensor.get_rank t) [0i64, 0i64]
