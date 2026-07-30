open Thuli_tensor

let pauli_x : tensor =
  { shape = [| 2L; 2L |];
    data =
      [| { re = 0.; im = 0. }
       ; { re = 1.; im = 0. }
       ; { re = 1.; im = 0. }
       ; { re = 0.; im = 0. }
      |]
  }

let () =
  let x2 = kpow pauli_x 2 in
  Printf.printf "kpow Pauli-X 2: shape=[%Ld;%Ld] size=%d\n"
    x2.shape.(0) x2.shape.(1) (Array.length x2.data);
  let x3 = kpow pauli_x 3 in
  Printf.printf "kpow Pauli-X 3: shape=[%Ld;%Ld] size=%d\n"
    x3.shape.(0) x3.shape.(1) (Array.length x3.data)
