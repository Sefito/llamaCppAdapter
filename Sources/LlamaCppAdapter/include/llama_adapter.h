#ifndef LLAMA_CPP_ADAPTER_H
#define LLAMA_CPP_ADAPTER_H

// This header provides the C interface for llama.cpp integration
// In a full implementation, this would include llama.h from llama.cpp
// and potentially provide wrapper functions for easier Swift interop

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

// Forward declarations for llama.cpp types
// In actual implementation, these would come from llama.h
typedef struct llama_model llama_model;
typedef struct llama_context llama_context;
typedef int32_t llama_token;

// Model parameters structure
typedef struct {
    int32_t n_gpu_layers;  // Number of layers to offload to GPU
    bool use_mmap;         // Use memory mapping
    bool use_mlock;        // Lock model in RAM
    int32_t n_threads;     // Number of threads
} llama_adapter_model_params;

// Context parameters structure
typedef struct {
    uint32_t n_ctx;        // Context size
    uint32_t n_batch;      // Batch size
    int32_t n_threads;     // Number of threads
    bool use_metal;        // Use Metal acceleration
} llama_adapter_context_params;

// Sampling parameters structure
typedef struct {
    float temperature;
    float top_p;
    int32_t top_k;
    int32_t n_predict;     // Max tokens to generate
} llama_adapter_sampling_params;

// Function declarations
// These would wrap or call llama.cpp functions

// Initialize backend
void llama_adapter_backend_init(bool use_numa);
void llama_adapter_backend_free(void);

// Model operations (placeholders - actual implementation would call llama.cpp)
// llama_model* llama_adapter_load_model(const char* path, llama_adapter_model_params params);
// void llama_adapter_free_model(llama_model* model);

// Context operations
// llama_context* llama_adapter_new_context(llama_model* model, llama_adapter_context_params params);
// void llama_adapter_free_context(llama_context* ctx);

// Tokenization
// int32_t llama_adapter_tokenize(llama_context* ctx, const char* text, llama_token* tokens, int32_t n_max_tokens, bool add_bos);
// const char* llama_adapter_token_to_str(llama_context* ctx, llama_token token);

// Inference
// int llama_adapter_eval(llama_context* ctx, llama_token* tokens, int32_t n_tokens, int32_t n_past);
// llama_token llama_adapter_sample_token(llama_context* ctx, llama_adapter_sampling_params params);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_CPP_ADAPTER_H
