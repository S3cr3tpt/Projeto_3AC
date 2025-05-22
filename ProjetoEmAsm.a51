;Constantes
fimTempo        EQU 100;

;PortaLeds
ledVerde   EQU P1.0;
ledVermelho EQU P1.1;
ledAmarelo EQU P1.2;

;Porta da barreira e do sensor
barreira   EQU P1.3;
sensor     EQU P1.4;

;Porta Estacionamento
LedsEstacionamento EQU P0;

;display de 7 egmento 
display7seg EQU P2;

;variaveis globais
pressionado     EQU 30;
botao           EQU 32;
conta           EQU 34;
constaSegundo   EQU 36;
passoucarro     EQU 38;

;inicio
cseg at 0
jmp main

;interrupcao esterna 0
cseg at 0x3
jmp External0_ISR

;interrupcao esteterna 1
cseg at 0x4
jmp External1_ISR

;Interropcao do timer0
cseg at 0Xb
jmp Timer0_ISR

;inicializacoes
Init:

    ;Configuracao Registo IE
    setb EA; ativa interrupcoes globais
    setb ET0;ativa interrupcao timer0
    setb EX0;ativa interrupcao externa 0
    setb EX1;ativa interrupcao externa 1

    ;Configuracao reisto TMOD
    anl TMOD, #0xF0 ;limpa os 4 bits do timer0
    orl TMOD, #0x02;modo 2 do timer 0

    ;Configuracao timer 0 - 200us
    mov TH0, #0x38; Timer 0 - 200
    mov TL0, #0x38

    ;Configuracao registos TCON
    setb TR0; comeca o timer 0
    setb IT0; interrupcao ativa a falling edge
    
    ;inicializacao das variaveis
    mov pressionado, 0;
    mov conta, 0;
    mov botao, 0;
    mov passoucarro, 0;

    ;Configuracao dos pinos
    mov ledVerde , 0; led verde ligado
    mov ledVermelho , #1; Led vermelho desligado
    mov ledAmarelo , #1; Led amarelo desligado
    mov barrreira , #0; barreira para baixo
    mov sensor , #0; sensor desligado
    mov LedsEstacionamento , #0 ; todos os leds ligados
    mov display7seg , 8; display 7 segmentos com o numero 8

ret

;interrupcao esterna 0
External0_ISR:
    mov botao, #0; assinala que o botao de sair foi pressionado
    mov pressionado, #1;assinala que o botao foi pressionado
reti

;interrupcao esterna 1
External1_ISR:
    mov botao, #1; assinala que o botao fde entrar foi pressionado
    mov pressionado, #1;assinala que o botao foi pressionado

reti

;Interrupcao timer 0
Timer0_ISR:
    inc conta; incrementa a contagem dos 200us
reti

cseg at 0x50
main:
    mov sp,#7;inicializacao da stack
    cmp conta, #0xFF; verifica se ja passaram 200ms
    jz main; se nao passaram 200ms, volta a verificar
    mov conta, #0; reinicia a contagem
    inc LedsEstacionamento
    rl ledsEstacionamento
jmp main
END