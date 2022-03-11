open! Base
module W = Onnx.Wrappers

let%expect_test _ =
  let env = W.Env.create "foo" in
  let session_options = W.SessionOptions.create () in
  let session = W.Session.create env session_options ~model_path:"add_one.onnx" in
  Stdio.print_s
    [%message
      ""
        ~in_cnt:(W.Session.input_count session : int)
        ~out_cnt:(W.Session.output_count session : int)
        ~in_names:(W.Session.input_names session : string list)
        ~out_names:(W.Session.output_names session : string list)];
  [%expect {|
    ((in_cnt 1) (out_cnt 1) (in_names (input)) (out_names (output))) |}];
  let run_model
      (type a b)
      (kind : (a, b) Bigarray.kind)
      (v : a)
      ~(elt_to_string : a -> string)
    =
    let ba = Bigarray.Array1.create kind C_layout 1 in
    ba.{0} <- v;
    let input_tensor = Bigarray.genarray_of_array1 ba |> W.Value.of_bigarray in
    let tensor =
      W.Session.run_1_1 session input_tensor ~input_name:"input" ~output_name:"output"
    in
    let type_and_shape = W.Value.tensor_type_and_shape tensor in
    let ba = W.Value.to_bigarray tensor kind |> Bigarray.array1_of_genarray in
    Stdio.print_s
      [%message
        ""
          ~is_tensor:(W.Value.is_tensor tensor : bool)
          ~element_count:(W.TensorTypeAndShapeInfo.element_count type_and_shape : int)
          ~dim_count:(W.TensorTypeAndShapeInfo.dimensions_count type_and_shape : int)
          ~dims:(W.TensorTypeAndShapeInfo.dimensions type_and_shape : int array)
          (elt_to_string ba.{0})]
  in
  run_model Float32 3.14159265358979 ~elt_to_string:Float.to_string;
  (* run_model Float64 2.71828182846 ~elt_to_string:Float.to_string; *)
  [%expect
    {|
    ((is_tensor true) (element_count 1) (dim_count 1) (dims (1))
     4.1415929794311523) |}]

let%expect_test _ =
  let tensor = W.Value.create_tensor Int64 ~shape:[| 42; 1337 |] in
  let type_and_shape = W.Value.tensor_type_and_shape tensor in
  Stdio.print_s
    [%message
      ""
        ~is_tensor:(W.Value.is_tensor tensor : bool)
        ~element_count:(W.TensorTypeAndShapeInfo.element_count type_and_shape : int)
        ~dim_count:(W.TensorTypeAndShapeInfo.dimensions_count type_and_shape : int)
        ~dims:(W.TensorTypeAndShapeInfo.dimensions type_and_shape : int array)];
  [%expect
    {|
    ((is_tensor true) (element_count 56154) (dim_count 2) (dims (42 1337))) |}]

let%expect_test _ =
  let env = W.Env.create "foo" in
  let session_options = W.SessionOptions.create () in
  let session = W.Session.create env session_options ~model_path:"add_one.onnx" in
  let s =
    W.SessionWithArgs.create session ~input_names:[ "input" ] ~output_names:[ "output" ]
  in
  let ba = Bigarray.Array1.create Float32 C_layout 1 in
  ba.{0} <- 2.71828182846;
  let input_tensor = Bigarray.genarray_of_array1 ba |> W.Value.of_bigarray in
  match W.SessionWithArgs.run s [| input_tensor |] with
  | [| tensor |] ->
    let ba =
      W.Value.to_bigarray tensor Float32
      |> fun ba ->
      Bigarray.Genarray.change_layout ba Fortran_layout |> Bigarray.array1_of_genarray
    in
    Stdio.print_s (Sexplib.Conv.sexp_of_float32_vec ba);
    [%expect {|
    (3.7182817459106445) |}]
  | array ->
    Printf.failwithf "unexpected number of tensors from run %d" (Array.length array) ()

let%expect_test _ =
  let env = W.Env.create "foo" in
  let session_options = W.SessionOptions.create () in
  let session = W.Session.create env session_options ~model_path:"add_one.onnx" in
  let metadata = Onnx.Metadata.of_session session in
  Stdio.print_s
    [%message
      ""
        (W.Session.inputs session : W.InputOutputInfo.t list)
        (W.Session.outputs session : W.InputOutputInfo.t list)
        (metadata : Onnx.Metadata.t)];
  [%expect
    {|
    (("W.Session.inputs session"
      (((name input) (element_type Float) (dimensions (1)))))
     ("W.Session.outputs session"
      (((name output) (element_type Float) (dimensions (1)))))
     (metadata
      ((description "") (domain "") (graph_description "")
       (graph_name torch-jit-export) (producer_name pytorch)
       (version 9223372036854775807) (custom_map ())))) |}]
