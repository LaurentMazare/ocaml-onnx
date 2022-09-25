(* This is adapted from the onnxruntime example available here:
   https://github.com/microsoft/onnxruntime-inference-examples/blob/c9a65be0c649870a56b5d702d54b2b927de212e7/c_cxx/fns_candy_style_transfer/fns_candy_style_transfer.c
   A sample model file can be found here:
   https://raw.githubusercontent.com/microsoft/Windows-Machine-Learning/master/Samples/FNSCandyStyleTransfer/UWP/cs/Assets/candy.onnx
*)
open! Base
open! Onnx

let () =
  match Sys.get_argv () with
  | [| _bin; model_path; input_path; output_path |] ->
    let env = Env.create "ocaml-env" in
    let s = Session.create env (Session_options.create ()) ~model_path in
    let in_tensor =
      Onnx_image_helper.Image.load_image
        ~resize:(720, 720)
        ~channels:`chw
        ~max_value:256.
        ~use_batch_dim:true
        input_path
      |> Or_error.ok_exn
    in
    let out_tensor =
      Session.run_1_1 s in_tensor ~input_name:"inputImage" ~output_name:"outputImage"
    in
    Onnx_image_helper.Image.write_image
      ~max_value:256.
      ~channels:`chw
      out_tensor
      output_path
  | argv ->
    Stdio.eprintf "usage: %s model.onnx input.png output.png\n%!" argv.(0);
    Caml.exit 1
