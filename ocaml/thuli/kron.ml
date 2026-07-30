open Bigarray
open Ctypes
open Bindings

type i64_arr = (int64, int64_elt, c_layout) Array1.t
type f32_arr = (float, float32_elt, c_layout) Array1.t

type parts = {
  shape : i64_arr;
  re : f32_arr;
  im : f32_arr;
}

let rank t = Array1.dim t.shape
let size t = Array1.dim t.re
let shape_get t i = t.shape.{i}

let make ~shape ~re ~im =
  let n = Array1.dim re in
  if Array1.dim im <> n then invalid_arg "make: re/im length mismatch";
  if n = 0 && Array1.dim shape <> 0 then invalid_arg "make: empty data";
  { shape; re; im }

let ctx =
  lazy
    (let cfg = futhark_context_config_new () in
     futhark_context_new cfg)

let check rc =
  if rc <> 0 then
    let msg =
      try futhark_context_get_error (Lazy.force ctx) with _ -> "Futhark entry failed"
    in
    failwith msg

let with_i64_ba ba f = f (bigarray_start array1 ba)

let with_f32_ba ba f = f (bigarray_start array1 ba)

let with_parts { shape; re; im } f =
  let n = Array1.dim re in
  if Array1.dim im <> n then invalid_arg "kron: re/im length mismatch";
  with_i64_ba shape (fun shape_ptr ->
      with_f32_ba re (fun re_ptr ->
          with_f32_ba im (fun im_ptr ->
              f shape_ptr re_ptr im_ptr n (Array1.dim shape))))

let read_i64_1d arr =
  let len = Int64.to_int !@(futhark_shape_i64_1d (Lazy.force ctx) arr) in
  let ba = Array1.create Int64 c_layout len in
  check
    (futhark_values_i64_1d (Lazy.force ctx) arr
       (bigarray_start array1 ba));
  ba

let read_f32_1d arr =
  let len = Int64.to_int !@(futhark_shape_f32_1d (Lazy.force ctx) arr) in
  let ba = Array1.create Float32 c_layout len in
  check
    (futhark_values_f32_1d (Lazy.force ctx) arr
       (bigarray_start array1 ba));
  ba

let kron_parts (a : parts) (b : parts) : parts =
  if Array1.dim a.shape <> Array1.dim b.shape then
    invalid_arg "kron: rank mismatch";
  Lazy.force ctx |> ignore;
  with_parts a (fun a_shape_ptr a_re_ptr a_im_ptr s1 rank_a ->
      with_parts b (fun b_shape_ptr b_re_ptr b_im_ptr s2 rank_b ->
          let c = Lazy.force ctx in
          let fa_shape =
            futhark_new_i64_1d c a_shape_ptr (Int64.of_int rank_a)
          in
          let fa_re = futhark_new_f32_1d c a_re_ptr (Int64.of_int s1) in
          let fa_im = futhark_new_f32_1d c a_im_ptr (Int64.of_int s1) in
          let fb_shape =
            futhark_new_i64_1d c b_shape_ptr (Int64.of_int rank_b)
          in
          let fb_re = futhark_new_f32_1d c b_re_ptr (Int64.of_int s2) in
          let fb_im = futhark_new_f32_1d c b_im_ptr (Int64.of_int s2) in
          let out_ptr = allocate (ptr void) null in
          check
            (futhark_entry_kron_entry c out_ptr fa_shape fa_re fa_im fb_shape
               fb_re fb_im);
          let out = !@out_ptr in
          let out_shape_ptr = allocate (ptr void) null in
          let out_re_ptr = allocate (ptr void) null in
          let out_im_ptr = allocate (ptr void) null in
          check (futhark_project_kron_out_0 c out_shape_ptr out);
          check (futhark_project_kron_out_1 c out_re_ptr out);
          check (futhark_project_kron_out_2 c out_im_ptr out);
          let result =
            {
              shape = read_i64_1d !@out_shape_ptr;
              re = read_f32_1d !@out_re_ptr;
              im = read_f32_1d !@out_im_ptr;
            }
          in
          check (futhark_free_i64_1d c fa_shape);
          check (futhark_free_f32_1d c fa_re);
          check (futhark_free_f32_1d c fa_im);
          check (futhark_free_i64_1d c fb_shape);
          check (futhark_free_f32_1d c fb_re);
          check (futhark_free_f32_1d c fb_im);
          check (futhark_free_kron_out c out);
          check (futhark_free_i64_1d c !@out_shape_ptr);
          check (futhark_free_f32_1d c !@out_re_ptr);
          check (futhark_free_f32_1d c !@out_im_ptr);
          result))
