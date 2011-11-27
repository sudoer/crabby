
#ifndef uint8
#define uint8  unsigned char
#endif
#ifndef uint16
#define uint16  unsigned short
#endif

#define LED   13
//#define SCK   8
//#define SDA   9

// CLOCK & DATA PINS
#define SCK_BIT  5
#define SDA_BIT  6
#define SCK_PORT PORTD
#define SDA_PORT PORTD
#define SDA_PIN  PIND
#define SCK_DDR  DDRD
#define SDA_DDR  DDRD

// BITWISE OPERATIONS
#define BITSET(name,bitn)  ((name)|=(0x01<<(bitn)))
#define BITCLR(name,bitn)  ((name)&=~(0x01<<(bitn)))
#define BITTST(name,bitn)  ((name) & (0x01<<(bitn)))
#define BITNOT(name,bitn)  ((name)^=(0x01<<(bitn)))
#define MASKSET(name,mask)  ((name)|=(mask))
#define MASKCLR(name,mask)  ((name)&=~(mask))
#define MASKTST(name,mask)  ((name) & (mask))
#define MASKNOT(name,mask)  ((name)^=(mask))

// PRIMITIVE PIN OPERATIONS
#define I2C_SCK_OUTPUT     BITSET(SCK_DDR,SCK_BIT)
#define I2C_SCK_WRITE(hl)  ((hl)?BITSET(SCK_PORT,SCK_BIT):BITCLR(SCK_PORT,SCK_BIT))
#define I2C_SDA_INPUT      BITCLR(SDA_DDR,SDA_BIT) ; BITSET(SDA_PORT,SDA_BIT);
#define I2C_SDA_READ       ((BITTST(SDA_PIN,SDA_BIT))?1:0)
#define I2C_SDA_OUTPUT     BITSET(SDA_DDR,SDA_BIT)
#define I2C_SDA_WRITE(hl)  ((hl)?BITSET(SDA_PORT,SDA_BIT):BITCLR(SDA_PORT,SDA_BIT))
#define I2C_DELAY          delayMicroseconds(100);
#define I2C_PAUSE          delayMicroseconds(1000);

                           //adr cmnd r/w
#define STATUS_REG_W 0x06  //000 0011 0
#define STATUS_REG_R 0x07  //000 0011 1
#define MEASURE_TEMP 0x03  //000 0001 1
#define MEASURE_HUMI 0x05  //000 0010 1
#define RESET        0x1e  //000 1111 0

////////////////////////////////////////////////////////////////////////////////

void setup();
void loop();
int wait_for_sensor_ready();
void i2c_init(void);
uint8 i2c_send(uint8 * b, uint8 count);
void i2c_start(void);
void i2c_reset(void);
uint8 i2c_send_byte(uint8 b);
uint8 i2c_recv_byte(uint8 ack);
void i2c_stop(void);
//void calc_sth11(float *p_humidity ,float *p_temperature);

////////////////////////////////////////////////////////////////////////////////

void setup() {
   Serial.begin(57600);
   Serial.println(__DATE__);
   Serial.println(__TIME__);
   i2c_init();
   //i2c_reset();
   pinMode(LED,OUTPUT);
   delay(10); // milliseconds
}

////////////////////////////////////////////////////////////////////////////////

void loop() {
   Serial.println("loop");
   digitalWrite(LED, HIGH);
   I2C_SCK_WRITE(1); // why is this low ??
   delay(2); // milliseconds
   //i2c_reset();
   transmission_start();
   uint8 ack=i2c_send_byte(MEASURE_TEMP);
   // sensor chip will set ack=0
   if (wait_for_sensor_ready()) { // about 80 millisecs
      uint8 d1=i2c_recv_byte(1);
      uint8 d2=i2c_recv_byte(1);
      uint8 d3=i2c_recv_byte(0);
      i2c_stop();
      Serial.print("d1=");
      Serial.print(d1,HEX);
      Serial.print(" d2=");
      Serial.print(d2,HEX);
      Serial.print(" d3=");
      Serial.print(d3,HEX);
      unsigned short temp_int=(((unsigned short)d1 << 8) + (unsigned short)d2)-4010;
      Serial.print(" T=");
      Serial.print(temp_int/100,DEC);
      Serial.print(".");
      Serial.print(temp_int%100,DEC);
      Serial.println("*C");
   }
   digitalWrite(LED, LOW);
   delay(2000); // milliseconds
}

////////////////////////////////////////////////////////////////////////////////

int wait_for_sensor_ready() {
   I2C_SDA_INPUT; // we'll be reading SDA
   for (uint16 i=0;i<1000;i++) {
      digitalWrite(LED,LOW);
      delay(1);
      digitalWrite(LED,HIGH);
      uint8 d=I2C_SDA_READ;
      if (d == 0x00) {
         // SENSOR IS READY!
         digitalWrite(LED, LOW);
         delay(1);
         digitalWrite(LED,HIGH);
         return 1;
      }
   }
   // ERROR
   Serial.println("TIMEOUT");
   return 0;
}

////////////////////////////////////////////////////////////////////////////////
//   LOW-LEVEL I2C
////////////////////////////////////////////////////////////////////////////////

void i2c_init(void) {
   // SCK is always an output
   I2C_SCK_OUTPUT;
   I2C_SDA_WRITE(1);
   // SDA is an output for now
   I2C_SDA_OUTPUT;
   I2C_SDA_WRITE(1);
}

////////////////////////////////////////////////////////////////////////////////

void i2c_start(void) {
   I2C_SDA_OUTPUT;
   I2C_SDA_WRITE(0);
   I2C_DELAY;
   I2C_SCK_WRITE(0);
   I2C_DELAY;
}

////////////////////////////////////////////////////////////////////////////////

void i2c_reset(void) {
   I2C_SDA_OUTPUT;
   I2C_SDA_WRITE(1);
   I2C_SCK_WRITE(0);
   int i;
   for(i=0;i<9;i++) {
      I2C_SCK_WRITE(1);
      I2C_DELAY;
      I2C_SCK_WRITE(0);
      I2C_DELAY;
   }
}

////////////////////////////////////////////////////////////////////////////////

uint8 i2c_send_byte(uint8 b) {
   //Serial.print("send=");
   //Serial.println(b,HEX);
   uint8 errors=0;
   uint8 mask;
   I2C_SDA_OUTPUT;
   for(mask=0x80;mask;mask>>=1) {
      // present the data bit while the clock is low
      I2C_SDA_WRITE((b&mask)?1:0);
      I2C_DELAY;
      // pulse clock line
      I2C_SCK_WRITE(1);
      I2C_DELAY;
      I2C_SCK_WRITE(0);
      I2C_DELAY;
   }
   // send ACK pulse, read his ACK
   I2C_SDA_INPUT;
   I2C_SCK_WRITE(1);
   // receiver should pull SDA low here
   I2C_DELAY;
   errors=I2C_SDA_READ;
   I2C_SCK_WRITE(0);
   I2C_SDA_OUTPUT;
   I2C_DELAY;
   if (errors) {
      //Serial.print("send_byte error=");
      //Serial.println(errors,HEX);
   }
   return errors;
}

////////////////////////////////////////////////////////////////////////////////

uint8 i2c_recv_byte(uint8 ack) {
   uint8 b=0;
   // release SDA line
   I2C_SDA_INPUT;
   // cycle clock and read bits in
   uint8 mask;
   for(mask=0x80;mask;mask>>=1) {
      I2C_SCK_WRITE(1);
      I2C_DELAY;
      uint8 inbit = I2C_SDA_READ;
      if (inbit) b=b|mask;
      I2C_SCK_WRITE(0);
      I2C_DELAY;
   }
   // send ACK pulse
   I2C_SDA_OUTPUT;
   I2C_SDA_WRITE(ack?0:1);
   I2C_SCK_WRITE(1);
   I2C_DELAY;
   I2C_SCK_WRITE(0);
   I2C_DELAY;
   // release data line
   I2C_SDA_INPUT;
   //Serial.print("recv=");
   //Serial.println(b,HEX);
   return b;
}

////////////////////////////////////////////////////////////////////////////////

void i2c_stop(void) {
   I2C_SDA_OUTPUT;
   I2C_SDA_WRITE(0);
   I2C_DELAY;
   I2C_SCK_WRITE(1);
   I2C_DELAY;
   I2C_SDA_WRITE(1);
   I2C_DELAY;
}

////////////////////////////////////////////////////////////////////////////////
//   SPECIAL FUNCTIONS FOR TEMP/HUMID SENSOR
////////////////////////////////////////////////////////////////////////////////

void transmission_start() {
   I2C_SDA_OUTPUT;
   I2C_SDA_WRITE(1);
   delay(2); // ms
   // It consists of a lowering of the DATA line while
   // SCK is high, followed by a low pulse on SCK and
   // raising DATA again while SCK is still high.
   // clock starts off high
   I2C_SCK_WRITE(1);
   I2C_PAUSE;
   // lower data while clock is high
   I2C_SDA_WRITE(0);
   I2C_DELAY;
   // cycle clock down and up
   I2C_SCK_WRITE(0);
   I2C_DELAY;
   I2C_SCK_WRITE(1);
   I2C_DELAY;
   // raise data again while clock is still high
   I2C_SDA_WRITE(1);
   I2C_DELAY;
   // "transmission start" sequence finished
   // but the manual has this tag-along sequence
   I2C_SCK_WRITE(0);
   I2C_DELAY;
   I2C_SDA_WRITE(0);
   I2C_DELAY;
}

////////////////////////////////////////////////////////////////////////////////
//   TEMPERATURE / HUMIDITY CALCULATIONS
////////////////////////////////////////////////////////////////////////////////

/*
//----------------------------------------------------------------------------------
void calc_sth11(float *p_humidity ,float *p_temperature)
//----------------------------------------------------------------------------------
// calculates temperature [°C] and humidity [%RH]
// input : humi [Ticks] (12 bit)
//         temp [Ticks] (14 bit)
// output: humi [%RH]
//         temp [°C]
{
   const float C1=-2.0468;        // for 12 Bit RH
   const float C2=+0.0367;        // for 12 Bit RH
   const float C3=-0.0000015955;  // for 12 Bit RH
   const float T1=+0.01;          // for 12 Bit RH
   const float T2=+0.00008;       // for 12 Bit RH
   float rh=*p_humidity;    // rh:      Humidity [Ticks] 12 Bit
   float t=*p_temperature;  // t:       Temperature [Ticks] 14 Bit
   float rh_lin;            // rh_lin:  Humidity linear
   float rh_true;           // rh_true: Temperature compensated humidity
   float t_C;               // t_C:     Temperature [°C]

   // calc. temperature[°C]from 14 bit temp.ticks @5V
   t_C=t*0.01 - 40.1;

   // calc. humidity from ticks to [%RH]
   rh_lin=C3*rh*rh + C2*rh + C1;

   // calc. temperature compensated humidity [%RH]
   rh_true=(t_C-25)*(T1+T2*rh)+rh_lin;

   // cut if the value is outside of
   //the physical possible range
   if(rh_true>100)rh_true=100;
   if(rh_true<0.1)rh_true=0.1;

   //return temperature [°C]
   *p_temperature=t_C;
   //return humidity[%RH]
   *p_humidity=rh_true;
}
*/































/*



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


