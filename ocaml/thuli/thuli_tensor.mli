type c64 = { re : float; im : float }

type tensor = {
  shape : int64 array;
  data : c64 array;
}

val kron : tensor -> tensor -> tensor
(** [kron a b] is the Kronecker product of [a] and [b]. *)

val kpow : tensor -> int -> tensor
(** [kpow t n] is [t] Kronecker-producted with itself [n] times.
    [kpow t 0] is the 1-element identity; [kpow t 1] is [t]. *)

val c64_of_parts : float -> float -> c64
val tensor_of_parts : int64 array -> float array -> float array -> tensor
