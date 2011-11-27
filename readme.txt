
/*

#define BYTE  unsigned char
#define SCK   8
#define SDA   9
                           //adr cmnd r/w
#define STATUS_REG_W 0x06  //000 0011 0
#define STATUS_REG_R 0x07  //000 0011 1
#define MEASURE_TEMP 0x03  //000 0001 1
#define MEASURE_HUMI 0x05  //000 0010 1
#define RESET        0x1e  //000 1111 0

void start() {
   Serial.begin(57600);
   i2c_init();
}

void loop() {
   Serial.println("loop");
   i2c_start();
   i2c_send_byte(STATUS_REG_R);
   i2c_send_byte(MEASURE_TEMP);
   //wait until sensor has finished the measurement
   for (i=0;i<65535;i++) {
      if(SDA==0) break;
   if(SDA) error+=1;

}

BYTE wait_for_read() {
   pinMode(SDA,INPUT);
   for (i=0;i<65535;i++) {
      BYTE d=digitalRead(SDA);
      if (d==0) return 0;
   }
   return 1;
}

////////////////////////////////////////////////////////////////////////////////
//   HIGH-LEVEL I2C
////////////////////////////////////////////////////////////////////////////////

void i2c_init(void) {
   // set up lines
   pinMode(SCK,OUTPUT);
   pinMode(SDA,OUTPUT);
   // send initial STOP condition
   digitalWrite(SDA, LOW);
   digitalWrite(SCK, HIGH);
   digitalWrite(SDA, HIGH);
}

////////////////////////////////////////////////////////////////////////////////

void i2c_send(BYTE * b, BYTE count) {
   BYTE c=0;
   i2c_start();
   while(c<count) {
      i2c_send_byte(b[c++]);
   }
   i2c_stop();
}

////////////////////////////////////////////////////////////////////////////////
//   LOW-LEVEL I2C
////////////////////////////////////////////////////////////////////////////////

void i2c_start(void) {
   digitalWrite(SDA, LOW);
   digitalWrite(SCK, LOW);
}

////////////////////////////////////////////////////////////////////////////////

void i2c_send_byte(BYTE b) {
   BYTE mask;
   for(mask=0x80;mask;mask>>=1) {
      // present the data bit while the clock is low
      if(b&mask) {
         digitalWrite(SDA, HIGH);
      } else {
         digitalWrite(SDA, LOW);
      }
      // pulse clock line
      digitalWrite(SCK, HIGH);
      digitalWrite(SCK, LOW);
   }
   // send ACK pulse
   pinMode(SDA,OUTPUT);
   digitalWrite(SCK, HIGH);
   digitalWrite(SCK, LOW);
   pinMode(SDA,INPUT);
}

////////////////////////////////////////////////////////////////////////////////

BYTE i2c_recv_byte(BYTE ack) {
   BYTE data=0;
   // release SDA line
   pinMode(SDA,INPUT);
   // cycle clock and read bits in
   BYTE mask;
   for(mask=0x80;mask;mask>>=1) {
      digitalWrite(SCK, HIGH);
      BYTE inbit = digitalRead(SDA);
      if (inbit) data=data|mask;
      digitalWrite(SCK, LOW);
   }
   pinMode(SDA,OUTPUT);
   // send ACK pulse
   digitalWrite(SDA, ack?LOW:HIGH);
   digitalWrite(SCK, HIGH);
   // TODO - wait 5 usec
   digitalWrite(SCK, LOW);
   // release data line
   pinMode(SDA,INPUT);
   return data;
}

////////////////////////////////////////////////////////////////////////////////

void i2c_stop(void) {
   digitalWrite(SDA, LOW);
   digitalWrite(SCK, HIGH);
   digitalWrite(SDA, HIGH);
}

////////////////////////////////////////////////////////////////////////////////
































/*



//**********************************************************************************
// Project: SHT1x/7x demo program (V2.4)
// Filename: SHT1x_sample_code.c
// Prozessor: 80C51 family
// Compiler: Keil Version 6.23a
// Autor: MST
// Copyrigth: (c) Sensirion AG
//**********************************************************************************
// Revisions:
// V2.4 calc_sht11() Coefficients for humidity and temperature conversion
// changed (for V4 sensors)
// calc_dewpoint() New formula for dew point calculation

#include <AT89s53.h>
#include <intrins.h>
#include <math.h>
#include <stdio.h>
//Microcontroller specific library, e.g. port definitions
//Keil library (is used for _nop()_ operation)
//Keil library
//Keil library
typedef union
{
 unsigned int i;
float f;
} value;








//----------------------------------------------------------------------------------
// modul-var
//----------------------------------------------------------------------------------
enum {TEMP,HUMI};
#define SDA P1_1
#define SCK P1_0
#define noACK 0
#define ACK 1

                           //adr command    r/w
#define STATUS_REG_W 0x06  //000 0011       0
#define STATUS_REG_R 0x07  //000 0011       1
#define MEASURE_TEMP 0x03  //000 0001       1
#define MEASURE_HUMI 0x05  //000 0010       1
#define RESET        0x1e  //000 1111       0

//----------------------------------------------------------------------------------
char s_write_byte(unsigned char value)
//----------------------------------------------------------------------------------
// writes a byte on the Sensibus and checks the acknowledge
{
   unsigned char i,error=0;
   for (i=0x80;i>0;i/=2)
   //shift bit for masking
   {
      if (i & value) SDA=1;
      //masking value with i , write to SENSI-BUS
      else SDA=0;
      _nop_();
      //observe setup time
      SCK=1;
      //clk for SENSI-BUS
      _nop_();_nop_();_nop_();
      //pulswith approx. 5 us
      SCK=0;
      _nop_();
      //observe hold time
   }
   SDA=1;
   //release SDA-line
   _nop_();
   //observe setup time
   SCK=1;
   //clk #9 for ack
   error=SDA;
   //check ack (SDA will be pulled down by SHT11)
   SCK=0;
   return error;
   //error=1 in case of no acknowledge
}

//----------------------------------------------------------------------------------
char s_read_byte(unsigned char ack)
//----------------------------------------------------------------------------------
// reads a byte form the Sensibus and gives an acknowledge in case of "ack=1"
{
   unsigned char i,val=0;
   SDA=1;
   //release SDA-line
   for (i=0x80;i>0;i/=2)
   //shift bit for masking
   {
      SCK=1;
      //clk for SENSI-BUS
      if (SDA) val=(val | i);
      //read bit
      SCK=0;
   }
   SDA=!ack;
   //in case of "ack==1" pull down SDA-Line
   _nop_();
   //observe setup time
   SCK=1;
   //clk #9 for ack
   _nop_();_nop_();_nop_();
   //pulswith approx. 5 us
   SCK=0;
   _nop_();
   //observe hold time
   SDA=1;
   //release SDA-line
   return val;
}

//----------------------------------------------------------------------------------
void s_transstart(void)
//----------------------------------------------------------------------------------
// generates a transmission start
//        _____         ________
// SDA:       |_______|
//            ___     ___
// SCK :  ___|   |___|   |______
{
   SDA=1; SCK=0;
   //Initial state
   _nop_();
   SCK=1;
   _nop_();
   SDA=0;
   _nop_();
   SCK=0;
   _nop_();_nop_();_nop_();
   SCK=1;
   _nop_();
   SDA=1;
   _nop_();
   SCK=0;
}



//----------------------------------------------------------------------------------
void s_connectionreset(void)
//----------------------------------------------------------------------------------
// communication reset: SDA-line=1 and at least 9 SCK cycles followed by transstart
//        _____________________________________________________         ________
// SDA:                                                       |_______|
//           _    _    _    _    _    _    _    _    _        ___     ___
// SCK :  __| |__| |__| |__| |__| |__| |__| |__| |__| |______|   |___|   |______
{
   unsigned char i;
   SDA=1; SCK=0; //Initial state
   for(i=0;i<9;i++)
   //9 SCK cycles
   {
      SCK=1;
      SCK=0;
   }
   s_transstart(); //transmission start
}

//----------------------------------------------------------------------------------
char s_softreset(void)
//----------------------------------------------------------------------------------
// resets the sensor by a softreset
{
   unsigned char error=0;
   s_connectionreset(); //reset communication
   error+=s_write_byte(RESET); //send RESET-command to sensor
   return error; //error=1 in case of no response form the sensor
}


//----------------------------------------------------------------------------------
char s_read_statusreg(unsigned char *p_value, unsigned char *p_checksum)
//----------------------------------------------------------------------------------
// reads the status register with checksum (8-bit)
{
   unsigned char error=0;
   s_transstart(); //transmission start
   error=s_write_byte(STATUS_REG_R); //send command to sensor
   *p_value=s_read_byte(ACK); //read status register (8-bit)
   *p_checksum=s_read_byte(noACK); //read checksum (8-bit)
   return error; //error=1 in case of no response form the sensor
}


//----------------------------------------------------------------------------------
char s_write_statusreg(unsigned char *p_value)
//----------------------------------------------------------------------------------
// writes the status register with checksum (8-bit)
{
   unsigned char error=0;
   s_transstart();
   //transmission start
   error+=s_write_byte(STATUS_REG_W);//send command to sensor
   error+=s_write_byte(*p_value);
   //send value of status register
   return error;
   //error>=1 in case of no response form the sensor
}
//----------------------------------------------------------------------------------
char s_measure(unsigned char *p_value, unsigned char *p_checksum, unsigned char
mode)
//----------------------------------------------------------------------------------
// makes a measurement (humidity/temperature) with checksum
{
unsigned char error=0;
unsigned int i;
s_transstart();
//transmission start
switch(mode){
//send command to sensor
case TEMP : error+=s_write_byte(MEASURE_TEMP); break;
case HUMI : error+=s_write_byte(MEASURE_HUMI); break;
default
: break;
}
for (i=0;i<65535;i++) if(SDA==0) break; //wait until sensor has finished the
measurement
if(SDA) error+=1;
// or timeout (~2 sec.) is reached
*(p_value) =s_read_byte(ACK);
//read the first byte (MSB)
*(p_value+1)=s_read_byte(ACK);
//read the second byte (LSB)
*p_checksum =s_read_byte(noACK); //read checksum
return error;
}




//----------------------------------------------------------------------------------
void init_uart()
//----------------------------------------------------------------------------------
//9600 bps @ 11.059 MHz
{SCON = 0x52;
TMOD = 0x20;
TCON = 0x69;
TH1
= 0xfd;
}
//----------------------------------------------------------------------------------
void calc_sth11(float *p_humidity ,float *p_temperature)
//----------------------------------------------------------------------------------
// calculates temperature [°C] and humidity [%RH]
// input : humi [Ticks] (12 bit)
//
temp [Ticks] (14 bit)
// output: humi [%RH]
//
temp [°C]
{ const float C1=-2.0468;
// for 12 Bit RH
const float C2=+0.0367;
// for 12 Bit RH
const float C3=-0.0000015955;
// for 12 Bit RH
const float T1=+0.01;
// for 12 Bit RH
const float T2=+0.00008;
// for 12 Bit RH
float
float
float
float
float
rh=*p_humidity;
t=*p_temperature;
rh_lin;
rh_true;
t_C;
//
//
//
//
//
rh:
t:
rh_lin:
rh_true:
t_C
:
Humidity [Ticks] 12 Bit
Temperature [Ticks] 14 Bit
Humidity linear
Temperature compensated humidity
Temperature [°C]
t_C=t*0.01 - 40.1;
//calc. temperature[°C]from 14 bit temp.ticks @5V
rh_lin=C3*rh*rh + C2*rh + C1;
//calc. humidity from ticks to [%RH]
rh_true=(t_C-25)*(T1+T2*rh)+rh_lin;
//calc. temperature compensated humidity
[%RH]
if(rh_true>100)rh_true=100;
//cut if the value is outside of
if(rh_true<0.1)rh_true=0.1;
//the physical possible range
*p_temperature=t_C;
*p_humidity=rh_true;
//return temperature [°C]
//return humidity[%RH]
}
//--------------------------------------------------------------------
float calc_dewpoint(float h,float t)
//--------------------------------------------------------------------
// calculates dew point
// input:
humidity [%RH], temperature [°C]
// output: dew point [°C]
{ float k,dew_point ;
k = (log10(h)-2)/0.4343 + (17.62*t)/(243.12+t);
dew_point = 243.12*k/(17.62-k);
return dew_point;
}





//----------------------------------------------------------------------------------
void main()
//----------------------------------------------------------------------------------
// sample program that shows how to use SHT11 functions
// 1. connection reset
// 2. measure humidity [ticks](12 bit) and temperature [ticks](14 bit)
// 3. calculate humidity [%RH] and temperature [°C]
// 4. calculate dew point [°C]
// 5. print temperature, humidity, dew point
{ value humi_val,temp_val;
float dew_point;
unsigned char error,checksum;
unsigned int i;
init_uart();
s_connectionreset();
while(1)
{ error=0;
error+=s_measure((unsigned char*) &humi_val.i,&checksum,HUMI); //measure
humidity
error+=s_measure((unsigned char*) &temp_val.i,&checksum,TEMP); //measure
temperature
if(error!=0) s_connectionreset();
//in case of an error: connection reset
else
{ humi_val.f=(float)humi_val.i;
//converts integer to float
temp_val.f=(float)temp_val.i;
//converts integer to float
calc_sth11(&humi_val.f,&temp_val.f);
//calculate humidity,
temperature
dew_point=calc_dewpoint(humi_val.f,temp_val.f); //calculate dew point
printf("temp:%5.1fC humi:%5.1f%% dew
point:%5.1fC\n",temp_val.f,humi_val.f,dew_point);
}
//----------wait approx. 0.8s to avoid heating up SHTxx-----------------------------
for (i=0;i<40000;i++); //(be sure that the compiler doesn't eliminate this line!)
//----------------------------------------------------------------------------------
}
}


*/


