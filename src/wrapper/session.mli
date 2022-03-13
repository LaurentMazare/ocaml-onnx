open! Base
open! Import
include module type of Wrappers.Session with type t = Wrappers.Session.t

val inputs : t -> Input_output_info.t list
val outputs : t -> Input_output_info.t list
