open! Base
open! Import

type t =
  { element_type : Element_type.t
  ; dimensions : int array
  }
[@@deriving sexp]

let create w =
  { element_type = Wrappers.TensorTypeAndShapeInfo.element_type w
  ; dimensions = Wrappers.TensorTypeAndShapeInfo.dimensions w
  }

let of_value v = Wrappers.Value.tensor_type_and_shape_ v |> create
