type t =
  | Undefined
  | Float
  | UInt8
  | Int8
  | UInt16
  | Int16
  | Int32
  | Int64
  | String
  | Bool
  | Float16
  | Double
  | UInt32
  | UInt64
  | Complex64
  | Complex128
  | BFloat16
  | Unknown

let of_c_int = function
  | 0 -> Undefined
  | 1 -> Float
  | 2 -> UInt8
  | 3 -> Int8
  | 4 -> UInt16
  | 5 -> Int16
  | 6 -> Int32
  | 7 -> Int64
  | 8 -> String
  | 9 -> Bool
  | 10 -> Float16
  | 11 -> Double
  | 12 -> UInt32
  | 13 -> UInt64
  | 14 -> Complex64
  | 15 -> Complex128
  | 16 -> BFloat16
  | _ -> Unknown
