import "../lib/github.com/arul/thuli/hello"

-- Hello world
-- ==
-- input { 0 }
-- output { [72u8, 101u8, 108u8, 108u8, 111u8, 44u8, 32u8, 87u8, 111u8, 114u8, 108u8, 100u8, 33u8] }

let main (_: i32) = copy hello
