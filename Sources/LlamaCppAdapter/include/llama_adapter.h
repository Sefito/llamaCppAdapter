#ifndef LLAMA_CPP_ADAPTER_H
#define LLAMA_CPP_ADAPTER_H

// This header provides the C interface for llama.cpp integration
#include "llama.h"

#ifdef __cplusplus
extern "C" {
#endif

// Re-export llama.cpp types for easier access
// These are already defined in llama.h, but we provide convenient typedefs
typedef struct llama_model llama_model;
typedef struct llama_context llama_context;

#ifdef __cplusplus
}
#endif

#endif // LLAMA_CPP_ADAPTER_H
