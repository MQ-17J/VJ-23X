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
;   asm_data.inc
;
; description
;   include file for various assembly code files to link against asm_data.asm
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
;
; change log
;   2026-02-28: created initial version
;
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; =================================================================================================================

extern h0 :qword
extern h1 :qword
extern h2 :qword
extern h3 :qword
extern h4 :qword
extern h5 :qword
extern h6 :qword
extern h7 :qword

extern t0 :qword
extern t1 :qword
extern t2 :qword
extern t3 :qword
extern t4 :qword
extern t5 :qword
extern t6 :qword
extern t7 :qword

extern d0 :qword
extern d1 :qword
extern d2 :qword
extern d3 :qword

extern n0 :qword 
extern n1 :qword 
extern n2 :qword 
extern n3 :qword 
extern n4 :qword 
extern n5 :qword 
extern n6 :qword 
extern n7 :qword 

extern m0 :qword 
extern m1 :qword 
extern m2 :qword 
extern m3 :qword 
extern m4 :qword 
extern m5 :qword 
extern m6 :qword 
extern m7 :qword 

extern temp_xmm6  :qword 
extern temp_xmm7  :qword 
extern temp_xmm8  :qword 
extern temp_xmm9  :qword
extern temp_xmm10 :qword
