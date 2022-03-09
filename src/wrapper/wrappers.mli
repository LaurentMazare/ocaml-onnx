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

module TypeInfo : sig
  type t

  val cast_to_tensor_info : t -> TensorTypeAndShapeInfo.t
end

module ModelMetadata : sig
  type t

  val description : t -> string
  val domain : t -> string
  val graph_description : t -> string
  val graph_name : t -> string
  val producer_name : t -> string
  val version : t -> Int64.t
end

module Value : sig
  type t

  val create_tensor : Element_type.t -> shape:int array -> t
  val is_tensor : t -> bool
  val type_info : t -> TypeInfo.t
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

module InputOutputInfo : sig
  type t =
    { name : string
    ; element_type : Element_type.t
    ; dimensions : int array
    }
end

module Session : sig
  type t

  val create : Env.t -> SessionOptions.t -> model_path:string -> t
  val input_count : t -> int
  val output_count : t -> int
  val input_type_info : t -> int -> TypeInfo.t
  val output_type_info : t -> int -> TypeInfo.t
  val input_name : t -> int -> string
  val output_name : t -> int -> string
  val input_names : t -> string list
  val output_names : t -> string list
  val inputs : t -> InputOutputInfo.t list
  val outputs : t -> InputOutputInfo.t list
  val model_metadata : t -> ModelMetadata.t
  val run_1_1 : t -> Value.t -> input_name:string -> output_name:string -> Value.t
end

module SessionWithArgs : sig
  type t

  val create : Session.t -> input_names:string list -> output_names:string list -> t
  val run : t -> Value.t array -> Value.t array
end
