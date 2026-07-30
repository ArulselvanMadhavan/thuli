import "types"
import "tensor"

module type QUANTUM_TENSOR = {
  include ND_TENSOR
  val kron [s1] [s2] [rank] : tensor [s1] [rank] -> tensor [s2] [rank] -> tensor [s1 * s2] [rank]
}

module MkQuantumTensor (N: NUMERIC) : QUANTUM_TENSOR with t = N.t = {
  open NdTensor {type t = N.t}

  def kron [s1] [s2] [rank] (A: tensor [s1] [rank]) (B: tensor [s2] [rank]) : tensor [s1 * s2] [rank] =
    let b_shape = get_rank B
    let out_shape = map2 (*) (get_rank A) b_shape
    let out_data : [s1 * s2]N.t =
      tabulate (s1 * s2) (\flat_out_idx ->
                            let k_idx = unflat_offset out_shape flat_out_idx
                            in N.mul (get A (map2 (/) k_idx b_shape))
                                     (get B (map2 (%) k_idx b_shape)))
    in make out_shape out_data
}
