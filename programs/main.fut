import "../lib/github.com/ArulselvanMadhavan/thuli/quantum_tensor"
import "../lib/github.com/ArulselvanMadhavan/thuli/types"

module QT = MkQuantumTensor C64

entry main =
  let pauli_x =
    QT.make [2i64, 2i64] [C64.zero, C64.one, C64.one, C64.zero]
  let pauli_z =
    QT.make [2i64, 2i64]
      [C64.one, C64.zero, C64.zero, (f32.neg 1f32, 0f32)]
  in map (.0) (QT.get_data (QT.kron pauli_x pauli_z))
