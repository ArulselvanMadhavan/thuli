open Ctypes
open Foreign

let context = ptr void
let context_config = ptr void
let i64_1d = ptr void
let f32_1d = ptr void
let kron_out = ptr void

let futhark_context_config_new =
  foreign "futhark_context_config_new" (void @-> returning context_config)

let futhark_context_new =
  foreign "futhark_context_new" (context_config @-> returning context)

let futhark_context_get_error =
  foreign "futhark_context_get_error" (context @-> returning string)

let futhark_new_i64_1d =
  foreign "futhark_new_i64_1d"
    (context @-> ptr int64_t @-> int64_t @-> returning i64_1d)

let futhark_new_f32_1d =
  foreign "futhark_new_f32_1d"
    (context @-> ptr float @-> int64_t @-> returning f32_1d)

let futhark_free_i64_1d =
  foreign "futhark_free_i64_1d" (context @-> i64_1d @-> returning int)

let futhark_free_f32_1d =
  foreign "futhark_free_f32_1d" (context @-> f32_1d @-> returning int)

let futhark_values_i64_1d =
  foreign "futhark_values_i64_1d"
    (context @-> i64_1d @-> ptr int64_t @-> returning int)

let futhark_values_f32_1d =
  foreign "futhark_values_f32_1d"
    (context @-> f32_1d @-> ptr float @-> returning int)

let futhark_shape_i64_1d =
  foreign "futhark_shape_i64_1d" (context @-> i64_1d @-> returning (ptr int64_t))

let futhark_shape_f32_1d =
  foreign "futhark_shape_f32_1d" (context @-> f32_1d @-> returning (ptr int64_t))

let futhark_entry_kron_entry =
  foreign "futhark_entry_kron_entry"
    (context
    @-> ptr kron_out
    @-> i64_1d
    @-> f32_1d
    @-> f32_1d
    @-> i64_1d
    @-> f32_1d
    @-> f32_1d
    @-> returning int)

let futhark_project_kron_out_0 =
  foreign "futhark_project_opaque_tup3_arr1d_i64_arr1d_f32_arr1d_f32_0"
    (context @-> ptr i64_1d @-> kron_out @-> returning int)

let futhark_project_kron_out_1 =
  foreign "futhark_project_opaque_tup3_arr1d_i64_arr1d_f32_arr1d_f32_1"
    (context @-> ptr f32_1d @-> kron_out @-> returning int)

let futhark_project_kron_out_2 =
  foreign "futhark_project_opaque_tup3_arr1d_i64_arr1d_f32_arr1d_f32_2"
    (context @-> ptr f32_1d @-> kron_out @-> returning int)

let futhark_free_kron_out =
  foreign "futhark_free_opaque_tup3_arr1d_i64_arr1d_f32_arr1d_f32"
    (context @-> kron_out @-> returning int)
