module type NUMERIC = {
  type t
  val mul : t -> t -> t
  val add : t -> t -> t
  val zero : t
  val one : t
}

module ComplexNumeric (F: real) : NUMERIC with t = (F.t, F.t) = {
  type t = (F.t, F.t)

  -- F.i32 converts integer literals to F.t dynamically (0.0f32 or 0.0f64)
  def zero : t = (F.i32 0, F.i32 0)
  def one : t = (F.i32 1, F.i32 0)

  def add ((r1, i1): t) ((r2, i2): t) : t =
    (F.(r1 + r2), F.(i1 + i2))

  def mul ((r1, i1): t) ((r2, i2): t) : t =
    let ac = F.(r1 * r2)
    let bd = F.(i1 * i2)
    let ad = F.(r1 * i2)
    let bc = F.(i1 * r2)
    in (F.(ac - bd), F.(ad + bc))
}

module C64 = ComplexNumeric f32
module C128 = ComplexNumeric f64
