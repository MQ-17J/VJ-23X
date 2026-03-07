// =================================================================================================================
//
//
// MMMMMMMM               MMMMMMMM     QQQQQQQQQ                         1111111   77777777777777777777    JJJJJJJJJJJ
// M:::::::M             M:::::::M   QQ:::::::::QQ                      1::::::1   7::::::::::::::::::7    J:::::::::J
// M::::::::M           M::::::::M QQ:::::::::::::QQ                   1:::::::1   7::::::::::::::::::7    J:::::::::J
// M:::::::::M         M:::::::::MQ:::::::QQQ:::::::Q                  111:::::1   777777777777:::::::7    JJ:::::::JJ
// M::::::::::M       M::::::::::MQ::::::O   Q::::::Q                     1::::1              7::::::7       J:::::J
// M:::::::::::M     M:::::::::::MQ:::::O     Q:::::Q                     1::::1             7::::::7        J:::::J
// M:::::::M::::M   M::::M:::::::MQ:::::O     Q:::::Q                     1::::1            7::::::7         J:::::J
// M::::::M M::::M M::::M M::::::MQ:::::O     Q:::::Q  ---------------    1::::l           7::::::7          J:::::j
// M::::::M  M::::M::::M  M::::::MQ:::::O     Q:::::Q  -:::::::::::::-    1::::l          7::::::7           J:::::J
// M::::::M   M:::::::M   M::::::MQ:::::O     Q:::::Q  ---------------    1::::l         7::::::7JJJJJJJ     J:::::J
// M::::::M    M:::::M    M::::::MQ:::::O  QQQQ:::::Q                     1::::l        7::::::7 J:::::J     J:::::J
// M::::::M     MMMMM     M::::::MQ::::::O Q::::::::Q                     1::::l       7::::::7  J::::::J   J::::::J
// M::::::M               M::::::MQ:::::::QQ::::::::Q                  111::::::111   7::::::7   J:::::::JJJ:::::::J
// M::::::M               M::::::M QQ::::::::::::::Q                   1::::::::::1  7::::::7     JJ:::::::::::::JJ
// M::::::M               M::::::M   QQ:::::::::::Q                    1::::::::::1 7::::::7        JJ:::::::::JJ
// MMMMMMMM               MMMMMMMM     QQQQQQQQ::::QQ                  11111111111177777777           JJJJJJJJJ
//                                             Q:::::Q
//                                              QQQQQQ
//
// =================================================================================================================
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
//
// name
//   octonion_asm.h
//
// description
//   header file for assembly octonion math with both AVX2 and AVX-512 versions
//
// platform
//   Windows x64
//
// version
//   1.0.0
//
// date created
//   2026-02-28
//
// author
//   MQ-17J
//
// notes
//
// change log
//   2026-02-28: created initial double versions of octonion primitives (mul, div, add, sub, norm)
//
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// =================================================================================================================

#pragma once

#include "common.h"
#include <immintrin.h>

#ifdef __cplusplus
namespace mq17j
{
    extern "C" {
#endif

        __declspec(align(64)) typedef struct _oscalars32 {
            float e0, e1, e2, e3, e4, e5, e6, e7;
        } oscalars32;

        __declspec(align(64)) typedef struct _oscalars64 {
            double e0, e1, e2, e3, e4, e5, e6, e7;
        } oscalars64;

        __declspec(align(64)) typedef union _octonion32 {
            __m512 avx512;
            __m256 avx256[2];
            oscalars32 vals;
        } octonion32;

        __declspec(align(64)) typedef union _octonion64 {
            __m512d avx512;
            __m256d avx256[2];
            oscalars64 vals;
        } octonion64;

        void octonion_norm64_AVX2(octonion64 *o1, double *result);
        void octonion_mul64_AVX2(octonion64 *o1, octonion64 *o2, octonion64 *result);
        void octonion_div64_AVX2(octonion64 *o1, octonion64 *o2, octonion64 *result);
        void octonion_mul64s_AVX2(octonion64 *o1, double *s, octonion64 *result);
        void octonion_div64s_AVX2(octonion64 *o1, double *s, octonion64 *result);
        void octonion_add64_AVX2(octonion64 *o1, octonion64 *o2, octonion64 *result);
        void octonion_sub64_AVX2(octonion64 *o1, octonion64 *o2, octonion64 *result);

        void octonion_norm64_AVX512(octonion64 *o1, double *result);
        void octonion_mul64_AVX512(octonion64 *o1, octonion64 *o2, octonion64 *result);
        void octonion_div64_AVX512(octonion64 *o1, octonion64 *o2, octonion64 *result);
        void octonion_mul64s_AVX512(octonion64 *o1, double *s, octonion64 *result);
        void octonion_div64s_AVX512(octonion64 *o1, double *s, octonion64 *result);
        void octonion_add64_AVX512(octonion64 *o1, octonion64 *o2, octonion64 *result);
        void octonion_sub64_AVX512(octonion64 *o1, octonion64 *o2, octonion64 *result);

#ifdef __cplusplus
    }
}
#endif
