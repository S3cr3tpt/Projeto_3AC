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
bit pressionado = 0; //para confirmar se o botao foi pressionado
bit passouCarro = 0; //confirmar se passou o carro

bit ledIntermitente = 0; //vai mudando entre 0 e 1 a cada segundo

unsigned int conta = 0; //para ajudar a contar 1 segundo
unsigned int contaSegundo = 0; //contador do timer a cada 1s
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
    IT0 = 1;//interrupcao esterna ativa a falling edge

    Leds = 0x00;
    P0 = Leds;
	
    ledVerde = 0; //led verde ligado
    ledVermelho = 1; //led vermelho desligado
    ledAmarelo = 1; //led amarelo desligado
		barreira = 0;//a barreira comeca para baixo
		sensor = 0;//inicializa o sensor a 0
		
    //comecar com o display de 7 segmentos a 9
    segmentoA = 0;
    segmentoB = 0;
    segmentoC = 0;
    segmentoD = 1; 
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
	switch (Leds){
    case 255:
        segmentoA = 0;
        segmentoB = 0;
        segmentoC = 0;
        segmentoD = 0;
        break;
    case 127:
        segmentoA = 1;
        segmentoB = 0;
        segmentoC = 0;
        segmentoD = 0;
        break;
    case 63:
        segmentoA = 0;
        segmentoB = 1;
        segmentoC = 0;
        segmentoD = 0;
        break;
    case 31:
        segmentoA = 1;
        segmentoB = 1;
        segmentoC = 0;
        segmentoD = 0;
        break;
    case 15:
        segmentoA = 0;
        segmentoB = 0;
        segmentoC = 1;
        segmentoD = 0;
        break;
    case 7:
        segmentoA = 1;
        segmentoB = 0;
        segmentoC = 1;
        segmentoD = 0;
        break;
    case 3:
        segmentoA = 0;
        segmentoB = 1;
        segmentoC = 1;
        segmentoD = 0;
        break;
    case 1:
        segmentoA = 1;
        segmentoB = 1;
        segmentoC = 1;
        segmentoD = 0;
        break;
    case 0:
        segmentoA = 0;
        segmentoB = 0;
        segmentoC = 0;
        segmentoD = 1;
        break;
    default:
        break;
    }
}

void leSensor(){
    if (sensor == 1){
        passouCarro = 1;
    }
}

void main(void){
    //inicializacoes
	Init();
    while (1){ //loop inifinito
        display();
        leSensor();
        if (conta == fimTempo){
            conta = 0; //volta a contar
            if (pressionado){    
                contaSegundo ++; //passou 1 segundo
                if (segmentoA || segmentoB || segmentoC || segmentoD || botao ){ //se tiver lugares ou se for para sair
                    ledVerde = 0; //ativa o verde
                    barreira = 1;//levanta a barreira
                    ledAmarelo = ~ledAmarelo;//fica intermitente
                    if (contaSegundo >= 10){//espera ate ser maior que 10 segundos 
                        if (passouCarro){
                            barreira = 0; //baixa a barreira 	
                            pressionado = 0; //volta a colocar o botao de passou a 0
                            contaSegundo = 0; //reseta o timer		
                            sensor = 0; //reseta o sensor	
                            ledAmarelo = 1; //desliga o led amareleo							
                            if (botao){//se for para entrar 
                                Leds = (Leds >> 1);//deslocar para a direita
                                P0 = Leds;  
                            }
                            else{//se for para sair    
                                Leds = (Leds << 1);//deslocar para a esquerda
                                Leds ++; //incrementa 1 nos lugares
                                P0 = Leds;
                            }
                        }
                    } 
                }else{
                    ledVermelho = 0;//ativa o led vermelho
                }
            }
        
        }
    }
}