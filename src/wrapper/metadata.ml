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

let of_metadata metadata =
  let module M = Wrappers.ModelMetadata in
  let custom_map =
    M.custom_map_keys metadata
    |> Option.value ~default:[]
    |> List.filter_map ~f:(fun key ->
           M.lookup_custom_map metadata key |> Option.map ~f:(fun value -> key, value))
  in
  { description = M.description metadata
  ; domain = M.domain metadata
  ; graph_description = M.graph_description metadata
  ; graph_name = M.graph_name metadata
  ; producer_name = M.producer_name metadata
  ; version = M.version metadata
  ; custom_map
  }

let of_session session = Wrappers.Session.model_metadata session |> of_metadata
