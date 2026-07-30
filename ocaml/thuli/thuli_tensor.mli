type i64_arr =
  (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array1.t

type f32_arr =
  (float, Bigarray.float32_elt, Bigarray.c_layout) Bigarray.Array1.t

type tensor = Kron.parts

val rank : tensor -> int
val size : tensor -> int
val shape_get : tensor -> int -> int64

val make :
  shape:i64_arr -> re:f32_arr -> im:f32_arr -> tensor

val make_complex :
  shape:int64 list -> re:float list -> im:float list -> tensor

val kron : tensor -> tensor -> tensor
(** [kron a b] is the Kronecker product of [a] and [b]. *)

val kpow : tensor -> int -> tensor
(** [kpow t n] is [t] Kronecker-producted with itself [n] times.
    [kpow t 0] is the 1-element identity; [kpow t 1] is [t]. *)
