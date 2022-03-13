open! Base
open! Import
include Wrappers.SessionOptions

let create ?inter_op_num_threads ?intra_op_num_threads () =
  let t = create () in
  Option.iter inter_op_num_threads ~f:(fun threads ->
      set_inter_op_num_threads t ~threads:(Some threads));
  Option.iter intra_op_num_threads ~f:(fun threads ->
      set_intra_op_num_threads t ~threads:(Some threads));
  t
