
#include <LiquidCrystal.h>
#include <avr/pgmspace.h>
#include "sht1x.h"

#define LED   13
#define LIGHT  0
#define BACKLIGHT 6

#define TEMP_LO 7200
#define TEMP_HI 8000
#define HUMI_LO 7000
#define HUMI_HI 8000
typedef enum { LO, OK, HI } lohi_t;
char * describe[] = {"LOW","OK","HIGH"};

////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------
void calc_sth11(unsigned short t_in, unsigned short h_in, float & t_out ,float & h_out)
//----------------------------------------------------------------------------------
// calculates temperature [°C] and humidity [%RH]
// input : h_in [Ticks] (12 bit)
//         t_in [Ticks] (14 bit)
// output: h_out [%RH]
//         t_out [°C]
{
   const float C1=-2.0468;        // for 12 Bit RH
   const float C2=+0.0367;        // for 12 Bit RH
   const float C3=-0.0000015955;  // for 12 Bit RH
   const float T1=+0.01;          // for 12 Bit RH
   const float T2=+0.00008;       // for 12 Bit RH
   float rh=h_in;           // rh:      Humidity [Ticks] 12 Bit
   float t=t_in;            // t:       Temperature [Ticks] 14 Bit
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
   t_out=t_C;
   //return humidity[%RH]
   h_out=rh_true;
}

////////////////////////////////////////////////////////////////////////////////

static sht1x tempsensor;
static LiquidCrystal lcd(7,8,9,10,11,12);

void setup() {
   // set up serial port
   Serial.begin(57600);
   Serial.println(__DATE__);
   Serial.println(__TIME__);
   // set up temperature/humidity sensor
   tempsensor.init(2,3);
   // set up the LCD's number of columns and rows:
   lcd.begin(20, 4);
   lcd.noCursor();
   // set up GPIOs
   pinMode(LED,OUTPUT);
   pinMode(BACKLIGHT,OUTPUT);
}

////////////////////////////////////////////////////////////////////////////////

void loop() {
   char str[21];

   int lightlevel=analogRead(LIGHT);
   lightlevel=map(lightlevel,1023,0,0,255);  // adjust to 0-255 range
   lightlevel=constrain(lightlevel,1,255);  // bound within 0-255
   analogWrite(BACKLIGHT,lightlevel);

   // starting to read sensors
   digitalWrite(LED, HIGH);

   // read temperature
   tempsensor.transmission_start();
   uint8_t t_ack=tempsensor.send_byte(MEASURE_TEMP);
   tempsensor.wait_for_ready(); // about 80 millisecs
   uint8_t d1=tempsensor.recv_byte(1);
   uint8_t d2=tempsensor.recv_byte(1);
   uint8_t d3=tempsensor.recv_byte(0);
   tempsensor.stop();

   // read humidity
   tempsensor.transmission_start();
   uint8_t h_ack=tempsensor.send_byte(MEASURE_HUMI);
   tempsensor.wait_for_ready(); // about 80 millisecs
   uint8_t d4=tempsensor.recv_byte(1);
   uint8_t d5=tempsensor.recv_byte(1);
   uint8_t d6=tempsensor.recv_byte(0);
   tempsensor.stop();

   // done reading sensors
   digitalWrite(LED, LOW);

   // compute relative humidity
   unsigned short t_in=d1*256 + d2;
   unsigned short h_in=d4*256 + d5;
   float adj_temp_c;
   float adj_rel_humid;
   calc_sth11(t_in,h_in,adj_temp_c,adj_rel_humid);

   // integer values for printing
   unsigned short int_tc=(unsigned short)(adj_temp_c * 100.0);
   unsigned short int_tf=(int_tc*9/5)+3200;
   unsigned short int_rh=(unsigned short)(adj_rel_humid * 100.0);

   // prepare displays
   Serial.print("loop: ");
   lcd.clear();

   // line 1
   sprintf(str,"%02X,%02X%02X%02X,%02X%02X%02X",lightlevel,d1,d2,d3,d4,d5,d6);
   Serial.println(str);
   lcd.setCursor(0, 0);
   lcd.print(str);

   // line 2
   sprintf(str,"temp=%d.%02dC/%d.%02dF",int_tc/100,int_tc%100,int_tf/100,int_tf%100);
   Serial.println(str);
   lcd.setCursor(0, 1);
   lcd.print(str);

   // line 3
   sprintf(str,"rel.humidity=%d.%02d%%",int_rh/100,int_rh%100);
   Serial.println(str);
   lcd.setCursor(0, 2);
   lcd.print(str);

   // line 4

   // find ranges: LO-OK-HI
   lohi_t temp_ok=LO;
   if (int_tf >= TEMP_LO) temp_ok=OK;
   if (int_tf > TEMP_HI) temp_ok=HI;
   lohi_t humi_ok=LO;
   if (int_rh >= HUMI_LO) humi_ok=OK;
   if (int_rh > HUMI_HI) humi_ok=HI;

   if ((temp_ok==OK)&&(humi_ok==OK)) {
      sprintf(str,"happy crabby!");
   } else {
      sprintf(str,"TEMP %s, RH %s",describe[temp_ok],describe[humi_ok]);
   }
   Serial.println(str);
   lcd.setCursor(0, 3);
   lcd.print(str);

   // end loop
   Serial.println("");
   delay(2000); // milliseconds
}

////////////////////////////////////////////////////////////////////////////////

