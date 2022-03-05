# ocaml-onnx
OCaml ONNX runtime powered by [onnxruntime](https://onnxruntime.ai/).

This is an early prototype of bindings to the onnxruntime C library.
Only a small subset of the functions are available though it should
be enough to run basic models.

This has been tested with [release 1.10.0 of onnxruntime](https://github.com/microsoft/onnxruntime/releases/tag/v1.10.0).
To try it out, download the onnxruntime library, uncompress it in the
onnxruntime directory and run the following.

```bash
LIBONNXRUNTIME=onnxruntime dune runtest
```

Exporting a PyTorch model:
```python
import torch
import torch.nn as nn
import torch.nn.init as init

class AddOne(nn.Module):
    def __init__(self):
        super(AddOne, self).__init__()

    def forward(self, x):
        return x + 1

torch_model = AddOne()
x = torch.randn(1, requires_grad=True)
torch_out = torch_model(x)

torch.onnx.export(torch_model,               # model being run
                  x,                         # model input (or a tuple for multiple inputs)
                  "add_one.onnx",            # where to save the model (can be a file or file-like object)
                  export_params=True,        # store the trained parameter weights inside the model file
                  opset_version=10,          # the ONNX version to export the model to
                  do_constant_folding=True,  # whether to execute constant folding for optimization
                  input_names = ['input'],   # the model's input names
                  output_names = ['output'], # the model's output names
)
```
