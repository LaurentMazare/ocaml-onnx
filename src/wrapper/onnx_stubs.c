#include "onnx_stubs.h"

const OrtApi* __g_ort = NULL;

const OrtApi* current_ort() {
  if (!__g_ort) {
    __g_ort = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    if (!__g_ort) {
      caml_failwith("failed to initialize the ONNX runtime engine");
    }
  }
  return __g_ort;
}

void release_status(OrtStatus *status) {
  current_ort()->ReleaseStatus(status);
}

char *status_get_error_message(OrtStatus *status) {
  const char* _msg = current_ort()->GetErrorMessage(status);
  return strdup(_msg);
}

void release_env(OrtEnv *env) {
  current_ort()->ReleaseEnv(env);
}

void release_session(OrtSession *session) {
  current_ort()->ReleaseSession(session);
}

void release_session_options(OrtSessionOptions *session_options) {
  current_ort()->ReleaseSessionOptions(session_options);
}

void release_value(OrtValue *value) {
  current_ort()->ReleaseValue(value);
}

void release_tensor_type_and_shape_info(OrtTensorTypeAndShapeInfo *v) {
  current_ort()->ReleaseTensorTypeAndShapeInfo(v);
}

OrtStatus* create_env(char *name, OrtEnv **env) {
  return current_ort()->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "ocaml-env", env);
}

OrtStatus* create_session_options(OrtSessionOptions **session_options) {
  return current_ort()->CreateSessionOptions(session_options);
}

OrtStatus* create_session(OrtSession **session, OrtEnv *env, OrtSessionOptions *session_options, char *model_path) {
  return current_ort()->CreateSession(env, model_path, session_options, session);
}

OrtStatus* session_get_input_count(OrtSession *session, size_t *value) {
  return current_ort()->SessionGetInputCount(session, value);
}

OrtStatus* session_get_output_count(OrtSession *session, size_t *value) {
  return current_ort()->SessionGetOutputCount(session, value);
}

OrtStatus* value_is_tensor(OrtValue *value, int *is_tensor) {
  return current_ort()->IsTensor(value, is_tensor);
}

OrtStatus* tensor_type_and_shape_info_get_dimensions_count(OrtTensorTypeAndShapeInfo *t, size_t *d) {
  return current_ort()->GetDimensionsCount(t, d);
}

OrtStatus* tensor_type_and_shape_info_get_tensor_shape_element_count(OrtTensorTypeAndShapeInfo *t, size_t *d) {
  return current_ort()->GetTensorShapeElementCount(t, d);
}

OrtStatus* tensor_type_and_shape_info_get_dimensions(OrtTensorTypeAndShapeInfo *t, int64_t *dim, size_t ndim) {
  return current_ort()->GetDimensions(t, dim, ndim);
}

OrtStatus* value_get_tensor_type_and_shape(OrtValue *t, OrtTensorTypeAndShapeInfo **u) {
  return current_ort()->GetTensorTypeAndShape(t, u);
}

OrtStatus* tensor_type_and_shape_info_get_tensor_element_type(OrtTensorTypeAndShapeInfo *t, int *u) {
  enum ONNXTensorElementDataType type_;
  OrtStatus * status = current_ort()->GetTensorElementType(t, &type_);
  if (status) return status;
  *u = -1;
  switch (type_) {
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UNDEFINED:
      *u = 0;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT:
      *u = 1;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT8:
      *u = 2;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT8:
      *u = 3;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT16:
      *u = 4;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT16:
      *u = 5;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32:
      *u = 6;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64:
      *u = 7;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_STRING:
      *u = 8;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_BOOL:
      *u = 9;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16:
      *u = 10;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_DOUBLE:
      *u = 11;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT32:
      *u = 12;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT64:
      *u = 13;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_COMPLEX64:
      *u = 14;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_COMPLEX128:
      *u = 15;
      break;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_BFLOAT16:
      *u = 16;
      break;
  }
  return NULL;
}

OrtStatus *create_tensor_with_data_as_ort_value(void *data, size_t data_len, int64_t *shape, size_t shape_len, OrtValue **v) {
  OrtMemoryInfo* memory_info;
  const OrtApi *g_ort = current_ort();

  OrtStatus *status = g_ort->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &memory_info);
  if (status) return status;
  status = g_ort->CreateTensorWithDataAsOrtValue(
                                                 memory_info,
                                                 data,
                                                 data_len,
                                                 shape,
                                                 shape_len,
                                                 // TODO: expose more types.
                                                 ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT,
                                                 v);
  g_ort->ReleaseMemoryInfo(memory_info);
  return status;
}

OrtStatus *create_tensor_as_ort_value(int64_t *shape, size_t shape_len, OrtValue **v) {
  const OrtApi *g_ort = current_ort();
  OrtAllocator* allocator;
  OrtStatus *status = g_ort->GetAllocatorWithDefaultOptions(&allocator);
  if (status) return status;
  return g_ort->CreateTensorAsOrtValue(
                                       allocator,
                                       shape,
                                       shape_len,
                                       ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT,
                                       v);
}

OrtStatus* session_run_1_1(OrtSession *s, char *iname, char *oname, OrtValue* i, OrtValue **o) {
  const OrtApi *g_ort = current_ort();
  const char* input_names[] = {iname};
  const char* output_names[] = {oname};
  *o = NULL;
  return g_ort->Run(s, NULL, input_names, (const OrtValue* const*)&i, 1, output_names, 1, o);
}

OrtStatus* value_tensor_memcpy_to_ptr(OrtValue *v, void *data, size_t data_len) {
  void* tensor_data;
  OrtStatus *status = current_ort()->GetTensorMutableData(v, &tensor_data);
  if (status) return status;
  memcpy(data, tensor_data, data_len);
  return NULL;
}

OrtStatus* value_tensor_memcpy_of_ptr(OrtValue *v, void *data, size_t data_len) {
  void* tensor_data;
  OrtStatus *status = current_ort()->GetTensorMutableData(v, &tensor_data);
  if (status) return status;
  memcpy(tensor_data, data, data_len);
  return NULL;
}
