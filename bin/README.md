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
