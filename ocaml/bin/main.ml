open Thuli_tensor

let pauli_x =
  make_complex ~shape:[ 2L; 2L ]
    ~re:[ 0.; 0.; 1.; 0. ]
    ~im:[ 0.; 0.; 0.; 0. ]

let () =
  let x2 = kpow pauli_x 2 in
  Printf.printf "kpow Pauli-X 2: shape=[%Ld;%Ld] size=%d\n" (shape_get x2 0)
    (shape_get x2 1) (size x2);
  let x3 = kpow pauli_x 3 in
  Printf.printf "kpow Pauli-X 3: shape=[%Ld;%Ld] size=%d\n" (shape_get x3 0)
    (shape_get x3 1) (size x3)
