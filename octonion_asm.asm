; =================================================================================================================
;
;
; MMMMMMMM               MMMMMMMM     QQQQQQQQQ                         1111111   77777777777777777777    JJJJJJJJJJJ
; M:::::::M             M:::::::M   QQ:::::::::QQ                      1::::::1   7::::::::::::::::::7    J:::::::::J
; M::::::::M           M::::::::M QQ:::::::::::::QQ                   1:::::::1   7::::::::::::::::::7    J:::::::::J
; M:::::::::M         M:::::::::MQ:::::::QQQ:::::::Q                  111:::::1   777777777777:::::::7    JJ:::::::JJ
; M::::::::::M       M::::::::::MQ::::::O   Q::::::Q                     1::::1              7::::::7       J:::::J
; M:::::::::::M     M:::::::::::MQ:::::O     Q:::::Q                     1::::1             7::::::7        J:::::J
; M:::::::M::::M   M::::M:::::::MQ:::::O     Q:::::Q                     1::::1            7::::::7         J:::::J
; M::::::M M::::M M::::M M::::::MQ:::::O     Q:::::Q  ---------------    1::::l           7::::::7          J:::::j
; M::::::M  M::::M::::M  M::::::MQ:::::O     Q:::::Q  -:::::::::::::-    1::::l          7::::::7           J:::::J
; M::::::M   M:::::::M   M::::::MQ:::::O     Q:::::Q  ---------------    1::::l         7::::::7JJJJJJJ     J:::::J
; M::::::M    M:::::M    M::::::MQ:::::O  QQQQ:::::Q                     1::::l        7::::::7 J:::::J     J:::::J
; M::::::M     MMMMM     M::::::MQ::::::O Q::::::::Q                     1::::l       7::::::7  J::::::J   J::::::J
; M::::::M               M::::::MQ:::::::QQ::::::::Q                  111::::::111   7::::::7   J:::::::JJJ:::::::J
; M::::::M               M::::::M QQ::::::::::::::Q                   1::::::::::1  7::::::7     JJ:::::::::::::JJ
; M::::::M               M::::::M   QQ:::::::::::Q                    1::::::::::1 7::::::7        JJ:::::::::JJ
; MMMMMMMM               MMMMMMMM     QQQQQQQQ::::QQ                  11111111111177777777           JJJJJJJJJ
;                                             Q:::::Q
;                                              QQQQQQ
;
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; name
;   octonion_asm.asm
;
; description
;   octonion math with both AVX2 and AVX-512 versions
;
; platform
;   Windows x64
;
; version
;   1.0.0
;
; date created
;   2026-02-28
;
; author
;   MQ-17J
;
; notes
;   this code expects proper data alignment as it uses aligned moves, you are warned. it also follows the
;   microsoft x64 ABI currently and does not use the shadow space. linux is on the radar.
;
; change log
;   2026-02-28: created initial double versions of octonion primitives (mul, div, add, sub, norm)
;
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; =================================================================================================================


; =================================================================================================================
; -----------------------------------------------------------------------------------------------------------------
;
; function naming conventions
;
; [object]_[funtionDATASIZE]_[technology]
;
; example:
; object = octonion
; function = add
; DATASIZE = sizeof(double) in C, or bits in a qword/float8 for asm
; technology = AVX2
; result: octonion_add64_AVX2
;
; example:
; object = octonion
; function = mul (short for multiply)
; DATASIZE = sizeof(float) in C, or bits in a dword/float4 for asm
; technology = AVX-512
; result: octonion_mul32_AVX512
;
; -----------------------------------------------------------------------------------------------------------------
; =================================================================================================================


; =================================================================================================================
; -----------------------------------------------------------------------------------------------------------------
;
; special reference
;
; VPERMPD ymm1, ymm2/m256, imm8
; Permute double precision floating-point elements in ymm2/m256 using indices in imm8 and store the result in ymm1
; -----------------------------------------------------------------------------------------------------------------
; VPERMPD (EVEX - imm8 control forms)
; (KL, VL) = (4, 256), (8, 512)
; FOR j := 0 TO KL-1
;     i := j * 64
;     IF (EVEX.b = 1) AND (SRC *is memory*)
;         THEN TMP_SRC[i+63:i] := SRC[63:0];
;         ELSE TMP_SRC[i+63:i] := SRC[i+63:i];
;     FI;
; ENDFOR;
; TMP_DEST[63:0] := (TMP_SRC[256:0] >> (IMM8[1:0] * 64))[63:0];
; TMP_DEST[127:64] := (TMP_SRC[256:0] >> (IMM8[3:2] * 64))[63:0];
; TMP_DEST[191:128] := (TMP_SRC[256:0] >> (IMM8[5:4] * 64))[63:0];
; TMP_DEST[255:192] := (TMP_SRC[256:0] >> (IMM8[7:6] * 64))[63:0];
; IF VL >= 512
;     TMP_DEST[319:256] := (TMP_SRC[511:256] >> (IMM8[1:0] * 64))[63:0];
;     TMP_DEST[383:320] := (TMP_SRC[511:256] >> (IMM8[3:2] * 64))[63:0];
;     TMP_DEST[447:384] := (TMP_SRC[511:256] >> (IMM8[5:4] * 64))[63:0];
;     TMP_DEST[511:448] := (TMP_SRC[511:256] >> (IMM8[7:6] * 64))[63:0];
; FI;
; FOR j := 0 TO KL-1
;     i := j * 64
;     IF k1[j] OR *no writemask*
;         THEN DEST[i+63:i] := TMP_DEST[i+63:i]
;     ELSE
;         IF *merging-masking* ; merging-masking
;             THEN *DEST[i+63:i] remains unchanged*
;         ELSE ; zeroing-masking
;             DEST[i+63:i] := 0 ;zeroing-masking
;         FI;
;     FI;
; ENDFOR
; DEST[MAXVL-1:VL] := 0
;
; -----------------------------------------------------------------------------------------------------------------
; windows ABI
;
; Register                Status      Use
; RAX                     Volatile    Return value register
; RCX                     Volatile    First integer argument
; RDX                     Volatile    Second integer argument
; R8                      Volatile    Third integer argument
; R9                      Volatile    Fourth integer argument
; R10:R11	              Volatile    Must be preserved as needed by caller; used in syscall/sysret instructions
; R12:R15	              Nonvolatile Must be preserved by callee
; RDI                     Nonvolatile Must be preserved by callee
; RSI                     Nonvolatile Must be preserved by callee
; RBX                     Nonvolatile Must be preserved by callee
; RBP                     Nonvolatile May be used as a frame pointer; must be preserved by callee
; RSP                     Nonvolatile Stack pointer
; XMM0, YMM0              Volatile    First FP argument; first vector-type argument when __vectorcall is used
; XMM1, YMM1              Volatile    Second FP argument; second vector-type argument when __vectorcall is used
; XMM2, YMM2              Volatile    Third FP argument; third vector-type argument when __vectorcall is used
; XMM3, YMM3              Volatile    Fourth FP argument; fourth vector-type argument when __vectorcall is used
; XMM4, YMM4              Volatile    Must be preserved as needed by caller; fifth vector-type argument when __vectorcall is used
; XMM5, YMM5              Volatile    Must be preserved as needed by caller; sixth vector-type argument when __vectorcall is used
; XMM6:XMM15, YMM6:YMM15  Nonvolatile (XMM), Volatile (upper half of YMM)	Must be preserved by callee. YMM registers must be preserved as needed by caller.
;
; The x64 ABI considers the registers RAX, RCX, RDX, R8, R9, R10, R11, and XMM0-XMM5 volatile. When present, the upper portions of YMM0-YMM15 and ZMM0-ZMM15
; are also volatile. On AVX512VL, the ZMM, YMM, and XMM registers 16-31 are also volatile. When AMX support is present, the TMM tile registers are volatile.
; The x64 ABI considers registers RBX, RBP, RDI, RSI, RSP, R12, R13, R14, R15, and XMM6-XMM15 nonvolatile. They must be saved and restored by a function that
; uses them.
; -----------------------------------------------------------------------------------------------------------------
; =================================================================================================================


; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; includes
;
include asm_data.inc
;
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; file level data declarations
;

.data

;
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================
;
;
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; code begins
;
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; =================================================================================================================

.code

; =================================================================================================================
; =================================================================================================================
; AVX2
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


; =================================================================================================================
; octonion double precision normal AVX2
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math
;   result = e0*e0 + e1*e1 + e2*e2 + e3*e3 + e4*e4 + e5*e5 + e6*e6 + e7*e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;   2026-03-15 increased efficiency here after implementing a better algo for sedenions
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_norm64_AVX2(octonion64 *o1, double *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_norm64_AVX2
octonion_norm64_AVX2 proc
    vmovapd      ymm0, ymmword ptr [rcx]                   ; ymm0 = o1e0, o1e1, o1e2, o1e3
    vmovapd      ymm1, ymmword ptr [rcx+32]                ; ymm1 = o1e4, o1e5, o1e6, o1e7
    vmulpd       ymm0, ymm0, ymm0                          ; ymm0 = o1e0*o1e0, o1e1*o1e1, o1e2*o1e2, o1e3*o1e3
    vfmadd231pd  ymm0, ymm1, ymm1                          ; ymm0 = o1e0*o1e0+o1e4*o1e4, o1e1*o1e1+o1e5*o1e5, o1e2*o1e2+o1e6*o1e6, o1e3*o1e3+o1e7*o1e7
    vextractf128 xmm1, ymm0, 1                             ; ymm1 = o1e2*o1e2+o1e6*o1e6, o1e3*o1e3+o1e7*o1e7
    vaddpd       xmm0, xmm0, xmm1                          ; xmm0 = o1e0*o1e0+o1e4*o1e4+o1e2*o1e2+o1e6*o1e6, o1e1*o1e1+o1e5*o1e5+o1e3*o1e3+o1e7*o1e7
    vshufpd      xmm1, xmm0, xmm0, 1                       ; xmm1 = o1e1*o1e1+o1e5*o1e5+o1e3*o1e3+o1e7*o1e7, o1e0*o1e0+o1e4*o1e4+o1e2*o1e2+o1e6*o1e6
    vaddpd       xmm0, xmm0, xmm1                          ; xmm0 = o1e0*o1e0+o1e4*o1e4+o1e2*o1e2+o1e6*o1e6+o1e1*o1e1+o1e5*o1e5+o1e3*o1e3+o1e7*o1e7, o1e1*o1e1+o1e5*o1e5+o1e3*o1e3+o1e7*o1e7+o1e0*o1e0+o1e4*o1e4+o1e2*o1e2+o1e6*o1e6
    vmovsd       qword ptr [rdx], xmm0                     ; result = xmm0
    ret
octonion_norm64_AVX2 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================

; =================================================================================================================
; octonion double precision multiplication AVX2
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math
; h0          h1          h2          h3          h4          h5          h6          h7
; o1e0*o2e0 - o1e1*o2e1 - o1e2*o2e2 - o1e3*o2e3 - o1e4*o2e4 - o1e5*o2e5 - o1e6*o2e6 - o1e7*o2e7 -> o3e0
; o1e0*o2e1 + o1e1*o2e0 + o1e2*o2e3 - o1e3*o2e2 + o1e4*o2e5 - o1e5*o2e4 - o1e6*o2e7 + o1e7*o2e6 -> o3e1
; o1e0*o2e2 - o1e1*o2e3 + o1e2*o2e0 + o1e3*o2e1 + o1e4*o2e6 + o1e5*o2e7 - o1e6*o2e4 - o1e7*o2e5 -> o3e2
; o1e0*o2e3 + o1e1*o2e2 - o1e2*o2e1 + o1e3*o2e0 + o1e4*o2e7 - o1e5*o2e6 + o1e6*o2e5 - o1e7*o2e4 -> o3e3
; h8          h9          ha          hb          hc          hd          he          hf
; o1e0*o2e4 - o1e1*o2e5 - o1e2*o2e6 - o1e3*o2e7 + o1e4*o2e0 + o1e5*o2e1 + o1e6*o2e2 + o1e7*o2e3 -> o3e4
; o1e0*o2e5 + o1e1*o2e4 - o1e2*o2e7 + o1e3*o2e6 - o1e4*o2e1 + o1e5*o2e0 - o1e6*o2e3 + o1e7*o2e2 -> o3e5
; o1e0*o2e6 + o1e1*o2e7 + o1e2*o2e4 - o1e3*o2e5 - o1e4*o2e2 + o1e5*o2e3 + o1e6*o2e0 - o1e7*o2e1 -> o3e6
; o1e0*o2e7 - o1e1*o2e6 + o1e2*o2e5 + o1e3*o2e4 - o1e4*o2e3 - o1e5*o2e2 + o1e6*o2e1 + o1e7*o2e0 -> o3e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_mul64_AVX2(octonion64 *o1, octonion64 *o2, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_mul64_AVX2
octonion_mul64_AVX2 proc
    vinsertf128  ymm10, ymm10, xmm6, 1                     ; save non-volatile lower 128 bits of xmm6 into volatile upper 128 bits of ymm10
    vinsertf128  ymm11, ymm11, xmm7, 1                     ; save non-volatile lower 128 bits of xmm7 into volatile upper 128 bits of ymm11
    vinsertf128  ymm12, ymm12, xmm8, 1                     ; save non-volatile lower 128 bits of xmm8 into volatile upper 128 bits of ymm12
    vinsertf128  ymm13, ymm13, xmm9, 1                     ; save non-volatile lower 128 bits of xmm9 into volatile upper 128 bits of ymm13
    lea          rax, [h0]                                 ; load address of mul mask
    ;vxorpd       ymm8, ymm8, ymm8                          ; zero accumulator high part (commented out for optimize)
    ;vxorpd       ymm9, ymm9, ymm9                          ; zero accumulator low part (commented out for optimize)
    vmovapd      ymm0, ymmword ptr [rcx]                   ; load oct1[high_half]
    vmovapd      ymm1, ymmword ptr [rcx+32]                ; load oct1[low_half]
    vmovapd      ymm2, ymmword ptr [rdx]                   ; load oct2[high_half]
    vmovapd      ymm3, ymmword ptr [rdx+32]                ; load oct2[low_half]
    ; e0 column
    vpermpd      ymm4, ymm0, 00000000b                     ; ymm4 = o1e0, o1e0, o1e0, o1e0
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e0, o1e0, o1e0, o1e0
    vpermpd      ymm6, ymm2, 11100100b                     ; ymm6 = o2e0, o2e1, o2e2, o2e3
    vpermpd      ymm7, ymm3, 11100100b                     ; ymm7 = o2e4, o2e5, o2e6, o2e7
    vmulpd       ymm8, ymm6, ymm4                          ; ymm4 = o1e0*o2e0, o1e0*o2e1, o1e0*o2e2, o1e0*o2e3
    vmulpd       ymm9, ymm7, ymm5                          ; ymm5 = o1e0*o2e4, o1e0*o2e5, o1e0*o2e6, o1e0*o2e7
    ;vfmadd231pd  ymm8, ymm4, ymmword ptr [rax]             ; multiply by mask and add to accumulator (commented out for optimize)
    ;vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+32]          ; multiply by mask and add to accumulator (commented out for optimize)
    ; e1 column
    vpermpd      ymm4, ymm0, 01010101b                     ; ymm4 = o1e1, o1e1, o1e1, o1e1
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e1, o1e1, o1e1, o1e1
    vpermpd      ymm6, ymm2, 10110001b                     ; ymm6 = o2e1, o2e0, o2e3, o2e2
    vpermpd      ymm7, ymm3, 10110001b                     ; ymm7 = o2e5, o2e4, o2e7, o2e6
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e1*o2e1, o1e1*o2e0, o1e1*o2e3, o1e1*o2e2
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e1*o2e5, o1e1*o2e4, o1e1*o2e7, o1e1*o2e6
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+64]          ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+96]          ; multiply by mask and add to accumulator
    ; e2 column
    vpermpd      ymm4, ymm0, 10101010b                     ; ymm4 = o1e2, o1e2, o1e2, o1e2
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e2, o1e2, o1e2, o1e2
    vpermpd      ymm6, ymm2, 01001110b                     ; ymm6 = o2e2, o2e3, o2e0, o2e1
    vpermpd      ymm7, ymm3, 01001110b                     ; ymm7 = o2e6, o2e7, o2e4, o2e5
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e2*o2e2, o1e2*o2e3, o1e2*o2e0, o1e2*o2e1
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e2*o2e6, o1e2*o2e7, o1e2*o2e4, o1e2*o2e5
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+128]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+160]         ; multiply by mask and add to accumulator
    ; e3 column
    vpermpd      ymm4, ymm0, 11111111b                     ; ymm4 = o1e3, o1e3, o1e3, o1e3
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e3, o1e3, o1e3, o1e3
    vpermpd      ymm6, ymm2, 00011011b                     ; ymm6 = o2e3, o2e2, o2e1, o2e0
    vpermpd      ymm7, ymm3, 00011011b                     ; ymm7 = o2e7, o2e6, o2e5, o2e4
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e3*o2e3, o1e3*o2e2, o1e3*o2e1, o1e3*o2e0
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e3*o2e7, o1e3*o2e6, o1e3*o2e5, o1e3*o2e4
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+192]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+224]         ; multiply by mask and add to accumulator
    ; e4 column
    vpermpd      ymm4, ymm1, 00000000b                     ; ymm4 = o1e4, o1e4, o1e4, o1e4
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e4, o1e4, o1e4, o1e4
    vpermpd      ymm6, ymm3, 11100100b                     ; ymm6 = o2e4, o2e5, o2e6, o2e7
    vpermpd      ymm7, ymm2, 11100100b                     ; ymm7 = o2e0, o2e1, o2e2, o2e3
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e4*o2e4, o1e4*o2e5, o1e4*o2e6, o1e4*o2e7
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e4*o2e0, o1e4*o2e1, o1e4*o2e2, o1e4*o2e3
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+256]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+288]         ; multiply by mask and add to accumulator
    ; e5 column
    vpermpd      ymm4, ymm1, 01010101b                     ; ymm4 = o1e5, o1e5, o1e5, o1e5
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e5, o1e5, o1e5, o1e5
    vpermpd      ymm6, ymm3, 10110001b                     ; ymm6 = o2e5, o2e4, o2e7, o2e6
    vpermpd      ymm7, ymm2, 10110001b                     ; ymm7 = o2e1, o2e0, o2e3, o2e2
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e5*o2e5, o1e5*o2e4, o1e5*o2e7, o1e5*o2e6
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e5*o2e1, o1e5*o2e0, o11k*o2e3, o1e5*o2e2
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+320]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+352]         ; multiply by mask and add to accumulator
    ; e6 column
    vpermpd      ymm4, ymm1, 10101010b                     ; ymm4 = o1e6, o1e6, o1e6, o1e6
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e6, o1e6, o1e6, o1e6
    vpermpd      ymm6, ymm3, 01001110b                     ; ymm6 = o2e6, o2e7, o2e4, o2e5
    vpermpd      ymm7, ymm2, 01001110b                     ; ymm7 = o2e2, o2e3, o2e0, o2e1
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e6*o2e6, o1e6*o2e7, o1e6*o2e4, o1e6*o2e5
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e6*o2e2, o1e6*o2e3, o1e6*o2e0, o1e6*o2e1
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+384]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+416]         ; multiply by mask and add to accumulator
    ; e7 column
    vpermpd      ymm4, ymm1, 11111111b                     ; ymm4 = o1e7, o1e7, o1e7, o1e7
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e7, o1e7, o1e7, o1e7
    vpermpd      ymm6, ymm3, 00011011b                     ; ymm6 = o2e7, o2e6, o2e5, o2e4
    vpermpd      ymm7, ymm2, 00011011b                     ; ymm7 = o2e3, o2e2, o2e1, o2e0
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e7*o2e7, o1e7*o2e6, o1e7*o2e5, o1e7*o2e4
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e7*o2e3, o1e7*o2e2, o1e7*o2e1, o1e7*o2e0
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+448]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+480]         ; multiply by mask and add to accumulator
    vmovapd      ymmword ptr [r8], ymm8                    ; return low quaternion of octonion result
    vmovapd      ymmword ptr [r8+32], ymm9                 ; return high quaternion of octonion result
    vextractf128 xmm6, ymm10, 1                            ; restore non-volatile lower 128 bits of xmm6 from volatile upper 128 bits of ymm10
    vextractf128 xmm7, ymm11, 1                            ; restore non-volatile lower 128 bits of xmm7 from volatile upper 128 bits of ymm11
    vextractf128 xmm8, ymm12, 1                            ; restore non-volatile lower 128 bits of xmm8 from volatile upper 128 bits of ymm12
    vextractf128 xmm9, ymm13, 1                            ; restore non-volatile lower 128 bits of xmm9 from volatile upper 128 bits of ymm13
    ret
octonion_mul64_AVX2 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision division AVX2
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
;   o2norm = e0*e0 + e1*e1 + e2*e2 + e3*e3 + e4*e4 + e5*e5 + e6*e6 + e7*e7
;
;     t0          t1          t2          t3          t4          t5          t6          t7
;	( o1e0*o2e0 + o1e1*o2e1 + o1e2*o2e2 + o1e3*o2e3 + o1e4*o2e4 + o1e5*o2e5 + o1e6*o2e6 + o1e7*o2e7) / o2norm -> e0
;	(-o1e0*o2e1 + o1w1*o2e0 - o1e2*o2e3 + o1e3*o2e2 - o1e4*o2e5 + o1e5*o2e4 + o1e6*o2e7 - o1e7*o2e6) / o2norm -> e1
;	(-o1e0*o2e2 + o1e1*o2e3 + o1e2*o2e0 - o1e3*o2e1 - o1e4*o2e6 - o1e5*o2e7 + o1e6*o2e4 + o1e7*o2e5) / o2norm -> e2
;	(-o1e0*o2e3 - o1e1*o2e2 + o1e2*o2e1 + o1e3*o2e0 - o1e4*o2e7 + o1e5*o2e6 - o1e6*o2e5 + o1e7*o2e4) / o2norm -> e3
;     t8          t9          ta          tb          tc          td          te          tf
;	(-o1e0*o2e4 + o1e1*o2e5 + o1e2*o2e6 + o1e3*o2e7 + o1e4*o2e0 - o1e5*o2e1 - o1e6*o2e2 - o1e7*o2e3) / o2norm -> e4
;	(-o1e0*o2e5 - o1e1*o2e4 + o1e2*o2e7 - o1e3*o2e6 + o1e4*o2e1 + o1e5*o2e0 + o1e6*o2e3 - o1e7*o2e2) / o2norm -> e5
;	(-o1e0*o2e6 - o1e1*o2e7 - o1e2*o2e4 + o1e3*o2e5 + o1e4*o2e2 - o1e5*o2e3 + o1e6*o2e0 + o1e7*o2e1) / o2norm -> e6
;	(-o1e0*o2e7 + o1e1*o2e6 - o1e2*o2e5 - o1e3*o2e4 + o1e4*o2e3 + o1e5*o2e2 - o1e6*o2e1 + o1e7*o2e0) / o2norm -> e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_div64_AVX2(octonion64 *o1, octonion64 *o2, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_div64_AVX2
octonion_div64_AVX2 proc
    vinsertf128  ymm10, ymm10, xmm6, 1                     ; save non-volatile lower 128 bits of xmm6 into volatile upper 128 bits of ymm10
    vinsertf128  ymm11, ymm11, xmm7, 1                     ; save non-volatile lower 128 bits of xmm7 into volatile upper 128 bits of ymm11
    vinsertf128  ymm12, ymm12, xmm8, 1                     ; save non-volatile lower 128 bits of xmm8 into volatile upper 128 bits of ymm12
    vinsertf128  ymm13, ymm13, xmm9, 1                     ; save non-volatile lower 128 bits of xmm9 into volatile upper 128 bits of ymm13
    vinsertf128  ymm14, ymm14, xmm10, 1                    ; save non-volatile lower 128 bits of xmm10 into volatile upper 128 bits of ymm14
    vmovapd      ymm0, ymmword ptr [rdx]
    vmovapd      ymm1, ymmword ptr [rdx+32]
    vmovapd      ymm5, ymm0                                ; save for later
    vmovapd      ymm6, ymm1                                ; ditto
    vmulpd       ymm0, ymm0, ymm0                          ; ymm0 = o1e0*o1e0, o1e1*o1e1, o1e2*o1e2, o1e3*o1e3
    vfmadd231pd  ymm0, ymm1, ymm1                          ; ymm0 = o1e0*o1e0+o1e4*o1e4, o1e1*o1e1+o1e5*o1e5, o1e2*o1e2+o1e6*o1e6, o1e3*o1e3+o1e7*o1e7
    vextractf128 xmm1, ymm0, 1                             ; ymm1 = o1e2*o1e2+o1e6*o1e6, o1e3*o1e3+o1e7*o1e7
    vaddpd       xmm0, xmm0, xmm1                          ; xmm0 = o1e0*o1e0+o1e4*o1e4+o1e2*o1e2+o1e6*o1e6, o1e1*o1e1+o1e5*o1e5+o1e3*o1e3+o1e7*o1e7
    vshufpd      xmm1, xmm0, xmm0, 1                       ; xmm1 = o1e1*o1e1+o1e5*o1e5+o1e3*o1e3+o1e7*o1e7, o1e0*o1e0+o1e4*o1e4+o1e2*o1e2+o1e6*o1e6
    vaddpd       xmm0, xmm0, xmm1                          ; xmm0 = o1e0*o1e0+o1e4*o1e4+o1e2*o1e2+o1e6*o1e6+o1e1*o1e1+o1e5*o1e5+o1e3*o1e3+o1e7*o1e7, o1e1*o1e1+o1e5*o1e5+o1e3*o1e3+o1e7*o1e7+o1e0*o1e0+o1e4*o1e4+o1e2*o1e2+o1e6*o1e6
    vpermpd      ymm10, ymm0, 00000000b                    ; ymm10 = o2norm, o2norm, o2norm, o2norm
    lea          rax, [t0]                                 ; rax = addr div mask
    vmovapd      ymm0, ymmword ptr [rcx]                   ; ymm0 = o1e0, o1e1, o1e2, o1e3
    vmovapd      ymm1, ymmword ptr [rcx+32]                ; ymm1 = o1e4, o1e5, o1e6, o1e7
    vxorpd       ymm8, ymm8, ymm8                          ; ymm8 = 0
    vxorpd       ymm9, ymm9, ymm9                          ; ymm9 = 0
    vmovapd      ymm2, ymm5                                ; ymm2 = o2e0, o2e1, o2e2, o2e3
    vmovapd      ymm3, ymm6                                ; ymm3 = o2e4, o2e5, o2e6, o2e7
    ; e0 column
    vpermpd      ymm4, ymm0, 00000000b                     ; ymm4 = o1e0, o1e0, o1e0, o1e0
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e0, o1e0, o1e0, o1e0
    vpermpd      ymm6, ymm2, 11100100b                     ; ymm6 = o2e0, o2e1, o2e2, o2e3
    vpermpd      ymm7, ymm3, 11100100b                     ; ymm7 = o2e4, o2e5, o2e6, o2e7
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e0*o2e0, o1e0*o2e1, o1e0*o2e2, o1e0*o2e3
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e0*o2e4, o1e0*o2e5, o1e0*o2e6, o1e0*o2e7
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax]             ; ymm8 = ymm8 + (o1e0*o2e0*t0[0], o1e0*o2e1*t0[1], o1e0*o2e2*t0[2], o1e0*o2e3*t0[3])
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+32]          ; ymm9 = ymm9 + (o1e0*o2e4*t0[4], o1e0*o2e5*t0[5], o1e0*o2e6*t0[6], o1e0*o2e7*t0[7])
    ; e1 column
    vpermpd      ymm4, ymm0, 01010101b                     ; ymm4 = o1e1, o1e1, o1e1, o1e1
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e1, o1e1, o1e1, o1e1
    vpermpd      ymm6, ymm2, 10110001b                     ; ymm6 = o2e1, o2e0, o2e3, o2e2
    vpermpd      ymm7, ymm3, 10110001b                     ; ymm7 = o2e5, o2e4, o2e7, o2e6
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e1*o2e1, o1e1*o2e0, o1e1*o2e3, o1e1*o2e2
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e1*o2e5, o1e1*o2e4, o1e1*o2e7, o1e1*o2e6
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+64]          ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+96]          ; multiply by mask and add to accumulator
    ; e2 column
    vpermpd      ymm4, ymm0, 10101010b                     ; ymm4 = o1e2, o1e2, o1e2, o1e2
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e2, o1e2, o1e2, o1e2
    vpermpd      ymm6, ymm2, 01001110b                     ; ymm6 = o2e2, o2e3, o2e0, o2e1
    vpermpd      ymm7, ymm3, 01001110b                     ; ymm7 = o2e6, o2e7, o2e4, o2e5
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e2*o2e2, o1e2*o2e3, o1e2*o2e0, o1e2*o2e1
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e2*o2e6, o1e2*o2e7, o1e2*o2e4, o1e2*o2e5
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+128]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+160]         ; multiply by mask and add to accumulator
    ; e3 column
    vpermpd      ymm4, ymm0, 11111111b                     ; ymm4 = o1e3, o1e3, o1e3, o1e3
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e3, o1e3, o1e3, o1e3
    vpermpd      ymm6, ymm2, 00011011b                     ; ymm6 = o2e3, o2e2, o2e1, o2e0
    vpermpd      ymm7, ymm3, 00011011b                     ; ymm7 = o2e7, o2e6, o2e5, o2e4
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e3*o2e3, o1e3*o2e2, o1e3*o2e1, o1e3*o2e0
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e3*o2e7, o1e3*o2e6, o1e3*o2e5, o1e3*o2e4
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+192]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+224]         ; multiply by mask and add to accumulator
    ; e4 column
    vpermpd      ymm4, ymm1, 00000000b                     ; ymm4 = o1e4, o1e4, o1e4, o1e4
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e4, o1e4, o1e4, o1e4
    vpermpd      ymm6, ymm3, 11100100b                     ; ymm6 = o2e4, o2e5, o2e6, o2e7
    vpermpd      ymm7, ymm2, 11100100b                     ; ymm7 = o2e0, o2e1, o2e2, o2e3
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e4*o2e4, o1e4*o2e5, o1e4*o2e6, o1e4*o2e7
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e4*o2e0, o1e4*o2e1, o1e4*o2e2, o1e4*o2e3
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+256]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+288]         ; multiply by mask and add to accumulator
    ; e5 column
    vpermpd      ymm4, ymm1, 01010101b                     ; ymm4 = o1e5, o1e5, o1e5, o1e5
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e5, o1e5, o1e5, o1e5
    vpermpd      ymm6, ymm3, 10110001b                     ; ymm6 = o2e5, o2e4, o2e7, o2e6
    vpermpd      ymm7, ymm2, 10110001b                     ; ymm7 = o2e1, o2e0, o2e3, o2e2
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e5*o2e5, o1e5*o2e4, o1e5*o2e7, o1e5*o2e6
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e5*o2e1, o1e5*o2e0, o11k*o2e3, o1e5*o2e2
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+320]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+352]         ; multiply by mask and add to accumulator
    ; e6 column
    vpermpd      ymm4, ymm1, 10101010b                     ; ymm4 = o1e6, o1e6, o1e6, o1e6
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e6, o1e6, o1e6, o1e6
    vpermpd      ymm6, ymm3, 01001110b                     ; ymm6 = o2e6, o2e7, o2e4, o2e5
    vpermpd      ymm7, ymm2, 01001110b                     ; ymm7 = o2e2, o2e3, o2e0, o2e1
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e6*o2e6, o1e6*o2e7, o1e6*o2e4, o1e6*o2e5
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e6*o2e2, o1e6*o2e3, o1e6*o2e0, o1e6*o2e1
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+384]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+416]         ; multiply by mask and add to accumulator
    ; e7 column
    vpermpd      ymm4, ymm1, 11111111b                     ; ymm4 = o1e7, o1e7, o1e7, o1e7
    vmovapd      ymm5, ymm4                                ; ymm5 = o1e7, o1e7, o1e7, o1e7
    vpermpd      ymm6, ymm3, 00011011b                     ; ymm6 = o2e7, o2e6, o2e5, o2e4
    vpermpd      ymm7, ymm2, 00011011b                     ; ymm7 = o2e3, o2e2, o2e1, o2e0
    vmulpd       ymm4, ymm6, ymm4                          ; ymm4 = o1e7*o2e7, o1e7*o2e6, o1e7*o2e5, o1e7*o2e4
    vmulpd       ymm5, ymm7, ymm5                          ; ymm5 = o1e7*o2e3, o1e7*o2e2, o1e7*o2e1, o1e7*o2e0
    vfmadd231pd  ymm8, ymm4, ymmword ptr [rax+448]         ; multiply by mask and add to accumulator
    vfmadd231pd  ymm9, ymm5, ymmword ptr [rax+480]         ; multiply by mask and add to accumulator
    vdivpd       ymm8, ymm8, ymm10
    vdivpd       ymm9, ymm9, ymm10
    vmovapd      ymmword ptr [r8], ymm8                    ; return low quaternion of octonion result
    vmovapd      ymmword ptr [r8+32], ymm9                 ; return high quaternion of octonion result
    vextractf128 xmm6, ymm10, 1                            ; restore non-volatile lower 128 bits of xmm6 from volatile upper 128 bits of ymm10
    vextractf128 xmm7, ymm11, 1                            ; restore non-volatile lower 128 bits of xmm7 from volatile upper 128 bits of ymm11
    vextractf128 xmm8, ymm12, 1                            ; restore non-volatile lower 128 bits of xmm8 from volatile upper 128 bits of ymm12
    vextractf128 xmm9, ymm13, 1                            ; restore non-volatile lower 128 bits of xmm9 from volatile upper 128 bits of ymm13
    vextractf128 xmm10, ymm14, 1                           ; restore non-volatile lower 128 bits of xmm10 from volatile upper 128 bits of ymm14
    ret
octonion_div64_AVX2 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision scalar multiplication AVX2
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
; o1e0*s -> e0
; o1e1*s -> e1
; o1e2*s -> e2
; o1e3*s -> e3
; o1e4*s -> e4
; o1e5*s -> e5
; o1e6*s -> e6
; o1e7*s -> e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_mul64s_AVX2(octonion64 *o1, double *s, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_mul64s_AVX2
octonion_mul64s_AVX2 proc
    vmovapd      ymm0, ymmword ptr [rcx]
    vmovapd      ymm1, ymmword ptr [rcx+32]
    vbroadcastsd ymm2, qword ptr [rdx]
   ;vbroadcastsd ymm3, xmm2                                ; stalls waiting on xmm2 to load
    vbroadcastsd ymm3, qword ptr [rdx]                     ; s will be in L1, don't stall
    vmulpd       ymm0, ymm0, ymm2
    vmulpd       ymm1, ymm1, ymm3
    vmovapd      ymmword ptr [r8], ymm0
    vmovapd      ymmword ptr [r8+32], ymm1
    ret
octonion_mul64s_AVX2 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision scalar division AVX2
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
; o1e0/s -> e0
; o1e1/s -> e1
; o1e2/s -> e2
; o1e3/s -> e3
; o1e4/s -> e4
; o1e5/s -> e5
; o1e6/s -> e6
; o1e7/s -> e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_div64s_AVX2(octonion64 *o1, double *s, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_div64s_AVX2
octonion_div64s_AVX2 proc
    vmovapd      ymm0, ymmword ptr [rcx]
    vmovapd      ymm1, ymmword ptr [rcx+32]
    vbroadcastsd ymm2, qword ptr [rdx]
    vbroadcastsd ymm3, qword ptr [rdx]
    vdivpd       ymm0, ymm0, ymm2
    vdivpd       ymm1, ymm1, ymm3
    vmovapd      ymmword ptr [r8], ymm0
    vmovapd      ymmword ptr [r8+32], ymm1
    ret
octonion_div64s_AVX2 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision addition AVX2
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
; o1e0+o2e0 -> o3e0
; o1e1+o2e1 -> o3e1
; o1e2+o2e2 -> o3e2
; o1e3+o2e3 -> o3e3
; o1e4+o2e4 -> o3e4
; o1e5+o2e5 -> o3e5
; o1e6+o2e6 -> o3e6
; o1e7+o2e7 -> o3e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_add64_AVX2(octonion64 *o1, octonion64 *o2, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_add64_AVX2
octonion_add64_AVX2 proc
    vmovapd     ymm0, ymmword ptr [rcx]
    vmovapd     ymm1, ymmword ptr [rcx+32]
    vaddpd      ymm0, ymm0, ymmword ptr [rdx]
    vaddpd      ymm1, ymm1, ymmword ptr [rdx+32]
    vmovapd     ymmword ptr [r8], ymm0
    vmovapd     ymmword ptr [r8+32], ymm1
    ret
octonion_add64_AVX2 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision subtraction AVX2
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
; o1e0-o2e0 -> o3e0
; o1e1-o2e1 -> o3e1
; o1e2-o2e2 -> o3e2
; o1e3-o2e3 -> o3e3
; o1e4-o2e4 -> o3e4
; o1e5-o2e5 -> o3e5
; o1e6-o2e6 -> o3e6
; o1e7-o2e7 -> o3e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_sub64_AVX2(octonion64 *o1, octonion64 *o2, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_sub64_AVX2
octonion_sub64_AVX2 proc
    vmovapd     ymm0, ymmword ptr [rcx]
    vmovapd     ymm1, ymmword ptr [rcx+32]
    vsubpd      ymm0, ymm0, ymmword ptr [rdx]
    vsubpd      ymm1, ymm1, ymmword ptr [rdx+32]
    vmovapd     ymmword ptr [r8], ymm0
    vmovapd     ymmword ptr [r8+32], ymm1
    ret
octonion_sub64_AVX2 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; AVX2
; =================================================================================================================
; =================================================================================================================

; *****************************************************************************************************************
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; *****************************************************************************************************************

; =================================================================================================================
; =================================================================================================================
; AVX-512
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

; =================================================================================================================
; octonion double precision normal AVX-512
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;   result = e0*e0 + e1*e1 + e2*e2 + e3*e3 + e4*e4 + e5*e5 + e6*e6 + e7*e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_norm64_AVX512(octonion64 *o, double *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_norm64_AVX512
octonion_norm64_AVX512 proc
    vmovupd       zmm1, zmmword ptr [rcx]
    vmulpd        zmm1, zmm1, zmm1
    vextractf64x4 ymm0, zmm1, 1
    vaddpd        ymm2, ymm0, ymm1
    vextractf64x2 xmm0, ymm2, 1
    vaddpd        xmm1, xmm0, xmm2
    vpsrldq       xmm0, xmm1, 8
    vaddsd        xmm0, xmm0, xmm1
    vmovq         qword ptr [rdx], xmm0
    ret
octonion_norm64_AVX512 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision multiplication AVX-512
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
; h0          h1          h2          h3          h4          h5          h6          h7
; o1e0*o2e0 - o1e1*o2e1 - o1e2*o2e2 - o1e3*o2e3 - o1e4*o2e4 - o1e5*o2e5 - o1e6*o2e6 - o1e7*o2e7 -> e0
; o1e0*o2e1 + o1e1*o2e0 + o1e2*o2e3 - o1e3*o2e2 + o1e4*o2e5 - o1e5*o2e4 - o1e6*o2e7 + o1e7*o2e6 -> e1
; o1e0*o2e2 - o1e1*o2e3 + o1e2*o2e0 + o1e3*o2e1 + o1e4*o2e6 + o1e5*o2e7 - o1e6*o2e4 - o1e7*o2e5 -> e2
; o1e0*o2e3 + o1e1*o2e2 - o1e2*o2e1 + o1e3*o2e0 + o1e4*o2e7 - o1e5*o2e6 + o1e6*o2e5 - o1e7*o2e4 -> e3
; h8          h9          ha          hb          hc          hd          he          hf
; o1e0*o2e4 - o1e1*o2e5 - o1e2*o2e6 - o1e3*o2e7 + o1e4*o2e0 + o1e5*o2e1 + o1e6*o2e2 + o1e7*o2e3 -> e4
; o1e0*o2e5 + o1e1*o2e4 - o1e2*o2e7 + o1e3*o2e6 - o1e4*o2e1 + o1e5*o2e0 - o1e6*o2e3 + o1e7*o2e2 -> e5
; o1e0*o2e6 + o1e1*o2e7 + o1e2*o2e4 - o1e3*o2e5 - o1e4*o2e2 + o1e5*o2e3 + o1e6*o2e0 - o1e7*o2e1 -> e6
; o1e0*o2e7 - o1e1*o2e6 + o1e2*o2e5 + o1e3*o2e4 - o1e4*o2e3 - o1e5*o2e2 + o1e6*o2e1 + o1e7*o2e0 -> e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_mul64_AVX512(octonion64 *o1, octonion64 *o2, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_mul64_AVX512
octonion_mul64_AVX512 proc
    vinsertf128  ymm10, ymm10, xmm6, 1             ; save non-volatile lower 128 bits of xmm6 into volatile upper 128 bits of ymm10
    vxorpd       zmm6, zmm6, zmm6
    ; e0 column
    vmovapd      zmm0, zmmword ptr [rcx]           ; load oct1
    vmovapd      zmm1, zmmword ptr [rdx]           ; load oct2
    lea          rax, byte ptr [n0]                ; oct1 perm mask ptr
    lea          r9, byte ptr [m0]                 ; oct2 perm mask ptr
    lea          rcx, byte ptr [h0]                ; mult mask ptr
    vmovapd      zmm2, zmmword ptr [rax]           ; load oct1 perm mask
    vmovapd      zmm3, zmmword ptr [r9]            ; load oct2 perm mask
    vpermpd      zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd      zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd       zmm4, zmm4, zmmword ptr [rcx]     ; mult oct1 perm by mult mask
    vfmadd231pd  zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e1 column
    vmovapd      zmm2, zmmword ptr [rax+64]        ; load oct1 perm mask
    vmovapd      zmm3, zmmword ptr [r9+64]         ; load oct2 perm mask
    vpermpd      zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd      zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd       zmm4, zmm4, zmmword ptr [rcx+64]  ; mult oct1 perm by mult mask
    vfmadd231pd  zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e2 column
    vmovapd      zmm2, zmmword ptr [rax+128]       ; load oct1 perm mask
    vmovapd      zmm3, zmmword ptr [r9+128]        ; load oct2 perm mask
    vpermpd      zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd      zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd       zmm4, zmm4, zmmword ptr [rcx+128] ; mult oct1 perm by mult mask
    vfmadd231pd  zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e3 column
    vmovapd      zmm2, zmmword ptr [rax+192]       ; load oct1 perm mask
    vmovapd      zmm3, zmmword ptr [r9+192]        ; load oct2 perm mask
    vpermpd      zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd      zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd       zmm4, zmm4, zmmword ptr [rcx+192] ; mult oct1 perm by mult mask
    vfmadd231pd  zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e4 column
    vmovapd      zmm2, zmmword ptr [rax+256]       ; load oct1 perm mask
    vmovapd      zmm3, zmmword ptr [r9+256]        ; load oct2 perm mask
    vpermpd      zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd      zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd       zmm4, zmm4, zmmword ptr [rcx+256] ; mult oct1 perm by mult mask
    vfmadd231pd  zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e5 column
    vmovapd      zmm2, zmmword ptr [rax+320]       ; load oct1 perm mask
    vmovapd      zmm3, zmmword ptr [r9+320]        ; load oct2 perm mask
    vpermpd      zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd      zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd       zmm4, zmm4, zmmword ptr [rcx+320] ; mult oct1 perm by mult mask
    vfmadd231pd  zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e6 column
    vmovapd      zmm2, zmmword ptr [rax+384]       ; load oct1 perm mask
    vmovapd      zmm3, zmmword ptr [r9+384]        ; load oct2 perm mask
    vpermpd      zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd      zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd       zmm4, zmm4, zmmword ptr [rcx+384] ; mult oct1 perm by mult mask
    vfmadd231pd  zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e7 column
    vmovapd      zmm2, zmmword ptr [rax+448]       ; load oct1 perm mask
    vmovapd      zmm3, zmmword ptr [r9+448]        ; load oct2 perm mask
    vpermpd      zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd      zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd       zmm4, zmm4, zmmword ptr [rcx+448] ; mult oct1 perm by mult mask
    vfmadd231pd  zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    vmovapd      zmmword ptr [r8], zmm6            ; store results in caller's memory
    vextractf128 xmm6, ymm10, 1                    ; restore non-volatile lower 128 bits of xmm6 from volatile upper 128 bits of ymm10
    ret
octonion_mul64_AVX512 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision division AVX-512
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;   o2norm = e0*e0 + e1*e1 + e2*e2 + e3*e3 + e4*e4 + e5*e5 + e6*e6 + e7*e7
;	( o1e0*o2e0 + o1e1*o2e1 + o1e2*o2e2 + o1e3*o2e3 + o1e4*o2e4 + o1e5*o2e5 + o1e6*o2e6 + o1e7*o2e7) / o2norm -> e0
;	(-o1e0*o2e1 + o1w1*o2e0 - o1e2*o2e3 + o1e3*o2e2 - o1e4*o2e5 + o1e5*o2e4 + o1e6*o2e7 - o1e7*o2e6) / o2norm -> e1
;	(-o1e0*o2e2 + o1e1*o2e3 + o1e2*o2e0 - o1e3*o2e1 - o1e4*o2e6 - o1e5*o2e7 + o1e6*o2e4 + o1e7*o2e5) / o2norm -> e2
;	(-o1e0*o2e3 - o1e1*o2e2 + o1e2*o2e1 + o1e3*o2e0 - o1e4*o2e7 + o1e5*o2e6 - o1e6*o2e5 + o1e7*o2e4) / o2norm -> e3
;	(-o1e0*o2e4 + o1e1*o2e5 + o1e2*o2e6 + o1e3*o2e7 + o1e4*o2e0 - o1e5*o2e1 - o1e6*o2e2 - o1e7*o2e3) / o2norm -> e4
;	(-o1e0*o2e5 - o1e1*o2e4 + o1e2*o2e7 - o1e3*o2e6 + o1e4*o2e1 + o1e5*o2e0 + o1e6*o2e3 - o1e7*o2e2) / o2norm -> e5
;	(-o1e0*o2e6 - o1e1*o2e7 - o1e2*o2e4 + o1e3*o2e5 + o1e4*o2e2 - o1e5*o2e3 + o1e6*o2e0 + o1e7*o2e1) / o2norm -> e6
;	(-o1e0*o2e7 + o1e1*o2e6 - o1e2*o2e5 - o1e3*o2e4 + o1e4*o2e3 + o1e5*o2e2 - o1e6*o2e1 + o1e7*o2e0) / o2norm -> e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_div64_AVX512(octonion64 *o1, octonion64 *o1, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_div64_AVX512
octonion_div64_AVX512 proc
    vinsertf128   ymm10, ymm10, xmm6, 1             ; save non-volatile lower 128 bits of xmm6 into volatile upper 128 bits of ymm10
    vinsertf128   ymm11, ymm11, xmm7, 1             ; save non-volatile lower 128 bits of xmm7 into volatile upper 128 bits of ymm11
    vmovupd       zmm1, zmmword ptr [rdx]           ; calculate o2 norm
    vmulpd        zmm1, zmm1, zmm1
    vextractf64x4 ymm0, zmm1, 1
    vaddpd        ymm2, ymm0, ymm1
    vextractf64x2 xmm0, ymm2, 1
    vaddpd        xmm1, xmm0, xmm2
    vpsrldq       xmm0, xmm1, 8
    vaddsd        xmm0, xmm0, xmm1
    vpbroadcastq  zmm7, xmm0                        ; zmm7 = o2norm, o2norm, o2norm, o2norm, o2norm, o2norm, o2norm, o2norm
    vxorpd        zmm6, zmm6, zmm6                  ; initialize the accumulator to zero
    ; e0 column
    vmovapd       zmm0, zmmword ptr [rcx]           ; load oct1
    vmovapd       zmm1, zmmword ptr [rdx]           ; load oct2
    lea           rax, byte ptr [n0]                ; oct1 perm mask ptr
    lea           r9, byte ptr [m0]                 ; oct2 perm mask ptr
    lea           rcx, byte ptr [t0]                ; div mask ptr
    vmovapd       zmm2, zmmword ptr [rax]           ; load oct1 perm mask
    vmovapd       zmm3, zmmword ptr [r9]            ; load oct2 perm mask
    vpermpd       zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd       zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd        zmm4, zmm4, zmmword ptr [rcx]     ; mult oct1 perm by mult mask
    vfmadd231pd   zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e1 column
    vmovapd       zmm2, zmmword ptr [rax+64]        ; load oct1 perm mask
    vmovapd       zmm3, zmmword ptr [r9+64]         ; load oct2 perm mask
    vpermpd       zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd       zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd        zmm4, zmm4, zmmword ptr [rcx+64]  ; mult oct1 perm by mult mask
    vfmadd231pd   zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e2 column
    vmovapd       zmm2, zmmword ptr [rax+128]       ; load oct1 perm mask
    vmovapd       zmm3, zmmword ptr [r9+128]        ; load oct2 perm mask
    vpermpd       zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd       zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd        zmm4, zmm4, zmmword ptr [rcx+128] ; mult oct1 perm by mult mask
    vfmadd231pd   zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e3 column
    vmovapd       zmm2, zmmword ptr [rax+192]       ; load oct1 perm mask
    vmovapd       zmm3, zmmword ptr [r9+192]        ; load oct2 perm mask
    vpermpd       zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd       zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd        zmm4, zmm4, zmmword ptr [rcx+192] ; mult oct1 perm by mult mask
    vfmadd231pd   zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e4 column
    vmovapd       zmm2, zmmword ptr [rax+256]       ; load oct1 perm mask
    vmovapd       zmm3, zmmword ptr [r9+256]        ; load oct2 perm mask
    vpermpd       zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd       zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd        zmm4, zmm4, zmmword ptr [rcx+256] ; mult oct1 perm by mult mask
    vfmadd231pd   zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e5 column
    vmovapd       zmm2, zmmword ptr [rax+320]       ; load oct1 perm mask
    vmovapd       zmm3, zmmword ptr [r9+320]        ; load oct2 perm mask
    vpermpd       zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd       zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd        zmm4, zmm4, zmmword ptr [rcx+320] ; mult oct1 perm by mult mask
    vfmadd231pd   zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e6 column
    vmovapd       zmm2, zmmword ptr [rax+384]       ; load oct1 perm mask
    vmovapd       zmm3, zmmword ptr [r9+384]        ; load oct2 perm mask
    vpermpd       zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd       zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd        zmm4, zmm4, zmmword ptr [rcx+384] ; mult oct1 perm by mult mask
    vfmadd231pd   zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    ; e7 column
    vmovapd       zmm2, zmmword ptr [rax+448]       ; load oct1 perm mask
    vmovapd       zmm3, zmmword ptr [r9+448]        ; load oct2 perm mask
    vpermpd       zmm4, zmm2, zmm0                  ; perm oct1 by mask into zmm4
    vpermpd       zmm5, zmm3, zmm1                  ; perm oct2 by mask into zmm5
    vmulpd        zmm4, zmm4, zmmword ptr [rcx+448] ; mult oct1 perm by mult mask
    vfmadd231pd   zmm6, zmm4, zmm5                  ; mult oct1 by oct2 after perms and add to accumulator
    vdivpd        zmm6, zmm6, zmm7                  ; divide by o2norm
    vmovapd       zmmword ptr [r8], zmm6            ; store results in caller's memory
    vextractf128  xmm6, ymm10, 1                    ; restore non-volatile lower 128 bits of xmm6 from volatile upper 128 bits of ymm10
    vextractf128  xmm7, ymm11, 1                    ; restore non-volatile lower 128 bits of xmm7 from volatile upper 128 bits of ymm11
    ret
octonion_div64_AVX512 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision scalar multiplication AVX-512
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
; o1e0*s -> e0
; o1e1*s -> e1
; o1e2*s -> e2
; o1e3*s -> e3
; o1e4*s -> e4
; o1e5*s -> e5
; o1e6*s -> e6
; o1e7*s -> e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_mul64s_AVX512(octonion64 *o1, double *s, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_mul64s_AVX512
octonion_mul64s_AVX512 proc
    vmovapd      zmm0, zmmword ptr [rcx]
    vbroadcastsd zmm1, qword ptr [rdx]
    vmulpd       zmm0, zmm0, zmm1
    vmovapd      zmmword ptr [r8], zmm0
    ret
octonion_mul64s_AVX512 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision scalar division AVX-512
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
; o1e0/s -> e0
; o1e1/s -> e1
; o1e2/s -> e2
; o1e3/s -> e3
; o1e4/s -> e4
; o1e5/s -> e5
; o1e6/s -> e6
; o1e7/s -> e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_div64s_AVX512(octonion64 *o1, double *s, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_div64s_AVX512
octonion_div64s_AVX512 proc
    vmovapd      zmm0, zmmword ptr [rcx]
    vbroadcastsd zmm1, qword ptr [rdx]
    vdivpd       zmm0, zmm0, zmm1
    vmovapd      zmmword ptr [r8], zmm0
    ret
octonion_div64s_AVX512 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision addition AVX-512
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
; o1e0+o2e0 -> o3e0
; o1e1+o2e1 -> o3e1
; o1e2+o2e2 -> o3e2
; o1e3+o2e3 -> o3e3
; o1e4+o2e4 -> o3e4
; o1e5+o2e5 -> o3e5
; o1e6+o2e6 -> o3e6
; o1e7+o2e7 -> o3e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; Instruction timing:
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_add64_AVX512(octonion64 *o1, octonion64 *o2, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_add64_AVX512
octonion_add64_AVX512 proc
    vmovapd     zmm0, zmmword ptr [rcx]
    vaddpd      zmm0, zmm0, zmmword ptr [rdx]
    vmovapd     zmmword ptr [r8], zmm0
    ret
octonion_add64_AVX512 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; octonion double precision subtraction AVX-512
; =================================================================================================================
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
; The math:
;
; o1e0-o2e0 -> o3e0
; o1e1-o2e1 -> o3e1
; o1e2-o2e2 -> o3e2
; o1e3-o2e3 -> o3e3
; o1e4-o2e4 -> o3e4
; o1e5-o2e5 -> o3e5
; o1e6-o2e6 -> o3e6
; o1e7-o2e7 -> o3e7
;
; -----------------------------------------------------------------------------------------------------------------
;
; Instruction timing:
;
; notes:
;
; -----------------------------------------------------------------------------------------------------------------
;
; C prototype:
;
; void octonion_sub64_AVX512(octonion64 *o1, octonion64 *o2, octonion64 *result);
;
; -----------------------------------------------------------------------------------------------------------------
;
public octonion_sub64_AVX512
octonion_sub64_AVX512 proc
    vmovapd     zmm0, zmmword ptr [rcx]
    vsubpd      zmm0, zmm0, zmmword ptr [rdx]
    vmovapd     zmmword ptr [r8], zmm0
    ret
octonion_sub64_AVX512 endp
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; AVX-512
; =================================================================================================================
; =================================================================================================================

; =================================================================================================================
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;
; code ends
;
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================


; =================================================================================================================
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;
; end octonion_asm.asm
;
end
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; =================================================================================================================
