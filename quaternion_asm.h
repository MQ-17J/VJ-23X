#pragma once
#include <immintrin.h>

#ifdef __cplusplus
namespace mq17j
{
    extern "C" {
#endif

        __declspec(align(64)) typedef struct _qscalars64 {
            double e0, e1, e2, e3;
        } qscalars64;

        //could do align(32), but keep 64 in case AVX-512 used in edge cases of stacked quaternions
        __declspec(align(64)) typedef union _quaternion64 {
            __m256d avx256;
            qscalars64 vals;
        } quaternion64;

        void quaternion_norm64_AVX2(const quaternion64 *q, double *result);
        void quaternion_mul64_AVX2(const quaternion64 *o1, const quaternion64 *o2, quaternion64 *result);
        void quaternion_div64_AVX2(const quaternion64 *q1, const quaternion64 *q2, quaternion64 *result);
        void quaternion_mul64s_AVX2(const quaternion64 *q, const double *d, quaternion64 *result); //scalar multiply
        void quaternion_div64s_AVX2(const quaternion64 *q, const double *d, quaternion64 *result); //scalar division
        void quaternion_add64_AVX2(const quaternion64 *q1, const quaternion64 *q2, quaternion64 *result);
        void quaternion_sub64_AVX2(const quaternion64 *q1, const quaternion64 *q2, quaternion64 *result);

#ifdef __cplusplus
    }
}
#endif
