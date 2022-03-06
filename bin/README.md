## Style Transfer Example

This example is based on the neural style transfer demo from the
[onnxruntime-inference-examples repo](https://github.com/microsoft/onnxruntime-inference-examples/tree/main/c_cxx/fns_candy_style_transfer).

In order to run this,
- Download the FNS Candy ONNX model from this
  [location](https://raw.githubusercontent.com/microsoft/Windows-Machine-Learning/master/Samples/FNSCandyStyleTransfer/UWP/cs/Assets/candy.onnx).
- Download the [onnxruntime C library](https://github.com/microsoft/onnxruntime/releases/tag/v1.10.0) for your architecture and
  uncompress it.
- Compile and run `style_transfer.exe` with `LIBONNXRUNTIME` set to the directory with the uncompressed runtime files.

E.g. for a linux/x86 box run the followings at the top level of this repo:
```bash
wget https://raw.githubusercontent.com/microsoft/Windows-Machine-Learning/master/Samples/FNSCandyStyleTransfer/UWP/cs/Assets/candy.onnx
wget https://github.com/microsoft/onnxruntime/releases/download/v1.10.0/onnxruntime-linux-x64-1.10.0.tgz
tar xzvf onnxruntime-linux-x64-1.10.0.tgz
LIBONNXRUNTIME=$PWD/onnxruntime-linux-x64-1.10.0 dune exec bin/style_transfer.exe ~/tmp/candy.onnx input.png output.png
```

The input image will be resized to 720x720 so you may want to make its aspect ratio square first.

The OCaml code for running this model is roughly as follows:
```bash
    let env = W.Env.create "ocaml-env" in
    let s = W.Session.create env (W.SessionOptions.create ()) ~model_path in
    let in_tensor = Onnx_image_helper.Image.load_image input_path |> Or_error.ok_exn in
    let out_tensor =
      W.Session.run_1_1 s in_tensor ~input_name:"inputImage" ~output_name:"outputImage"
    in
    Onnx_image_helper.Image.write_image out_tensor output_path
```

#![St Paul](https://raw.githubusercontent.com/LaurentMazare/ocaml-onnx/master/bin/stpaul.jpg)

#![Candy St Paul](https://raw.githubusercontent.com/LaurentMazare/ocaml-onnx/master/bin/stpaul-candy.jpg)
