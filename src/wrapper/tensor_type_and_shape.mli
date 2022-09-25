open! Base
open! Import

type t =
  { element_type : Element_type.t
  ; dimensions : int array
  }
[@@deriving sexp]

val of_value : Wrappers.Value.t -> t
