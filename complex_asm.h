#pragma once
#include <immintrin.h>

#ifdef __cplusplus
namespace mq17j
{
    extern "C" {
#endif

        __declspec(align(32)) typedef struct _cscalars64 {
            double e0, e1;
        } cscalars64;

        //could do align(32)
        __declspec(align(64)) typedef union _complex64 {
            __m128d avx128;
            cscalars64 vals;
        } complex64;

        void complex_norm64_AVX2(const complex64 *c, double *result);
        void complex_mul64_AVX2(const complex64 *c1, const complex64 *c2, complex64 *result);
        void complex_div64_AVX2(const complex64 *c1, const complex64 *c2, complex64 *result);
        void complex_mul64s_AVX2(const complex64 *c, const double *d, complex64 *result); //scalar multiply
        void complex_div64s_AVX2(const complex64 *c, const double *d, complex64 *result); //scalar division
        void complex_add64_AVX2(const complex64 *c1, const complex64 *c2, complex64 *result);
        void complex_sub64_AVX2(const complex64 *c1, const complex64 *c2, complex64 *result);

#ifdef __cplusplus
    }
}
#endif
