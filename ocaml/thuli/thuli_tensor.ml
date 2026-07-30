open Bigarray

type i64_arr = Kron.i64_arr
type f32_arr = Kron.f32_arr
type tensor = Kron.parts

let rank = Kron.rank
let size = Kron.size
let shape_get = Kron.shape_get
let make = Kron.make

let i64_arr_of_list xs =
  let ba = Array1.create Int64 c_layout (List.length xs) in
  List.iteri (fun i x -> ba.{i} <- x) xs;
  ba

let f32_arr_of_list xs =
  let ba = Array1.create Float32 c_layout (List.length xs) in
  List.iteri (fun i x -> ba.{i} <- x) xs;
  ba

let make_complex ~shape ~re ~im =
  make ~shape:(i64_arr_of_list shape) ~re:(f32_arr_of_list re)
    ~im:(f32_arr_of_list im)

let kron = Kron.kron_parts

let kpow t = function
  | n when n < 0 -> invalid_arg "kpow: negative exponent"
  | 0 ->
      let rank_n = rank t in
      let shape = Array1.create Int64 c_layout rank_n in
      for i = 0 to rank_n - 1 do
        shape.{i} <- 1L
      done;
      make ~shape ~re:(f32_arr_of_list [ 1. ]) ~im:(f32_arr_of_list [ 0. ])
  | 1 -> t
  | n ->
      let rec loop i acc =
        if i = 0 then acc else loop (i - 1) (kron t acc)
      in
      loop (n - 1) t
