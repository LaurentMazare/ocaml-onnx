open! Base
module W = Onnx.Wrappers

let%expect_test _ =
  let env = W.Env.create "foo" in
  let session_options = W.SessionOptions.create () in
  let session = W.Session.create env session_options ~model_path:"add_one.onnx" in
  Stdio.printf "%d %d\n" (W.Session.input_count session) (W.Session.output_count session);
  let input_names = W.Session.input_names session |> String.concat ~sep:"|" in
  let output_names = W.Session.output_names session |> String.concat ~sep:"|" in
  Stdio.printf "%s %s\n" input_names output_names;
  [%expect {|
    1 1
    input output |}];
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
    let dim_count = W.TensorTypeAndShapeInfo.dimensions_count type_and_shape in
    let dims =
      W.TensorTypeAndShapeInfo.dimensions type_and_shape
      |> Array.to_list
      |> List.map ~f:Int.to_string
      |> String.concat ~sep:","
    in
    Stdio.printf
      "%b %d %d %s\n"
      (W.Value.is_tensor tensor)
      (W.TensorTypeAndShapeInfo.element_count type_and_shape)
      dim_count
      dims;
    let ba = W.Value.to_bigarray tensor kind |> Bigarray.array1_of_genarray in
    Stdio.printf "> %s\n%!" (elt_to_string ba.{0})
  in
  run_model Float32 3.14159265358979 ~elt_to_string:Float.to_string;
  (* run_model Float64 2.71828182846 ~elt_to_string:Float.to_string; *)
  [%expect {|
    true 1 1 1
    > 4.1415929794311523 |}]

let%expect_test _ =
  let tensor = W.Value.create_tensor Int64 ~shape:[| 42; 1337 |] in
  let type_and_shape = W.Value.tensor_type_and_shape tensor in
  let dim_count = W.TensorTypeAndShapeInfo.dimensions_count type_and_shape in
  let dims =
    W.TensorTypeAndShapeInfo.dimensions type_and_shape
    |> Array.to_list
    |> List.map ~f:Int.to_string
    |> String.concat ~sep:","
  in
  Stdio.printf "%b %d %s\n" (W.Value.is_tensor tensor) dim_count dims;
  [%expect {|
    true 2 42,1337 |}]

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
    let ba = W.Value.to_bigarray tensor Float32 |> Bigarray.array1_of_genarray in
    Stdio.printf "> %d %s\n%!" (Bigarray.Array1.dim ba) (Float.to_string ba.{0});
    [%expect {|
    > 1 3.7182817459106445 |}]
  | array ->
    Printf.failwithf "unexpected number of tensors from run %d" (Array.length array) ()

let input_output_info_to_string { W.InputOutputInfo.name; element_type; dimensions } =
  Printf.sprintf
    "(%s %s %s)"
    name
    (Onnx.Element_type.to_string element_type)
    (Array.to_list dimensions |> List.map ~f:Int.to_string |> String.concat ~sep:",")

let%expect_test _ =
  let env = W.Env.create "foo" in
  let session_options = W.SessionOptions.create () in
  let session = W.Session.create env session_options ~model_path:"add_one.onnx" in
  let inputs =
    W.Session.inputs session
    |> List.map ~f:input_output_info_to_string
    |> String.concat ~sep:","
  in
  let outputs =
    W.Session.outputs session
    |> List.map ~f:input_output_info_to_string
    |> String.concat ~sep:","
  in
  Stdio.printf "inputs:  %s\n" inputs;
  Stdio.printf "outputs: %s\n" outputs;
  [%expect {|
    inputs:  (input Float 1)
    outputs: (output Float 1) |}];
  let metadata = W.Session.model_metadata session in
  Stdio.printf "> %s\n%!" (W.ModelMetadata.description metadata);
  Stdio.printf "> %s\n%!" (W.ModelMetadata.domain metadata);
  Stdio.printf "> %s\n%!" (W.ModelMetadata.graph_description metadata);
  Stdio.printf "> %s\n%!" (W.ModelMetadata.graph_name metadata);
  Stdio.printf "> %s\n%!" (W.ModelMetadata.producer_name metadata);
  Stdio.printf "> %s\n%!" (W.ModelMetadata.version metadata |> Int64.to_string);
  [%expect {||}]
