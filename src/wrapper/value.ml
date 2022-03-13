open! Base
open! Import
include Wrappers.Value

let tensor_type_and_shape = Tensor_type_and_shape.of_value

let of_bigarray (type a b) (ba : (b, a, Bigarray.c_layout) Bigarray.Genarray.t) =
  let (element_type : Element_type.t) =
    match Bigarray.Genarray.kind ba with
    | Float32 -> Float
    | Float64 -> Double
    | Int8_signed -> Int8
    | Int8_unsigned -> UInt8
    | Int16_signed -> Int16
    | Int16_unsigned -> UInt16
    | Int32 -> Int32
    | Int64 -> Int64
    | _ -> Unknown
  in
  let t = create_tensor element_type ~shape:(Bigarray.Genarray.dims ba) in
  copy_from_bigarray t ba;
  t

let to_bigarray (type a b) t (kind : (a, b) Bigarray.kind) =
  let { Tensor_type_and_shape.dimensions; element_type } = tensor_type_and_shape t in
  let (ba : (a, b, Bigarray.c_layout) Bigarray.Genarray.t) =
    match kind, element_type with
    | Float32, Float -> Bigarray.Genarray.create kind C_layout dimensions
    | Float64, Double -> Bigarray.Genarray.create kind C_layout dimensions
    | Int64, Int64 -> Bigarray.Genarray.create kind C_layout dimensions
    | Int32, Int32 -> Bigarray.Genarray.create kind C_layout dimensions
    | _, et ->
      Printf.failwithf
        "unsupported element type or type mismatch, tensor type %s"
        (Element_type.to_string et)
        ()
  in
  copy_to_bigarray t ba;
  ba
