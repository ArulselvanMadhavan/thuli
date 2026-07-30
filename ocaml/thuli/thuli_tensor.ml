type c64 = { re : float; im : float }

type tensor = {
  shape : int64 array;
  data : c64 array;
}

let c64_of_parts re im = { re; im }

let tensor_of_parts shape re im =
  let n = Array.length re in
  if Array.length im <> n then invalid_arg "tensor_of_parts: length mismatch";
  if n = 0 && Array.length shape <> 0 then
    invalid_arg "tensor_of_parts: empty data";
  { shape; data = Array.init n (fun i -> c64_of_parts re.(i) im.(i)) }

let tensor_to_parts (t : tensor) : Kron.parts =
  let re_data = Array.map (fun (c : c64) -> c.re) t.data in
  let im_data = Array.map (fun (c : c64) -> c.im) t.data in
  { shape = t.shape; re = re_data; im = im_data }

let parts_to_tensor (p : Kron.parts) =
  tensor_of_parts p.shape p.re p.im

let kron (a : tensor) (b : tensor) =
  parts_to_tensor (Kron.kron_parts (tensor_to_parts a) (tensor_to_parts b))

let kpow (t : tensor) = function
  | n when n < 0 -> invalid_arg "kpow: negative exponent"
  | 0 ->
      { shape = Array.map (fun _ -> 1L) t.shape; data = [| c64_of_parts 1. 0. |] }
  | 1 -> t
  | n ->
      let rec loop i acc =
        if i = 0 then acc else loop (i - 1) (kron t acc)
      in
      loop (n - 1) t
