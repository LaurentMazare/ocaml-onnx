open! Base
module W = Onnx.Wrappers

let%expect_test _ =
  let env = W.Env.create "foo" in
  let session_options = W.SessionOptions.create () in
  let session = W.Session.create env session_options ~model_path:"add_one.onnx" in
  Stdio.printf "%d %d\n" (W.Session.input_count session) (W.Session.output_count session);
  [%expect {|
    1 1 |}];
  let ba = Bigarray.Array1.create Float32 C_layout 1 in
  ba.{0} <- 3.14159265358979;
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
  [%expect {|
    true 1 1 1 |}];
  let ba = W.Value.to_bigarray tensor |> Bigarray.array1_of_genarray in
  Stdio.printf "> %f\n%!" ba.{0};
  [%expect {|
    > 4.141593 |}]

let%expect_test _ =
  let tensor = W.Value.create_tensor ~shape:[| 42; 1337 |] in
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
