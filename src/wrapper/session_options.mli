open! Base
open! Import

type t = Wrappers.SessionOptions.t

val create : ?inter_op_num_threads:int -> ?intra_op_num_threads:int -> unit -> t
