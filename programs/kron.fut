import "../lib/github.com/ArulselvanMadhavan/thuli/quantum_tensor"
import "../lib/github.com/ArulselvanMadhavan/thuli/types"

module QT = MkQuantumTensor C64

def from_parts [n] (re: [n]f32) (im: [n]f32) : [n](f32, f32) =
  map2 (\r i -> (r, i)) re im

def to_parts [n] (xs: [n](f32, f32)) : ([n]f32, [n]f32) =
  (map (.0) xs, map (.1) xs)

entry kron_entry [s1] [s2] [rank]
  (a_shape: [rank]i64) (a_re: [s1]f32) (a_im: [s1]f32)
  (b_shape: [rank]i64) (b_re: [s2]f32) (b_im: [s2]f32)
  : ([rank]i64, [s1 * s2]f32, [s1 * s2]f32) =
  let a = QT.make a_shape (from_parts a_re a_im)
  let b = QT.make b_shape (from_parts b_re b_im)
  let c = QT.kron a b
  let (re, im) = to_parts (QT.get_data c)
  in (QT.get_rank c, re, im)
