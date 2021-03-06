open! Base
open! Import
module CArray = Ctypes.CArray

let add_compact =
  match Sys.getenv "OCAML_ONNX_ADD_COMPACT" with
  | None | Some "false" | Some "0" -> false
  | Some _ -> true

let check_and_release_status status =
  if not (Ctypes.is_null status)
  then (
    let error_message = W.Status.error_message status in
    W.Status.release status;
    failwith error_message)

let get_string t ~on_null ~on_some ~fn =
  let ptr = Ctypes.(allocate_n (ptr char) ~count:1) in
  if add_compact then Caml.Gc.compact ();
  fn t ptr |> check_and_release_status;
  let ptr = Ctypes.( !@ ) ptr in
  if Ctypes.is_null ptr
  then on_null ()
  else (
    let rec loop acc ptr =
      let chr = Ctypes.( !@ ) ptr in
      if Char.to_int chr = 0 then acc else loop (chr :: acc) (Ctypes.( +@ ) ptr 1)
    in
    let name = loop [] ptr |> List.rev |> String.of_char_list in
    W.default_allocator_free (Ctypes.to_voidp ptr) |> check_and_release_status;
    on_some name)

let get_name t idx ~fn =
  get_string
    t
    ~on_some:Fn.id
    ~on_null:(fun () -> Printf.failwithf "returned null %d" idx ())
    ~fn:(fun t ptr -> fn t idx ptr)

module type S = sig
  type t

  val t : t Ctypes.typ
  val release : t -> unit
end

let size_arr1 = CArray.make Ctypes.size_t 1
let int_arr1 = CArray.make Ctypes.int 1

let create (type a) (module M : S with type t = a Ctypes.ptr) create_fn =
  let arr = CArray.make M.t 1 in
  if add_compact then Caml.Gc.compact ();
  create_fn (CArray.start arr) |> check_and_release_status;
  let t = CArray.get arr 0 in
  if Ctypes.is_null t then failwith "function returned null despite ok status";
  Caml.Gc.finalise M.release t;
  t

module Env = struct
  type t = W.Env.t

  let create name = create (module W.Env) (fun ptr -> W.Env.create name ptr)
end

module ModelMetadata = struct
  type t = W.ModelMetadata.t

  let lookup_custom_map t key =
    get_string
      t
      ~fn:(fun t -> W.ModelMetadata.lookup_custom_map t key)
      ~on_null:(fun () -> None)
      ~on_some:Option.some

  let custom_map_keys t =
    let ptr = Ctypes.(allocate_n (ptr (ptr char)) ~count:1) in
    let size_ptr = Ctypes.(allocate_n int64_t ~count:1) in
    if add_compact then Caml.Gc.compact ();
    W.ModelMetadata.custom_map_keys t ptr size_ptr |> check_and_release_status;
    let ptr = Ctypes.( !@ ) ptr in
    let size_ptr = Ctypes.( !@ ) size_ptr in
    if Ctypes.is_null ptr
    then None
    else (
      let rec loop acc ptr =
        let chr = Ctypes.( !@ ) ptr in
        if Char.to_int chr = 0 then acc else loop (chr :: acc) (Ctypes.( +@ ) ptr 1)
      in
      let names =
        List.init (Int64.to_int_exn size_ptr) ~f:(fun i ->
            let ptr = Ctypes.( !@ ) (Ctypes.( +@ ) ptr i) in
            let name = loop [] ptr |> List.rev |> String.of_char_list in
            W.default_allocator_free (Ctypes.to_voidp ptr) |> check_and_release_status;
            name)
      in
      W.default_allocator_free (Ctypes.to_voidp ptr) |> check_and_release_status;
      Some names)

  let get_string =
    get_string ~on_null:(fun () -> failwith "c function returned null") ~on_some:Fn.id

  let description t = get_string t ~fn:W.ModelMetadata.description
  let domain t = get_string t ~fn:W.ModelMetadata.domain
  let producer_name t = get_string t ~fn:W.ModelMetadata.producer_name
  let graph_description t = get_string t ~fn:W.ModelMetadata.graph_description
  let graph_name t = get_string t ~fn:W.ModelMetadata.graph_name

  let version t =
    let ptr = Ctypes.(allocate_n int64_t ~count:1) in
    W.ModelMetadata.version t ptr |> check_and_release_status;
    if Ctypes.is_null ptr then failwith "version returned null";
    Ctypes.( !@ ) ptr
end

module SessionOptions = struct
  type t = W.SessionOptions.t

  let create () = create (module W.SessionOptions) W.SessionOptions.create

  let set_inter_op_num_threads t ~threads =
    W.SessionOptions.set_inter_op_num_threads t (Option.value threads ~default:0)
    |> check_and_release_status;
    keep_alive t

  let set_intra_op_num_threads t ~threads =
    W.SessionOptions.set_intra_op_num_threads t (Option.value threads ~default:0)
    |> check_and_release_status;
    keep_alive t
end

module TypeInfo = struct
  type t = W.TypeInfo.t

  let cast_to_tensor_info t =
    let arr = CArray.make W.TensorTypeAndShapeInfo.t 1 in
    if add_compact then Caml.Gc.compact ();
    W.TypeInfo.cast_to_tensor_info t (CArray.start arr) |> check_and_release_status;
    let tensor_info = CArray.get arr 0 in
    if Ctypes.is_null t then failwith "function returned null despite ok status";
    (* When not null, [tensor_info] should not be freed and will be valid until [t] is
       released. *)
    Caml.Gc.finalise (fun _ -> keep_alive t) tensor_info;
    tensor_info
end

module TensorTypeAndShapeInfo = struct
  type t = W.TensorTypeAndShapeInfo.t

  let element_type t =
    W.TensorTypeAndShapeInfo.element_type t (CArray.start int_arr1)
    |> check_and_release_status;
    CArray.get int_arr1 0 |> Element_type.of_c_int

  let dimensions_count t =
    W.TensorTypeAndShapeInfo.dimensions_count t (CArray.start size_arr1)
    |> check_and_release_status;
    CArray.get size_arr1 0 |> Unsigned.Size_t.to_int

  let element_count t =
    W.TensorTypeAndShapeInfo.element_count t (CArray.start size_arr1)
    |> check_and_release_status;
    CArray.get size_arr1 0 |> Unsigned.Size_t.to_int

  let dimensions t =
    let dimensions_count = dimensions_count t in
    let dim_arr = CArray.make Ctypes.int64_t dimensions_count in
    W.TensorTypeAndShapeInfo.dimensions
      t
      (CArray.start dim_arr)
      (Unsigned.Size_t.of_int dimensions_count)
    |> check_and_release_status;
    Array.init dimensions_count ~f:(fun i -> CArray.get dim_arr i |> Int64.to_int_exn)
end

module Value = struct
  type t = W.Value.t

  let create_tensor element_type ~shape =
    let shape_len = Array.length shape in
    let shape =
      let ca = CArray.make Ctypes.int64_t shape_len in
      Array.iteri shape ~f:(fun i v -> CArray.set ca i (Int64.of_int v));
      ca
    in
    let t =
      let shape_len = Unsigned.Size_t.of_int shape_len in
      create
        (module W.Value)
        (fun ptr ->
          W.Value.create_tensor
            (CArray.start shape)
            shape_len
            (Element_type.to_c_int element_type)
            ptr)
    in
    keep_alive shape;
    t

  let is_tensor t =
    W.Value.is_tensor t (CArray.start int_arr1) |> check_and_release_status;
    CArray.get int_arr1 0 <> 0

  let type_info t = create (module W.TypeInfo) (fun ptr -> W.Value.type_info t ptr)

  let tensor_type_and_shape_ t =
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
end

module Session = struct
  type t = W.Session.t

  let model_metadata t =
    let model_metadata =
      create (module W.ModelMetadata) (fun ptr -> W.Session.model_metadata t ptr)
    in
    keep_alive t;
    model_metadata

  let input_type_info t idx =
    let type_info =
      create (module W.TypeInfo) (fun ptr -> W.Session.input_type_info t idx ptr)
    in
    keep_alive t;
    type_info

  let output_type_info t idx =
    let type_info =
      create (module W.TypeInfo) (fun ptr -> W.Session.output_type_info t idx ptr)
    in
    keep_alive t;
    type_info

  let run_1_1 t input_value ~input_name ~output_name =
    let output_value =
      create
        (module W.Value)
        (fun ptr -> W.Session.run_1_1 t input_name output_name input_value ptr)
    in
    keep_alive (t, input_value);
    output_value

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
    count_fn t (CArray.start size_arr1) |> check_and_release_status;
    CArray.get size_arr1 0 |> Unsigned.Size_t.to_int

  let input_count t = count t ~count_fn:W.Session.input_count
  let output_count t = count t ~count_fn:W.Session.output_count
  let input_name t idx = get_name t idx ~fn:W.Session.input_name
  let output_name t idx = get_name t idx ~fn:W.Session.output_name
  let input_names t = List.init (input_count t) ~f:(input_name t)
  let output_names t = List.init (output_count t) ~f:(output_name t)
end

module SessionWithArgs = struct
  (* TODO: Use some GADT to provide a nicer api without the need for list for small
     tuples? *)
  type t =
    { session : Session.t
    ; input_names : char CArray.t list
    ; output_names : char CArray.t list
    ; input_names_arr : char Ctypes.ptr CArray.t
    ; output_names_arr : char Ctypes.ptr CArray.t
    ; input_values : Value.t CArray.t
    ; output_values : Value.t CArray.t
    }

  let create session ~input_names ~output_names =
    let to_list names =
      List.map names ~f:(fun n -> String.to_list n |> CArray.of_list Ctypes.char)
    in
    let input_names = to_list input_names in
    let output_names = to_list output_names in
    let input_names_arr =
      List.map input_names ~f:CArray.start |> CArray.of_list Ctypes.(ptr char)
    in
    let output_names_arr =
      List.map output_names ~f:CArray.start |> CArray.of_list Ctypes.(ptr char)
    in
    { session
    ; input_names
    ; output_names
    ; input_names_arr
    ; output_names_arr
    ; input_values = CArray.make W.Value.t (CArray.length input_names_arr)
    ; output_values = CArray.make W.Value.t (CArray.length output_names_arr)
    }

  let run t input_values =
    let input_names_len = CArray.length t.input_names_arr in
    let output_names_len = CArray.length t.output_names_arr in
    if input_names_len <> Array.length input_values
    then
      Printf.failwithf
        "input len mismatch %d <> %d"
        (Array.length input_values)
        input_names_len
        ();
    Array.iteri input_values ~f:(fun i v -> CArray.set t.input_values i v);
    for i = 0 to CArray.length t.output_values - 1 do
      CArray.set t.output_values i (Ctypes.null |> Ctypes.from_voidp W.Value.struct_)
    done;
    let status =
      if add_compact then Caml.Gc.compact ();
      W.Session.run
        t.session
        (CArray.start t.input_names_arr)
        input_names_len
        (CArray.start t.output_names_arr)
        output_names_len
        (CArray.start t.input_values)
        (CArray.start t.output_values)
    in
    for i = 0 to CArray.length t.output_values - 1 do
      CArray.set t.input_values i (Ctypes.null |> Ctypes.from_voidp W.Value.struct_)
    done;
    check_and_release_status status;
    (* The elements in [input_values] need to be kept alive as [CArray.set] unwraps the
       fat pointer so a GC taking place just before [W.Session.run] would have a chance
       to collect/run the finalizer on the input values if they are not referred to
       after the call to [run]. *)
    keep_alive (t, input_values);
    Array.init (CArray.length t.output_values) ~f:(fun i ->
        let output_value = CArray.get t.output_values i in
        CArray.set t.output_values i (Ctypes.null |> Ctypes.from_voidp W.Value.struct_);
        if Ctypes.is_null output_value
        then failwith "run function returned null despite ok status";
        Caml.Gc.finalise W.Value.release output_value;
        output_value)
end
