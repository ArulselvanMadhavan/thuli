module type ND_TENSOR = {
  type t
  type~ tensor [size] [rank]

  val make [size] [rank] : [rank]i64 -> [size]t -> tensor [size] [rank]

  val get_rank [size] [rank] : tensor [size] [rank] -> [rank]i64

  val get_data [size] [rank] : tensor [size] [rank] -> [size]t

  val get [size] [rank] : tensor [size] [rank] -> [rank]i64 -> t

  val flat_offset [rank] : [rank]i64 -> [rank]i64 -> i64

  val unflat_offset [rank] : [rank]i64 -> i64 -> [rank]i64
}

module NdTensor (E: {type t}) : ND_TENSOR with t = E.t = {
  type t = E.t
  type~ tensor [size] [rank] = {shape: [rank]i64, data: [size]t}

  def make [size] [rank] (sh: [rank]i64) (d: [size]t) : tensor [size] [rank] = {shape = sh, data = d}

  def get_rank [size] [rank] (tens: tensor [size] [rank]) : [rank]i64 =
    tens.shape

  def get_data [size] [rank] (tens: tensor [size] [rank]) : [size]t =
    tens.data

  def flat_offset [rank] (sh: [rank]i64) (idx: [rank]i64) : i64 =
    let (_, offset) =
      loop (stride, acc) = (1, 0)
      for i in reverse (iota rank) do
        (stride * sh[i], acc + idx[i] * stride)
    in offset

  def unflat_offset [rank] (sh: [rank]i64) (flat_idx: i64) : [rank]i64 =
    let (_, idxs) =
      loop (rem, accs) = (flat_idx, replicate rank 0)
      for i in reverse (iota rank) do
        let dim = sh[i]
        let idx = rem % dim
        in (rem / dim, accs with [i] = idx)
    in idxs

  def get [size] [rank] (tens: tensor [size] [rank]) (idx: [rank]i64) : t =
    tens.data[i32.i64 (flat_offset tens.shape idx)]
}
