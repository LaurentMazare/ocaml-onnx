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

val of_c_int : int -> t
