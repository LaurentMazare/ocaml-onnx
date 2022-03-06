open! Base
module W = Onnx.Wrappers

(* Returns a tensor with float values between 0 and max_value. *)
val load_image
  :  ?resize:int * int
  -> ?use_batch_dim:bool
  -> ?channels:[ `hwc | `chw ]
  -> ?max_value:float
  -> string
  -> W.Value.t Or_error.t

(* Takes as input a tensor with float values between 0 and max_value. *)
val write_image
  :  ?channels:[ `hwc | `chw ]
  -> ?max_value:float
  -> W.Value.t
  -> string
  -> unit
