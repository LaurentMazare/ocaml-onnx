type t = Wrappers.Env.t

val create : string -> t
val default : unit -> t

val create_session
  :  ?t:t
  -> ?inter_op_num_threads:int
  -> ?intra_op_num_threads:int
  -> model_path:string
  -> unit
  -> Session.t
