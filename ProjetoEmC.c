#include <reg51.h>

//constantes
#define fimTempo 4000  // 4000 *0.25ms = 1s
#define fimTempoBarreira 100 // 100 * 0.25ms = 25ms
#define zero 3 // 3*0.25ms = 0.75ms
#define oitenta 7// 7*0.25ms = 1.75ms

//Pins P0
sbit L0 = P0^0;
sbit L1 = P0^1;
sbit L2 = P0^2;
sbit L3 = P0^3;
sbit L4 = P0^4;
sbit L5 = P0^5;
sbit L6 = P0^6;
sbit L7 = P0^7;

//Pins P1
sbit ledVerde = P1^0; //pino do led verde
sbit ledVermelho = P1^1; //pino do led vermelho
sbit ledAmarelo = P1^2; //pino do led amarelo
sbit barreira = P1^3; //pino da barreira
sbit sensor = P1^4; //pino do sensor

//Pins P2
sbit segmentoA = P2^0; //pino do servo A
sbit segmentoB = P2^1; //pino do servo B
sbit segmentoC = P2^2; //pino do servo C
sbit segmentoD = P2^3; //pino do servo D

//variaveis globais
bit botao = 0; //se o botao estiver a 0 entao e uma entrada se estiver a 1 e uma saida
bit pressionado = 0; //para confirmar se o botao foi pressionado
bit passouCarro = 0; //confirmar se passou o carro
unsigned int conta = 0; //para ajudar a contar 1 segundo
unsigned int contaSegundo = 0; //contador do timer a cada 1s
unsigned int abreBarreira = 0; //para abrir a barreira
unsigned char referenciaBarreira = zero; //referencia da barreira
unsigned char contaBarreira = 0; //contador da barreira
unsigned char Leds; //Leds

void Init(void){
    //configuracao Registo IE
    EA = 1; //habilita interrupcao global
    ET0 = 1; //habilita interrupcao do timer 0
    EX0 = 1; //habilita interrupcao externa 0
    EX1 = 1; //habilita interrupcao externa 1

    //configuracao Registo TMOD
    TMOD &= 0xF0; // limpa os 4 bits do timer 0 (8 bits -auto reload)
    TMOD |= 0x02; //modo 2 do timer 0

    //configuracao Timer 0
    TR0 = 1; //inicia o timer 0
    TH0 = 0x06;
    TL0 = 0x06;
    IT0 = 1;//interrupcao esterna ativa a falling edge

    Leds = 0x00;
    P0 = Leds;
	
    //inicializa o display 
    P2 = 0x00; //inicializa o display a 0

    ledVerde = 0; //led verde ligado
    ledVermelho = 1; //led vermelho desligado
    ledAmarelo = 1; //led amarelo desligado
	barreira = 0;//a barreira comeca para baixo
	sensor = 1;//inicializa o sensor a 1
    

}

//interrupcao externa 0
void External0_ISR(void) interrupt 0{
    botao = 0; //assinala que o botao para entrar foi pressionado
    pressionado = 1;//foi pressionado
}

//interrupcao externa 1
void External1_ISR(void) interrupt 2{
    botao = 1; //assinala que o botao para sair foi pressionado
    pressionado = 1;//foi presionado
}

//interrupcao tempo a cada segundo
void Timer0_ISR(void) interrupt 1{
    conta ++;
}

void display(void){
    unsigned int Segmentos = 0;
    if (~(L0)) {Segmentos += 1;}
    if (~(L1)) {Segmentos += 1;}
    if (~(L2)) {Segmentos += 1;}
    if (~(L3)) {Segmentos += 1;}
    if (~(L4)) {Segmentos += 1;}
    if (~(L5)) {Segmentos += 1;}
    if (~(L6)) {Segmentos += 1;}
    if (~(L7)) {Segmentos += 1;}
    P2 = Segmentos; //atualiza o display
}

void leSensor(){
    if (sensor == 0){
        passouCarro = 1;
    }
}

void moveBarreira(void){
    contaBarreira++;
    if (abreBarreira){
        referenciaBarreira = oitenta; //se o carro passou entao a barreira tem de ir para 80

        if (contaBarreira == referenciaBarreira){
            barreira = 0; //se ja chegou ao sitio certo entao fica igual
        }
        if (contaBarreira ==  fimTempoBarreira){
            contaBarreira = 0; //reseta o contador
            barreira = 1; //levanta a barreira
        }
    }else{
        referenciaBarreira = zero; //se o carro passou entao a barreira tem de ir para 0

        if (contaBarreira == referenciaBarreira){
            barreira = 1; //se ja chegou ao sitio certo entao fica igual
        }
        if (contaBarreira ==  fimTempoBarreira){
            contaBarreira = 0; //reseta o contador
            barreira = 0; //baixa a barreira 
            //depois testar como e que se baixa a barreira
        }
    }
}

void main(void){
    //inicializacoes
	Init();
    while (1){ //loop inifinito
        display();
        leSensor();
        moveBarreira();
        if (conta == fimTempo){
              conta = 0; //volta a contar
            if (segmentoA || segmentoB || segmentoC || segmentoD || botao){    
                if (pressionado){ //se tiver lugares ou se for para sair
                    contaSegundo ++; //passou 1 segundo
                    ledVerde = 0; //ativa o verde
                    ledVermelho = 1; //desliga o vermelho
                    ledAmarelo = ~ledAmarelo; //amarelo intermitente
                    abreBarreira = 1;//levanta a barreira
                    if (contaSegundo >= 10){//espera ate ser maior que 10 segundos 
                        if (passouCarro){
                            abreBarreira = 0; //baixa a barreira 
                            passouCarro = 0; //reseta o carro
                            pressionado = 0; //volta a colocar o botao de passou a 0
                            contaSegundo = 0; //reseta o timer		
                            sensor = 1; //reseta o sensor	
                            ledAmarelo = 1; //desliga o led amareleo							
                        }
                    } 
                }
            }else{
                    ledVermelho = 0;//ativa o led vermelho
                    ledVerde = 1; //desliga o led verde
                }
        }
    }
}