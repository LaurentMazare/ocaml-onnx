open! Base
open! Onnx
module W = Onnx.Wrappers

type buffer = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

external resize_
  :  in_data:buffer
  -> in_w:int
  -> in_h:int
  -> out_data:buffer
  -> out_w:int
  -> out_h:int
  -> nchannels:int
  -> int
  = "ml_stbir_resize_bytecode" "ml_stbir_resize"

let load_image
    ?resize
    ?(use_batch_dim = true)
    ?(channels = `hwc)
    ?(max_value = 1.)
    image_file
  =
  let tensor_of_data ~data ~w ~h ~c =
    let ba = Bigarray.Array1.create Float32 C_layout (w * h * c) in
    let shape =
      let mult = max_value /. 256. in
      match channels with
      | `hwc ->
        for i = 0 to (w * h * c) - 1 do
          ba.{i} <- Float.of_int data.{i} *. mult
        done;
        [ h; w; c ]
      | `chw ->
        let stride = w * h in
        for i = 0 to stride - 1 do
          let i_times_c = i * c in
          for i_c = 0 to c - 1 do
            ba.{(i_c * stride) + i} <- Float.of_int data.{i_times_c + i_c} *. mult
          done
        done;
        [ c; h; w ]
    in
    let shape = if use_batch_dim then 1 :: shape else shape in
    let ba = Bigarray.reshape (Bigarray.genarray_of_array1 ba) (Array.of_list shape) in
    Ok (Value.of_bigarray ba)
  in
  match Stb_image.load image_file with
  | Ok (image : _ Stb_image.t) ->
    if image.channels = 3
    then (
      match resize with
      | None ->
        tensor_of_data ~data:image.data ~w:image.width ~h:image.height ~c:image.channels
      | Some (resize_width, resize_height) ->
        let out_data =
          Bigarray.Array1.create Int8_unsigned C_layout (resize_width * resize_height * 3)
        in
        let status =
          resize_
            ~in_data:image.data
            ~in_w:image.width
            ~in_h:image.height
            ~out_data
            ~out_w:resize_width
            ~out_h:resize_height
            ~nchannels:3
        in
        if status = 0
        then Or_error.errorf "error when resizing %s" image_file
        else
          tensor_of_data ~data:out_data ~w:resize_width ~h:resize_height ~c:image.channels)
    else Or_error.errorf "%d channels <> 3" image.channels
  | Error (`Msg msg) -> Or_error.error_string msg

let write_image ?(channels = `hwc) ?(max_value = 1.) tensor filename =
  let type_and_shape = Value.tensor_type_and_shape tensor in
  let dims = W.TensorTypeAndShapeInfo.dimensions type_and_shape in
  let w, h, c =
    match channels, dims with
    | `chw, [| c; h; w |] | `chw, [| 1; c; h; w |] -> w, h, c
    | `hwc, [| h; w; c |] | `hwc, [| 1; h; w; c |] -> w, h, c
    | _ ->
      let shape =
        Array.to_list dims |> List.map ~f:Int.to_string |> String.concat ~sep:","
      in
      Printf.failwithf "unexpected shape %s" shape ()
  in
  let tensor_ba = Value.to_bigarray tensor Float32 in
  let tensor_ba = Bigarray.reshape_1 tensor_ba (w * h * c) in
  let ba = Bigarray.Array1.create Int8_unsigned C_layout (w * h * c) in
  let mult = 256. /. max_value in
  (match channels with
  | `hwc ->
    for i = 0 to (w * h * c) - 1 do
      let v = Float.to_int (tensor_ba.{i} *. mult) in
      ba.{i} <- Int.max v 0 |> Int.min 255
    done
  | `chw ->
    let stride = w * h in
    for i_c = 0 to c - 1 do
      for i = 0 to stride - 1 do
        let v = Float.to_int (tensor_ba.{(i_c * stride) + i} *. mult) in
        ba.{(i * c) + i_c} <- Int.max v 0 |> Int.min 255
      done
    done);
  match String.rsplit2 filename ~on:'.' with
  | Some (_, "jpg") -> Stb_image_write.jpg filename ba ~w ~h ~c ~quality:90
  | Some (_, "tga") -> Stb_image_write.tga filename ba ~w ~h ~c
  | Some (_, "bmp") -> Stb_image_write.bmp filename ba ~w ~h ~c
  | Some (_, "png") -> Stb_image_write.png filename ba ~w ~h ~c
  | Some _ | None -> Stb_image_write.png (filename ^ ".png") ba ~w ~h ~c
