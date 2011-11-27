
#include <LiquidCrystal.h>
#include <avr/pgmspace.h>
#include "sht1x.h"

#define LED   13

////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------
void calc_sth11(float t_in, float h_in, float & t_out ,float & h_out)
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
   Serial.begin(57600);
   Serial.println(__DATE__);
   Serial.println(__TIME__);
   tempsensor.init(2,3);
   // set up the LCD's number of columns and rows:
   lcd.begin(20, 4);
   lcd.noCursor();
   pinMode(LED,OUTPUT);
   delay(10); // milliseconds
}

////////////////////////////////////////////////////////////////////////////////

void loop() {
   // prepare displays
   char str[21];
   Serial.print("loop: ");
   lcd.clear();

   digitalWrite(LED, HIGH);

   // read temperature
   tempsensor.transmission_start();
   uint8_t ack=tempsensor.send_byte(MEASURE_TEMP);
   if (tempsensor.wait_for_ready()) { // about 80 millisecs
      uint8_t d1=tempsensor.recv_byte(1);
      uint8_t d2=tempsensor.recv_byte(1);
      uint8_t d3=tempsensor.recv_byte(0);
      tempsensor.stop();

      // compute
      unsigned short temp_c=(((unsigned short)d1 << 8) + (unsigned short)d2)-4010;
      unsigned short temp_f=(temp_c*9/5)+3200;

      // line 1
      sprintf(str,"d1=%02X d2=%02X d3=%02X",d1,d2,d3);
      Serial.print(str);
      Serial.print(" ");
      lcd.setCursor(0, 0);
      lcd.print(str);

      // line 2
      sprintf(str,"T=%d.%02dC=%d.%02dF",temp_c/100,temp_c%100,temp_f/100,temp_f%100);
      Serial.print(str);
      Serial.print(" ");
      lcd.setCursor(0, 1);
      lcd.print(str);

      // read humidity
      tempsensor.transmission_start();
      uint8_t ack=tempsensor.send_byte(MEASURE_HUMI);
      if (tempsensor.wait_for_ready()) { // about 80 millisecs
         uint8_t d4=tempsensor.recv_byte(1);
         uint8_t d5=tempsensor.recv_byte(1);
         uint8_t d6=tempsensor.recv_byte(0);
         tempsensor.stop();

         // compute
         float t_in=(float)((unsigned short)d1*256 + (unsigned short)d2);
         float h_in=(float)((unsigned short)d4*256 + (unsigned short)d5);
         float adj_temp_c;
         float adj_rel_humid;
         calc_sth11(t_in,h_in,adj_temp_c,adj_rel_humid);
         unsigned short int_tc=(unsigned short)(adj_temp_c * 100.0);
         unsigned short int_rh=(unsigned short)(adj_rel_humid * 100.0);

         // line 3
         sprintf(str,"T=%d.%02dC H=%d.%02d%%",int_tc/100,int_tc%100,int_rh/100,int_rh%100);
         Serial.print(str);
         lcd.setCursor(0, 2);
         lcd.print(str);

         // line 4

      }
   }
   Serial.println("");
   digitalWrite(LED, LOW);
   delay(2000); // milliseconds
}

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
