open! Base
open! Import
include module type of Wrappers.Value with type t = Wrappers.Value.t

val of_bigarray : (_, _, Bigarray.c_layout) Bigarray.Genarray.t -> t

val to_bigarray
  :  t
  -> ('a, 'b) Bigarray.kind
  -> ('a, 'b, Bigarray.c_layout) Bigarray.Genarray.t
