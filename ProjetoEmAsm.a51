;Constantes
fimTempo        EQU 100;
zero            EQU 3;
oitenta         EQU 7;
CentoSessenta   EQU 11;

;Porta servo
servo   EQU P1.0;

;variaveis globais
botao       EQU 30;
conta       EQU 31;
referencia  EQU 32;

;inicio
cseg at 0
jmp main

;interrupcao esterna 0
cseg at 0x3
jmp External0_ISR

;Interropcao do timer0
cseg at 0Xb
jmp Timer0_ISR

;inicializacoes
Init:

    ;Configuracao Registo IE
    setb EA; ativa interrupcoes globais
    setb ET0;ativa interrupcao timer0
    setb EX0;ativa interrupcao externa 0

    ;Configuracao reisto TMOD
    anl TMOD, #0xF0 ;limpa os 4 bits do timer0
    orl TMOD, #0x02;modo 2 do timer 0

    ;Configuracao timer 0 - 200us
    mov TH0, #0x38; Timer 0 - 200
    mov TL0, #0x38

    ;Configuracao registos TCON
    setb TR0; comeca o timer 0
    setb IT0; interrupcao ativa a falling edge
ret

;interrupcao esterna 0
External0_ISR:
    mov botao, #1; assinala que o botao foi pressionado
reti

;Interrupcao timer 0
Timer0_ISR:
    inc conta; incrementa a contagem dos 200us
reti

cseg at 0x50
main:
    mov sp,#7;inicializacao da stack
    
    ;inicializacoes das variaveis globais
    mov botao, #0;
    mov conta, #0;
    mov referencia, #zero;
    call Init;
while:;
    mov a, conta; verifica se atingio o valor de referencia
    cjne a, referencia, Teste_Fim_Tempo
    clr servo;
    Teste_Fim_Tempo:;
        cjne a, #fimTempo, Teste_Botao_ativo;
        mov conta, #0;
        setb servo;
    Teste_Botao_ativo:;
        mov a, botao;
        cjne a, #1, while;
        mov a, referencia
        cjne a, #zero, Teste_oitenta
        mov referencia, #oitenta;
        jmp Fim_Teste_Botao_ativo
    Teste_oitenta:;
        cjne a, #oitenta, Teste_CentoSessenta;
        mov referencia, #CentoSessenta;
        jmp Fim_Teste_Botao_ativo
    Teste_CentoSessenta:;
        cjne a, #CentoSessenta, Fim_Teste_Botao_ativo
        mov botao, #0
    Fim_Teste_Botao_ativo:
        mov botao, #0
jmp while

END