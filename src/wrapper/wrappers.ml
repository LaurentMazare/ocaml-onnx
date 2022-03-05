open! Base
open! Import

let add_compact = false

let check_and_release_status status =
  if not (Ctypes.is_null status)
  then (
    let error_message = W.Status.error_message status in
    W.Status.release status;
    failwith error_message)

module type S = sig
  type t

  val t : t Ctypes.typ
  val release : t -> unit
end

let size_arr1 = Ctypes.CArray.make Ctypes.size_t 1
let int_arr1 = Ctypes.CArray.make Ctypes.int 1

let create (type a) (module M : S with type t = a Ctypes.ptr) create_fn =
  let arr = Ctypes.CArray.make M.t 1 in
  if add_compact then Caml.Gc.compact ();
  create_fn (Ctypes.CArray.start arr) |> check_and_release_status;
  let t = Ctypes.CArray.get arr 0 in
  if Ctypes.is_null t then failwith "function returned null despite ok status";
  Caml.Gc.finalise M.release t;
  t

module Env = struct
  type t = W.Env.t

  let create name = create (module W.Env) (fun ptr -> W.Env.create name ptr)
end

module SessionOptions = struct
  type t = W.SessionOptions.t

  let create () = create (module W.SessionOptions) W.SessionOptions.create
end

module TensorTypeAndShapeInfo = struct
  type t = W.TensorTypeAndShapeInfo.t

  let element_type t =
    W.TensorTypeAndShapeInfo.element_type t (Ctypes.CArray.start int_arr1)
    |> check_and_release_status;
    Ctypes.CArray.get int_arr1 0 |> Element_type.of_c_int

  let dimensions_count t =
    W.TensorTypeAndShapeInfo.dimensions_count t (Ctypes.CArray.start size_arr1)
    |> check_and_release_status;
    Ctypes.CArray.get size_arr1 0 |> Unsigned.Size_t.to_int

  let element_count t =
    W.TensorTypeAndShapeInfo.element_count t (Ctypes.CArray.start size_arr1)
    |> check_and_release_status;
    Ctypes.CArray.get size_arr1 0 |> Unsigned.Size_t.to_int

  let dimensions t =
    let dimensions_count = dimensions_count t in
    let dim_arr = Ctypes.CArray.make Ctypes.int64_t dimensions_count in
    W.TensorTypeAndShapeInfo.dimensions
      t
      (Ctypes.CArray.start dim_arr)
      (Unsigned.Size_t.of_int dimensions_count)
    |> check_and_release_status;
    Array.init dimensions_count ~f:(fun i ->
        Ctypes.CArray.get dim_arr i |> Int64.to_int_exn)
end

module Value = struct
  type t = W.Value.t

  let create_tensor element_type ~shape =
    let shape_len = Array.length shape in
    let shape =
      let ca = Ctypes.CArray.make Ctypes.int64_t shape_len in
      Array.iteri shape ~f:(fun i v -> Ctypes.CArray.set ca i (Int64.of_int v));
      ca
    in
    let t =
      let shape_len = Unsigned.Size_t.of_int shape_len in
      create
        (module W.Value)
        (fun ptr ->
          W.Value.create_tensor
            (Ctypes.CArray.start shape)
            shape_len
            (Element_type.to_c_int element_type)
            ptr)
    in
    keep_alive shape;
    t

  let is_tensor t =
    W.Value.is_tensor t (Ctypes.CArray.start int_arr1) |> check_and_release_status;
    Ctypes.CArray.get int_arr1 0 <> 0

  let tensor_type_and_shape t =
    create
      (module W.TensorTypeAndShapeInfo)
      (fun ptr -> W.Value.tensor_type_and_shape t ptr)

  let copy_from_bigarray t ba =
    (match Bigarray.Genarray.layout ba with
    | C_layout -> ()
    | _ -> .);
    if add_compact then Caml.Gc.compact ();
    W.Value.tensor_memcpy_of_ptr
      t
      (Ctypes.bigarray_start Ctypes.genarray ba |> Ctypes.to_voidp)
      (Bigarray.Genarray.size_in_bytes ba |> Unsigned.Size_t.of_int)
    |> check_and_release_status;
    keep_alive ba

  let copy_to_bigarray t ba =
    (match Bigarray.Genarray.layout ba with
    | C_layout -> ()
    | _ -> .);
    if add_compact then Caml.Gc.compact ();
    W.Value.tensor_memcpy_to_ptr
      t
      (Ctypes.bigarray_start Ctypes.genarray ba |> Ctypes.to_voidp)
      (Bigarray.Genarray.size_in_bytes ba |> Unsigned.Size_t.of_int)
    |> check_and_release_status;
    keep_alive ba

  let of_bigarray (type a b) (ba : (b, a, Bigarray.c_layout) Bigarray.Genarray.t) =
    let (element_type : Element_type.t) =
      match Bigarray.Genarray.kind ba with
      | Float32 -> Float
      | Float64 -> Double
      | Int8_signed -> Int8
      | Int8_unsigned -> UInt8
      | Int16_signed -> Int16
      | Int16_unsigned -> UInt16
      | Int32 -> Int32
      | Int64 -> Int64
      | _ -> Unknown
    in
    let t = create_tensor element_type ~shape:(Bigarray.Genarray.dims ba) in
    copy_from_bigarray t ba;
    t

  let to_bigarray (type a b) t (kind : (a, b) Bigarray.kind) =
    let tensor_type_and_shape = tensor_type_and_shape t in
    let dims = TensorTypeAndShapeInfo.dimensions tensor_type_and_shape in
    let (ba : (a, b, Bigarray.c_layout) Bigarray.Genarray.t) =
      match kind, TensorTypeAndShapeInfo.element_type tensor_type_and_shape with
      | Float32, Float -> Bigarray.Genarray.create kind C_layout dims
      | Float64, Double -> Bigarray.Genarray.create kind C_layout dims
      | Int64, Int64 -> Bigarray.Genarray.create kind C_layout dims
      | Int32, Int32 -> Bigarray.Genarray.create kind C_layout dims
      | _, et ->
        Printf.failwithf
          "unsupported element type or type mismatch, tensor type %s"
          (Element_type.to_string et)
          ()
    in
    copy_to_bigarray t ba;
    ba
end

module Session = struct
  type t = W.Session.t

  let run_1_1 t input_value ~input_name ~output_name =
    create
      (module W.Value)
      (fun ptr -> W.Session.run_1_1 t input_name output_name input_value ptr)

  let create env session_options ~model_path =
    let t =
      create
        (module W.Session)
        (fun ptr -> W.Session.create ptr env session_options model_path)
    in
    Caml.Gc.finalise
      (fun _ ->
        keep_alive env;
        keep_alive session_options)
      t;
    t

  let count t ~count_fn =
    count_fn t (Ctypes.CArray.start size_arr1) |> check_and_release_status;
    Ctypes.CArray.get size_arr1 0 |> Unsigned.Size_t.to_int

  let input_count t = count t ~count_fn:W.Session.input_count
  let output_count t = count t ~count_fn:W.Session.output_count
end
