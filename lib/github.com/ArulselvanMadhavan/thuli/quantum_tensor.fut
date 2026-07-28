import "types"
import "tensor"

module type QUANTUM_TENSOR = {
  include ND_TENSOR
  val kron [s1] [s2] [rank] : tensor [s1] [rank] -> tensor [s2] [rank] -> tensor [s1 * s2] [rank]
}

module MkQuantumTensor (N: NUMERIC) : QUANTUM_TENSOR with t = N.t = {
  open NdTensor {type t = N.t}

  def kron [s1] [s2] [rank] (A: tensor [s1] [rank]) (B: tensor [s2] [rank]) : tensor [s1 * s2] [rank] =
    let a_shape = get_rank A
    let b_shape = get_rank B
    let a_data = get_data A
    let b_data = get_data B
    let out_shape = map2 (*) a_shape b_shape
    let out_data : [s1 * s2]N.t =
      tabulate (s1 * s2) (\flat_out_idx ->
                            let k_idx = unflat_offset out_shape flat_out_idx
                            let a_idx = map2 (/) k_idx b_shape
                            let b_idx = map2 (%) k_idx b_shape
                            let off_a = flat_offset a_shape a_idx
                            let off_b = flat_offset b_shape b_idx
                            in N.mul a_data[i32.i64 off_a] b_data[i32.i64 off_b])
    in make out_shape out_data
}
