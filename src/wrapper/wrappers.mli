(* A low-level but hopefully type safe version of the API. *)
open! Base

module Env : sig
  type t

  val create : string -> t
end

module TensorTypeAndShapeInfo : sig
  type t

  val element_type : t -> Element_type.t
  val element_count : t -> int
  val dimensions_count : t -> int
  val dimensions : t -> int array
end

module Value : sig
  type t

  val create_tensor : Element_type.t -> shape:int array -> t
  val is_tensor : t -> bool
  val tensor_type_and_shape : t -> TensorTypeAndShapeInfo.t
  val of_bigarray : (_, _, Bigarray.c_layout) Bigarray.Genarray.t -> t

  val to_bigarray
    :  t
    -> ('a, 'b) Bigarray.kind
    -> ('a, 'b, Bigarray.c_layout) Bigarray.Genarray.t

  (* The [copy_from_...] functions do not check that the actual value type matches the
     bigarray type. It might be a good idea to introduce a parameterized type for tensors
     as a wrapper around [Value.t].
  *)
  val copy_from_bigarray : t -> (_, _, Bigarray.c_layout) Bigarray.Genarray.t -> unit
  val copy_to_bigarray : t -> (_, _, Bigarray.c_layout) Bigarray.Genarray.t -> unit
end

module SessionOptions : sig
  type t

  val create : unit -> t
end

module Session : sig
  type t

  val create : Env.t -> SessionOptions.t -> model_path:string -> t
  val input_count : t -> int
  val output_count : t -> int
  val run_1_1 : t -> Value.t -> input_name:string -> output_name:string -> Value.t
end
