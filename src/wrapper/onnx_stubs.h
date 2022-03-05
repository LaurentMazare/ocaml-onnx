#ifndef __OCAML_ONNX_RUNTIME_H__
#define __OCAML_ONNX_RUNTIME_H__

#include <caml/fail.h>

#include <onnxruntime_c_api.h>

OrtStatus* create_env(char *, OrtEnv **);
OrtStatus* create_session_options(OrtSessionOptions **);
OrtStatus* create_session(OrtSession **, OrtEnv *, OrtSessionOptions *, char *);
OrtStatus *create_tensor_with_data_as_ort_value(void *, size_t, int64_t *, size_t, OrtValue **);
OrtStatus *create_tensor_as_ort_value(int64_t *, size_t, OrtValue **);

char *status_get_error_message(OrtStatus *);
OrtStatus* session_get_input_count(OrtSession *, size_t *);
OrtStatus* session_get_output_count(OrtSession *, size_t *);
OrtStatus* session_run_1_1(OrtSession *, char *, char *, OrtValue*, OrtValue **);
OrtStatus* value_is_tensor(OrtValue *, int *);
OrtStatus* value_get_tensor_type_and_shape(OrtValue *, OrtTensorTypeAndShapeInfo **);
OrtStatus* value_tensor_memcpy_of_ptr(OrtValue *, void *, size_t);
OrtStatus* value_tensor_memcpy_to_ptr(OrtValue *, void *, size_t);
OrtStatus* tensor_type_and_shape_info_get_dimensions_count(OrtTensorTypeAndShapeInfo *, size_t *);
OrtStatus* tensor_type_and_shape_info_dimensions(OrtTensorTypeAndShapeInfo *, int *, int);
OrtStatus* tensor_type_and_shape_info_get_dimensions(OrtTensorTypeAndShapeInfo *, int64_t *, size_t);
OrtStatus* tensor_type_and_shape_info_get_tensor_element_type(OrtTensorTypeAndShapeInfo *, int *);
OrtStatus* tensor_type_and_shape_info_get_tensor_shape_element_count(OrtTensorTypeAndShapeInfo *, size_t *);

void release_status(OrtStatus *);
void release_env(OrtEnv *);
void release_session(OrtSession *);
void release_session_options(OrtSessionOptions *);
void release_value(OrtValue *);
void release_tensor_type_and_shape_info(OrtTensorTypeAndShapeInfo *);
#endif
