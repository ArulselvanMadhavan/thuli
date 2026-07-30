open Bigarray
open Ctypes
open Bindings

type parts = {
  shape : int64 array;
  re : float array;
  im : float array;
}

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

let array1_to_int64 ba =
  Array.init (Array1.dim ba) (fun i -> ba.{i})

let array1_to_float ba =
  Array.init (Array1.dim ba) (fun i -> ba.{i})

let with_i64_array arr f =
  let len = Array.length arr in
  let ba = Array1.create Int64 c_layout len in
  for i = 0 to len - 1 do
    ba.{i} <- arr.(i)
  done;
  f (bigarray_start array1 ba)

let with_f32_array arr f =
  let len = Array.length arr in
  let ba = Array1.create Float32 c_layout len in
  for i = 0 to len - 1 do
    ba.{i} <- arr.(i)
  done;
  f (bigarray_start array1 ba)

let read_i64_1d arr =
  let len = Int64.to_int !@(futhark_shape_i64_1d (Lazy.force ctx) arr) in
  let ba = Array1.create Int64 c_layout len in
  check
    (futhark_values_i64_1d (Lazy.force ctx) arr
       (bigarray_start array1 ba));
  array1_to_int64 ba

let read_f32_1d arr =
  let len = Int64.to_int !@(futhark_shape_f32_1d (Lazy.force ctx) arr) in
  let ba = Array1.create Float32 c_layout len in
  check
    (futhark_values_f32_1d (Lazy.force ctx) arr
       (bigarray_start array1 ba));
  array1_to_float ba

let kron_parts (a : parts) (b : parts) : parts =
  if Array.length a.shape <> Array.length b.shape then
    invalid_arg "kron: rank mismatch";
  Lazy.force ctx |> ignore;
  with_i64_array a.shape (fun a_shape_ptr ->
      with_f32_array a.re (fun a_re_ptr ->
          with_f32_array a.im (fun a_im_ptr ->
              let s1 = Array.length a.re in
              if Array.length a.im <> s1 then
                invalid_arg "kron: re/im length mismatch";
              with_i64_array b.shape (fun b_shape_ptr ->
                  with_f32_array b.re (fun b_re_ptr ->
                      with_f32_array b.im (fun b_im_ptr ->
                          let s2 = Array.length b.re in
                          if Array.length b.im <> s2 then
                            invalid_arg "kron: re/im length mismatch";
                          let c = Lazy.force ctx in
                          let fa_shape =
                            futhark_new_i64_1d c a_shape_ptr
                              (Int64.of_int (Array.length a.shape))
                          in
                          let fa_re =
                            futhark_new_f32_1d c a_re_ptr (Int64.of_int s1)
                          in
                          let fa_im =
                            futhark_new_f32_1d c a_im_ptr (Int64.of_int s1)
                          in
                          let fb_shape =
                            futhark_new_i64_1d c b_shape_ptr
                              (Int64.of_int (Array.length b.shape))
                          in
                          let fb_re =
                            futhark_new_f32_1d c b_re_ptr (Int64.of_int s2)
                          in
                          let fb_im =
                            futhark_new_f32_1d c b_im_ptr (Int64.of_int s2)
                          in
                          let out_ptr = allocate (ptr void) null in
                          check
                            (futhark_entry_kron_entry c out_ptr fa_shape fa_re
                               fa_im fb_shape fb_re fb_im);
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
                          result))))))
