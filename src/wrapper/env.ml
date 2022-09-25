include Wrappers.Env

let default_env = lazy (create "ocaml-onnx")
let default () = Lazy.force default_env

let or_default = function
  | None -> default ()
  | Some t -> t

let create_session ?t ?inter_op_num_threads ?intra_op_num_threads ~model_path () =
  let t = or_default t in
  let session_options =
    Session_options.create ?inter_op_num_threads ?intra_op_num_threads ()
  in
  Session.create t session_options ~model_path
