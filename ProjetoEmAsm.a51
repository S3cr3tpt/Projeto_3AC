;Constantes
fimTempo            EQU 100; 100 *50 *200us = 1s
fimTempoBarreira    EQU 100; ; 100 * 200us = 20ms
zeroBarreira        EQU 3; 3 * 200us = 600us
oitentaBarreira     EQU 7; 7 * 200us = 1400us

;Portas P0
L0 EQU P0.0;
L1 EQU P0.1;
L2 EQU P0.2;
L3 EQU P0.3;
L4 EQU P0.4;
L5 EQU P0.5;
L6 EQU P0.6;
L7 EQU P0.7;

;Portas P1
ledVerde   EQU P1.0;
ledVermelho EQU P1.1;
ledAmarelo EQU P1.2;
barreira   EQU P1.3;
sensor     EQU P1.4;

;Portas P2
segmentoA EQU P2.0;
segmentoB EQU P2.1;
segmentoC EQU P2.2;
segmentoD EQU P2.3;

;variaveis globais
pressionado         EQU 0x30;
botao               EQU 0x31;
conta               EQU 0x32;
contaSegundo        EQU 0x33;
contaBarreira       EQU 0x34;
abreBarreira        EQU 0x35;
passoucarro         EQU 0x36;
referenciaBarreira  EQU 0x37;
testebitor			EQU 0x38;
adjudaContador		EQU 0x39;
bufferAbreBarreira	EQU 0x40;

;inicio
cseg at 0
jmp main

;interrupcao esterna 0
cseg at 0x3
jmp External0_ISR

;interrupcao esteterna 1
cseg at 0x13
jmp External1_ISR

;Interropcao do timer0
cseg at 0Xb
jmp Timer0_ISR

;inicializacoes
cseg at 0x50
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
    mov TH0, #56; Timer 0 - 200
    mov TL0, #56;

    ;Configuracao registos TCON
    setb TR0; comeca o timer 0
    setb IT0; interrupcao ativa a falling edge
    
    ;inicializacao das variaveis
    clr pressionado;
    mov conta, #0;
    clr botao;
    clr passoucarro;
	clr adjudaContador;
    ;Configuracao dos pinos
    ;Porta 1
    clr ledVerde; led verde ligado
    setb ledVermelho; Led vermelho desligado
    setb ledAmarelo; Led amarelo desligado
    setb barreira; barreira para baixo
    mov contaBarreira, #0; contaBarreira a 0
    
    ;Porta 2
    mov P2, #0x00; todos os segmentos desligados
    setb segmentoA; segmento A desligado
    clr segmentoB; segmento B desligado
    clr segmentoC; segmento C desligado
    setb segmentoD; segmento D ligado
    ;
ret

;interrupcao esterna 0
External0_ISR:
    CLR botao; assinala que o botao de sair foi pressionado
    setb pressionado;assinala que o botao foi pressionado
reti

;interrupcao esterna 1
External1_ISR:
    setb botao; assinala que o botao fde entrar foi pressionado
    setb pressionado;assinala que o botao foi pressionado
reti

;Interrupcao timer 0
Timer0_ISR:
    inc conta; incrementa a contagem dos 200us
    inc contaBarreira; incrementa a contagem da barreira
reti

cseg at 0xA0
main:
    mov sp,#7;inicializacao da stack
    call Init; chama a inicializacao
whileTrue:
    call display; chama a funcao display
    call leSensor; chama a funcao leSensor
    call moveBarreira; chama a funcao moveBarreira
    mov a, #fimTempo; coloca o valor de 250 no registo R0
    cjne a , conta, whileTrue;
	inc adjudaContador	
	mov conta,#0
	mov r3, adjudaContador
	cjne r3, #50, whileTrue
    mov adjudaContador, #0
    mov conta, #0
	;aqui ja passou 1 segundo
	jb botao, ifPressionado;se o botao estiver on salta para o if
    setb ledVermelho; led vermelho ligado
    clr ledVerde; led verde ligado
    jb segmentoA, ifPressionado;se o a estiver on salta para o if
    jb segmentoB, ifPressionado;se o b estiver on salta para o if
    jb segmentoC, ifPressionado;se o c estiver on salta para o if
    jb segmentoD, ifPressionado;se o d estiver on salta para o if
    jmp elseNaoLugares;se nao houver nada ligado salta para o naoLugares
ifPressionado:
    jnb pressionado, whileTrue; se o botao nao estiver pressionado volta ao inicio
    inc contaSegundo; incrementa a contagem dos segundos
    clr ledVerde; led verde ligado
    setb ledVermelho; Led vermelho desligado
    cpl ledAmarelo; led amarelo intermitente
    setb abreBarreira; abre a barreira
    mov R0, contaSegundo; coloca o valor da contagem no registo R0
    cjne R0, #10, whileTrue; verifica se a contagem e menor que 10
    mov contaSegundo,#9; coloca 10 no R0 para nao dar erros de overflow
    jnb passoucarro, whileTrue; verifica se o carro passou
    clr abreBarreira; feixa a barreira
    clr passoucarro; da reset ao carro
    clr pressionado; da reset ao pressionado
    mov contaSegundo, #0; da reset a contagem dos segundos
    setb ledAmarelo; desliga o led amarelo
jmp whileTrue; volta ao inicio do ciclo
elseNaoLugares:
    clr ledVermelho; led vermelho ligado
    setb ledVerde; Led verde desligado
jmp whileTrue; volta ao inicio do ciclo

display:
    mov R0, #0x00; inicializa o registo R1
    jb L0, segmento2; verifica se esta a 0
    inc R0; soma o valor do registo R2
segmento2:
    jb L1, segmento3; verifica se esta a 0
    inc R0; soma o valor do registo R2
segmento3:
    jb L2, segmento4; verifica se esta a 0
    inc R0; soma o valor do registo R2
segmento4:
    jb L3, segmento5; verifica se esta a 0
    inc R0; soma o valor do registo R2
segmento5:
    jb L4, segmento6; verifica se esta a 0
    inc R0; soma o valor do registo R2
segmento6:
    jb L5, segmento7; verifica se esta a 0
    inc R0; soma o valor do registo R2
segmento7:
    jb L6, segmento8; verifica se esta a 0
    inc R0; soma o valor do registo R2
segmento8:
    jb L7, fimDisplay; verifica se esta a 0
    inc R0; soma o valor do registo R2
fimDisplay:
    MOV P2, R0; coloca o valor do registo R0 na porta 2
ret

leSensor:
    jb sensor, bufferFimSensor; verifica se o sensor esta a 0
    setb bufferAbreBarreira; assinala que o carro passou 
bufferFimSensor:
    jnb bufferAbreBarreira, fimSensor; verifica se o carro passou
    jnb sensor, fimSensor; verifica se o sensor esta a 0
    setb passoucarro; assinala que o carro passou
    clr bufferAbreBarreira; limpa o buffer
fimSensor:
    ret

moveBarreira:
    jnb abreBarreira, elseBarreira; verifica se a barreira esta a abrir
    mov referenciaBarreira, #oitentaBarreira; coloca o valor de 80 na referencia da barreira
    mov a, contaBarreira; coloca o valor da contagem no registo A
    cjne a, referenciaBarreira, continuaMovimento; verifica se a contagem da barreira e menor que 80
    clr barreira; Barreira nao move
continuaMovimento:
    mov a, contaBarreira
    cjne a, #fimTempoBarreira, fimBarreira; verifica se a contagem da barreira e menor que 25ms
    mov contaBarreira, #0; limpa a contagem da barreira
    setb barreira; Barreira para cima
    jmp fimBarreira; salta para o fim da barreira
elseBarreira:
    mov referenciaBarreira, #zeroBarreira; coloca o valor de 0 na referencia da barreira
    mov a, contaBarreira ; coloca o valor da contagem no registo R0
    cjne a, referenciaBarreira, continuaMovimento2; verifica se a contagem da barreira e menor que 0
    clr barreira; Barreira nao move
    jmp fimBarreira; salta para o fim da barreira
continuaMovimento2:
    mov a, contaBarreira; coloca o valor da contagem no registo R0
    cjne a, #fimTempoBarreira, fimBarreira; verifica se a contagem da barreira e menor que 25ms
    mov contaBarreira, #0; limpa a contagem da barreira
    setb barreira; Barreira para baixo
    jmp fimBarreira; salta para o fim da barreira
fimBarreira:
    ret
END