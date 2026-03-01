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

		typedef struct _scalars {
			double e0, e1, e2, e3, e4, e5, e6, e7;
			_scalars(double e0, double e1, double e2, double e3, double e4, double e5, double e6, double e7) {
				this->e0 = e0;
				this->e1 = e1;
				this->e2 = e2;
				this->e3 = e3;
				this->e4 = e4;
				this->e5 = e5;
				this->e6 = e6;
				this->e7 = e7;
			}
		} scalars;

		__declspec(align(64)) typedef union _octonion {
			__m512d avx512;
			__m256d avx256[2];
			scalars vals;

			_octonion(double e0, double e1, double e2, double e3, double e4, double e5, double e6, double e7) {
				this->vals.e0 = e0;
				this->vals.e1 = e1;
				this->vals.e2 = e2;
				this->vals.e3 = e3;
				this->vals.e4 = e4;
				this->vals.e5 = e5;
				this->vals.e6 = e6;
				this->vals.e7 = e7;
			}

			_octonion(__m256d q1, __m256d q2) {
				avx256[0] = q1;
				avx256[1] = q2;
			}
			_octonion(_octonion& o) {
				this->vals = o.vals;
			}
			_octonion(__m512d m512) : avx512(m512) {}
		} octonion;

		void octonion_mul64_AVX2(octonion* o1, octonion* o2, octonion* result);
		void octonion_div64_AVX2(octonion* o1, octonion* o2, octonion* result);
		void octonion_add64_AVX2(octonion* o1, octonion* o2, octonion* result);
		void octonion_sub64_AVX2(octonion* o1, octonion* o2, octonion* result);
		void octonion_norm64_AVX2(octonion* o1, double* result);

		void octonion_mul64_AVX512(octonion* o1, octonion* o2, octonion* result);
		void octonion_div64_AVX512(octonion* o1, octonion* o2, octonion* result);
		void octonion_add64_AVX512(octonion* o1, octonion* o2, octonion* result);
		void octonion_sub64_AVX512(octonion* o1, octonion* o2, octonion* result);
		void octonion_norm64_AVX512(octonion* o1, double* result);

#ifdef __cplusplus
	}
}
#endif
