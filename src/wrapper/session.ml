open! Base
open! Import
include Wrappers.Session

let inputs t =
  List.init (input_count t) ~f:(fun i ->
      let tensor_info = input_type_info t i |> Wrappers.TypeInfo.cast_to_tensor_info in
      { Input_output_info.name = input_name t i
      ; element_type = Wrappers.TensorTypeAndShapeInfo.element_type tensor_info
      ; dimensions = Wrappers.TensorTypeAndShapeInfo.dimensions tensor_info
      })

let outputs t =
  List.init (output_count t) ~f:(fun i ->
      let tensor_info = output_type_info t i |> Wrappers.TypeInfo.cast_to_tensor_info in
      { Input_output_info.name = output_name t i
      ; element_type = Wrappers.TensorTypeAndShapeInfo.element_type tensor_info
      ; dimensions = Wrappers.TensorTypeAndShapeInfo.dimensions tensor_info
      })
