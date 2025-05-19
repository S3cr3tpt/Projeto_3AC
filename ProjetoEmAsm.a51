;-----------------------------------------------
; Parque de Estacionamento 8051 — Assembly (R0–R7)
; Usando apenas registradores para variáveis
; Sem lógica de sensor integrado (retornado ao estado anterior)
; Correções MOV Rn,#immediate substituídas
;-----------------------------------------------

; Constantes de temporização
FIM_TEMPO       EQU 200        ; 200 µs por overflow
MAX_CONTA_ALTO  EQU 195        ; 195×256×200 µs ≈ 10 s
PISCA_INTERVALO EQU 20         ; 20×256×200 µs ≈ 1 s
ATUALIZA_OVF    EQU 500        ; 500×200 µs = 100 ms

; Mapeamento de pinos
barreira        EQU P1.3      ; Barreira (servo)
ledAmarelo      EQU P1.2      ; LED amarelo
sensorOptico    EQU P1.4      ; Sensor ótico (não usado neste código)
botaoEntrada    EQU P3.2      ; INT0
botaoSaida      EQU P3.3      ; INT1
ledVerde        EQU P1.0      ; LED verde
ledVermelho     EQU P1.1      ; LED vermelho

; Variáveis em registradores
; R0 = contaBaixo     ; ticks de 200 µs
; R1 = contaAlto      ; 10 s e piscar
; R2 = flagTempo10s   ; sinaliza fim de 10 s
; R3 = flagPiscar     ; habilita piscar LED amarelo
; R4 = contaUpdLow    ; ticks de 200 µs para atualização
; R5 = contaUpdHigh   ; 100 ms de atualização
; R6 = flagAtualizar  ; sinaliza MAIN atualizar display
; R7 = uso temporário para contagem de bits
; B  = acumulador de vagas livres

; Vetores de interrupção
    ORG 0000H
    LJMP main

    ORG 0003H       ; INT0 (botão Entrada)
    LJMP Botao_ISR

    ORG 000Bh       ; Timer0
    LJMP Timer0_ISR

    ORG 0013H       ; INT1 (botão Saída)
    LJMP Botao_ISR

;----------------------------
; Inicialização
;----------------------------
    ORG 0030H
Init:
    SETB   EA          ; habilita interrupções globais
    SETB   EX0         ; habilita INT0 (falling edge)
    SETB   EX1         ; habilita INT1 (falling edge)
    SETB   ET0         ; habilita Timer0

    ANL    TMOD, #0F0h ; limpa configurações de Timer0
    ORL    TMOD, #02h  ; modo 2 (auto-reload)

    MOV    TH0, #038h  ; recarga ≈200 µs
    MOV    TL0, #038h

    SETB   TR0         ; inicia Timer0
    SETB   IT0         ; INT0 na borda de descida
    SETB   IT1         ; INT1 na borda de descida

    RET

;----------------------------
; ISR comum: Botão Entrada/Saída
; Levanta barreira, liga amarelo e reinicia temporizações
;----------------------------
Botao_ISR:
    SETB   barreira         ; abre barreira
    SETB   ledAmarelo       ; acende amarelo
    ; reseta flags e contadores via A
    MOV    A, #0
    MOV    R2, A           ; reseta flagTempo10s
    MOV    R6, A           ; reseta flagAtualizar
    MOV    R0, A           ; reseta contaBaixo
    MOV    R1, A           ; reseta contaAlto
    MOV    R4, A           ; reseta contaUpdLow
    MOV    R5, A           ; reseta contaUpdHigh
    MOV    A, #1
    MOV    R3, A           ; habilita piscar amarelo
    RETI

;----------------------------
; ISR Timer0: Ticks de 200 µs
; - Contagem 10 s + piscar
; - Contagem 100 ms para atualização
;----------------------------
Timer0_ISR:
    ; ===== 10 s + piscar =====
    INC    R0
    MOV    A, R0
    CJNE   A, #0, SkipHigh
    INC    R1               ; overflow do contador baixo
SkipHigh:
    ; piscar amarelo
    MOV    A, R3
    CJNE   A, #1, SkipBlink
    MOV    A, R1
    CJNE   A, #PISCA_INTERVALO, SkipBlink    
	MOV    A, #0
    MOV    R1, A
    CPL    ledAmarelo       ; inverte amarelo
SkipBlink:
    MOV    A, R1
    CJNE   A, #MAX_CONTA_ALTO, SkipUpdate
    ; 10 s completos
    MOV    A, #0
    MOV    R1, A
    MOV    A, #1
    MOV    R2, A           ; marca flagTempo10s
    MOV    A, #0
    MOV    R3, A           ; desabilita piscar

    ; ===== 100 ms atualização =====
SkipUpdate:
    INC    R4
    MOV    A, R4
    CJNE   A, #0, EndISR
    INC    R5
    MOV    A, R5
    CJNE   A, #1, EndISR
    ; 100 ms completos
    MOV    A, #0
    MOV    R4, A
    MOV    R5, A
    MOV    A, #1
    MOV    R6, A           ; marca flagAtualizar

EndISR:
    RETI

;----------------------------
; Programa Principal
;----------------------------
    ORG 0050H
main:
    MOV    SP, #07h
    ; zera R0-R7
    MOV    A, #0
    MOV    R0, A
    MOV    R1, A
    MOV    R2, A
    MOV    R3, A
    MOV    R4, A
    MOV    R5, A
    MOV    R6, A
    MOV    R7, A
    CALL   Init

LoopPrincipal:
    MOV    A, R2
    CJNE   A, #1, CheckUpdate
    CLR    barreira         ; fecha barreira após 10 s
    CLR    ledAmarelo       ; apaga amarelo
    MOV    A, #0
    MOV    R2, A            ; limpa flagTempo10s

CheckUpdate:
    MOV    A, R6
    CJNE   A, #1, LoopEnd

    ; --- Atualização de sensores e display ---
    MOV    P0, #0FFh       ; configura P0 como entrada
    MOV    A, P0            ; lê sensores S1-S8
    CPL    A                ; prepara LEDs de lugar
    MOV    P0, A            ; acende L1-L8

    ; conta lugares livres em B
    MOV    A, #0
    MOV    B, A             ; zera B
    MOV    R7, #8           ; loop 8 bits
CountLoop:
    RL     A
    JNC    NoInc
    INC    B
NoInc:
    DJNZ   R7, CountLoop

    ; exibe B (0-8) no display BCD em P2
    MOV    A, B
    ANL    A, #0Fh
    MOV    P2, A

    ; LED verde/vermelho
    MOV    A, B
    CJNE   A, #0, ParkOK
    CLR    ledVerde
    SETB   ledVermelho
    SJMP   AfterUpd
ParkOK:
    SETB   ledVerde
    CLR    ledVermelho
AfterUpd:
    MOV    A, #0
    MOV    R6, A           ; limpa flagAtualizar

LoopEnd:
    SJMP   LoopPrincipal

END
