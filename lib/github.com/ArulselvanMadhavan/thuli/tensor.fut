module type ND_TENSOR = {
  type t
  type~ tensor [size] [rank]

  val make [size] [rank] : [rank]i64 -> [size]t -> tensor [size] [rank]

  val get_rank [size] [rank] : tensor [size] [rank] -> [rank]i64

  val flat_offset [rank] : [rank]i64 -> [rank]i64 -> i64
}

module NdTensor (E: {type t}) : ND_TENSOR with t = E.t = {
  type t = E.t
  type~ tensor [size] [rank] = {shape: [rank]i64, data: [size]t}

  def make [size] [rank] (sh: [rank]i64) (d: [size]t) : tensor [size] [rank] = {shape = sh, data = d}

  def get_rank [size] [rank] (tens: tensor [size] [rank]) : [rank]i64 =
    tens.shape

  def flat_offset [rank] (sh: [rank]i64) (idx: [rank]i64) : i64 =
    let (_, offset) =
      loop (stride, acc) = (1, 0)
      for i in reverse (iota rank) do
        (stride * sh[i], acc + idx[i] * stride)
    in offset
}
