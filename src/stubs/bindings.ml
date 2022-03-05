open! Ctypes

module C (F : Cstubs.FOREIGN) = struct
  open! F

  module Status = struct
    type modl
    type struct_ = modl Ctypes.structure
    type t = struct_ ptr

    let struct_ : struct_ typ = structure "OrtStatus"
    let t : t typ = ptr struct_
    let error_message = foreign "status_get_error_message" (t @-> returning string)
    let release = foreign "release_status" (t @-> returning void)
  end

  module Env = struct
    type modl
    type struct_ = modl Ctypes.structure
    type t = struct_ ptr

    let struct_ : struct_ typ = structure "OrtEnv"
    let t : t typ = ptr struct_
    let create = foreign "create_env" (string @-> ptr t @-> returning Status.t)
    let release = foreign "release_env" (t @-> returning void)
  end

  module SessionOptions = struct
    type modl
    type struct_ = modl Ctypes.structure
    type t = struct_ ptr

    let struct_ : struct_ typ = structure "OrtSessionOptions"
    let t : t typ = ptr struct_
    let create = foreign "create_session_options" (ptr t @-> returning Status.t)
    let release = foreign "release_session_options" (t @-> returning void)
  end

  module TensorTypeAndShapeInfo = struct
    type modl
    type struct_ = modl Ctypes.structure
    type t = struct_ ptr

    let struct_ : struct_ typ = structure "OrtTensorTypeAndShapeInfo"
    let t : t typ = ptr struct_

    let dimensions_count =
      foreign
        "tensor_type_and_shape_info_get_dimensions_count"
        (t @-> ptr size_t @-> returning Status.t)

    let element_count =
      foreign
        "tensor_type_and_shape_info_get_tensor_shape_element_count"
        (t @-> ptr size_t @-> returning Status.t)

    let dimensions =
      foreign
        "tensor_type_and_shape_info_get_dimensions"
        (t @-> ptr int64_t @-> size_t @-> returning Status.t)

    let element_type =
      foreign
        "tensor_type_and_shape_info_get_tensor_element_type"
        (t @-> ptr int @-> returning Status.t)

    let release = foreign "release_tensor_type_and_shape_info" (t @-> returning void)
  end

  module Value = struct
    type modl
    type struct_ = modl Ctypes.structure
    type t = struct_ ptr

    let struct_ : struct_ typ = structure "OrtValue"
    let t : t typ = ptr struct_

    let create_tensor =
      foreign
        "create_tensor_as_ort_value"
        (ptr int64_t @-> size_t @-> int @-> ptr t @-> returning Status.t)

    let create_tensor_with_data =
      foreign
        "create_tensor_with_data_as_ort_value"
        (ptr void
        @-> size_t
        @-> ptr int64_t
        @-> size_t
        @-> int
        @-> ptr t
        @-> returning Status.t)

    let is_tensor = foreign "value_is_tensor" (t @-> ptr int @-> returning Status.t)

    let tensor_type_and_shape =
      foreign
        "value_get_tensor_type_and_shape"
        (t @-> ptr TensorTypeAndShapeInfo.t @-> returning Status.t)

    let tensor_memcpy_of_ptr =
      foreign
        "value_tensor_memcpy_of_ptr"
        (t @-> ptr void @-> size_t @-> returning Status.t)

    let tensor_memcpy_to_ptr =
      foreign
        "value_tensor_memcpy_to_ptr"
        (t @-> ptr void @-> size_t @-> returning Status.t)

    let release = foreign "release_value" (t @-> returning void)
  end

  module Session = struct
    type modl
    type struct_ = modl Ctypes.structure
    type t = struct_ ptr

    let struct_ : struct_ typ = structure "OrtSession"
    let t : t typ = ptr struct_

    let create =
      foreign
        "create_session"
        (ptr t @-> Env.t @-> SessionOptions.t @-> string @-> returning Status.t)

    let input_count =
      foreign "session_get_input_count" (t @-> ptr size_t @-> returning Status.t)

    let output_count =
      foreign "session_get_output_count" (t @-> ptr size_t @-> returning Status.t)

    let run_1_1 =
      foreign
        "session_run_1_1"
        (t @-> string @-> string @-> Value.t @-> ptr Value.t @-> returning Status.t)

    let run =
      foreign
        "session_run"
        (t
        @-> ptr (ptr char)
        @-> int
        @-> ptr (ptr char)
        @-> int
        @-> ptr Value.t
        @-> ptr Value.t
        @-> returning Status.t)

    let release = foreign "release_session" (t @-> returning void)
  end
end
