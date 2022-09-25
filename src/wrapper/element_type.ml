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
[@@deriving sexp]

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

let to_c_int = function
  | Undefined -> 0
  | Float -> 1
  | UInt8 -> 2
  | Int8 -> 3
  | UInt16 -> 4
  | Int16 -> 5
  | Int32 -> 6
  | Int64 -> 7
  | String -> 8
  | Bool -> 9
  | Float16 -> 10
  | Double -> 11
  | UInt32 -> 12
  | UInt64 -> 13
  | Complex64 -> 14
  | Complex128 -> 15
  | BFloat16 -> 16
  | Unknown -> 0

let to_string = function
  | Undefined -> "Undefined"
  | Float -> "Float"
  | UInt8 -> "UInt8"
  | Int8 -> "Int8"
  | UInt16 -> "UInt16"
  | Int16 -> "Int16"
  | Int32 -> "Int32"
  | Int64 -> "Int64"
  | String -> "String"
  | Bool -> "Bool"
  | Float16 -> "Float16"
  | Double -> "Double"
  | UInt32 -> "UInt32"
  | UInt64 -> "UInt64"
  | Complex64 -> "Complex64"
  | Complex128 -> "Complex128"
  | BFloat16 -> "BFloat16"
  | Unknown -> "Unknown"
