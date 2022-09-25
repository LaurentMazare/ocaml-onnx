open! Base
open! Import

type t =
  { name : string
  ; element_type : Element_type.t
  ; dimensions : int array
  }
[@@deriving sexp]
