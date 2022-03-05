open! Base
module W = Onnx.Wrappers

let () =
  Stdio.printf "Starting...\n%!";
  let env = W.Env.create "foo" in
  let model_path =
    let argv = Sys.get_argv () in
    if Array.length argv > 1 then argv.(1) else "tests/add_one.onnx"
  in
  let session_options = W.SessionOptions.create () in
  let session = W.Session.create env session_options ~model_path in
  Stdio.printf
    "%d %d\n%!"
    (W.Session.input_count session)
    (W.Session.output_count session);
  let ba = Bigarray.Array1.create Float32 C_layout 1 in
  ba.{0} <- 3.14159265358979;
  let input_tensor = Bigarray.genarray_of_array1 ba |> W.Value.of_bigarray in
  Stdio.printf "Running model...\n%!";
  let tensor =
    W.Session.run_1_1 session input_tensor ~input_name:"input" ~output_name:"output"
  in
  Stdio.printf "Running model done.\n%!";
  let type_and_shape = W.Value.tensor_type_and_shape tensor in
  let dim_count = W.TensorTypeAndShapeInfo.dimensions_count type_and_shape in
  let dims =
    W.TensorTypeAndShapeInfo.dimensions type_and_shape
    |> Array.to_list
    |> List.map ~f:Int.to_string
    |> String.concat ~sep:","
  in
  Stdio.printf
    "%b %d %d %s\n%!"
    (W.Value.is_tensor tensor)
    (W.TensorTypeAndShapeInfo.element_count type_and_shape)
    dim_count
    dims;
  Stdio.printf "Converting to bigarray...\n%!";
  let ba = W.Value.to_bigarray tensor Float32 |> Bigarray.array1_of_genarray in
  Stdio.printf "> %f\n%!" ba.{0}
