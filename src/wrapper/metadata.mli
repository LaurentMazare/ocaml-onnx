open! Base
open! Import

type t =
  { description : string
  ; domain : string
  ; graph_description : string
  ; graph_name : string
  ; producer_name : string
  ; version : Int64.t
  ; custom_map : (string * string) list
  }
[@@deriving sexp]

val of_metadata : Wrappers.ModelMetadata.t -> t
val of_session : Wrappers.Session.t -> t
