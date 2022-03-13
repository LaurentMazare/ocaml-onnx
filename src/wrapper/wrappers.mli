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
  val lookup_custom_map : t -> string -> string option

  (* None is returned when there is no metadata custom map. *)
  val custom_map_keys : t -> string list option
  val version : t -> Int64.t
end

module Value : sig
  type t

  val create_tensor : Element_type.t -> shape:int array -> t
  val is_tensor : t -> bool
  val type_info : t -> TypeInfo.t
  val tensor_type_and_shape : t -> TensorTypeAndShapeInfo.t
  val copy_from_bigarray : t -> (_, _, Bigarray.c_layout) Bigarray.Genarray.t -> unit
  val copy_to_bigarray : t -> (_, _, Bigarray.c_layout) Bigarray.Genarray.t -> unit
end

module SessionOptions : sig
  type t

  val create : unit -> t

  (* Use [threads:None] to use the default number of threads. *)
  val set_inter_op_num_threads : t -> threads:int option -> unit
  val set_intra_op_num_threads : t -> threads:int option -> unit
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
  val model_metadata : t -> ModelMetadata.t
  val run_1_1 : t -> Value.t -> input_name:string -> output_name:string -> Value.t
end

module SessionWithArgs : sig
  type t

  val create : Session.t -> input_names:string list -> output_names:string list -> t
  val run : t -> Value.t array -> Value.t array
end
