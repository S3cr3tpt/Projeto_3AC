#include <reg51.h>

#define fimTempo 60000  // para so fazer operacoes de segundo a segundo

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

//constantes
bit botao = 0; //se o botao estiver a 0 entao e uma entrada se estiver a 1 e uma saida
bit passouCarro = 0; 

bit ledIntermitente = 0; //vai mudando entre 0 e 1 a cada segundo

unsigned int conta = 0; //para ajudar a contar 1 segundo
unsigned int contaSegundo = 0; //contador do timer a cada 1s
unsigned int Leds = 0; //variavel temporaria

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
    IT0 = 1;//interrupcao esterna ativa a falling edge

    P0 = Leds;
    
    ledVerde = 0; //led verde ligado
    ledVermelho = 1; //led vermelho desligado
    ledAmarelo = 1; //led amarelo desligado

    //comecar com o display de 7 segmentos a 9
    segmentoA = 0;
    segmentoB = 0;
    segmentoC = 0;
    segmentoD = 1; 
}

//interrupcao externa 0
void External0_ISR(void) interrupt 0{
    botao = 0; //assinala que o botao para entrar foi pressionado

}

//interrupcao externa 1
void External1_ISR(void) interrupt 2{
    botao = 1; //assinala que o botao para sair foi pressionado
}

//interrupcao tempo a cada segundo
void Timer0_ISR(void) interrupt 1{
    conta ++;
}

void display(void){

}

void leSensor(){
    sensor = 1; //so para testar
}

void main(void){
    //inicializacoes

	Init();
    while (1){ //loop inifinito
        display();
        if (conta == fimTempo){
            conta = 0; //volta a contar
            contaSegundo = 10; //passou 1 segundo
            if (segmentoA || segmentoB || segmentoC || segmentoD || botao){ //se tiver lugares ou se for para sair
                leSensor();
                barreira = 1;//levanta a barreira
                if (contaSegundo >= 10){//espera ate ser maior que 10 segundos 
                    if (sensor){
						barreira = 0; //baixa a barreira 											
                        if (botao){//se for para entrar 
                            Leds = (Leds >> 1) | (Leds << 7);//deslocar para a esquerda
                            P0 = Leds;  
                            //sensor = 0;//volta a colocar o sensor a 0
                        }
                        else{//se for para sair    
                            Leds = (Leds << 1) | (Leds >> 7);//deslocar para a direita
                            P0 = Leds;
                            P0 = P0 + 1;
                            Leds = P0; //atualiza os Leds
                            //sensor = 0;//volta a colocar o sensor a 0
                        }
                    }
                }
            }
        }
    }
}