
#include <wiring.h>
#include <avr/pgmspace.h>
#include "sht1x.h"

////////////////////////////////////////////////////////////////////////////////

// NOTE - hardware pins are as follows:
// (1) clock  - red
// (2) VDD=5v - black
// (3) GND=0v - black
// (4) data   - white

////////////////////////////////////////////////////////////////////////////////

void sht1x::transmission_start(void) {
   sda_is_output();
   sda_write(1);
   delay(2); // ms
   // It consists of a lowering of the DATA line while
   // SCK is high, followed by a low pulse on SCK and
   // raising DATA again while SCK is still high.
   // clock starts off high
   sck_write(1);
   spacer();
   // lower data while clock is high
   sda_write(0);
   spacer();
   // cycle clock down and up
   sck_write(0);
   spacer();
   sck_write(1);
   spacer();
   // raise data again while clock is still high
   sda_write(1);
   spacer();
   // "transmission start" sequence finished
   // but the manual has this tag-along sequence
   sck_write(0);
   spacer();
   sda_write(0);
   spacer();
}

////////////////////////////////////////////////////////////////////////////////

int sht1x::wait_for_ready(void) {
   sda_is_input(); // we'll be reading SDA
   for (uint16_t i=0;i<1000;i++) {
      delay(1); // ms
      uint8_t d=sda_read();
      if (d == 0x00) {
         // SENSOR IS READY!
         return 1;
      }
   }
   // ERROR
   //Serial.println("TIMEOUT");
   return 0;
}

////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------
void sht1x::calc(unsigned short t_in, unsigned short h_in, float & t_out ,float & h_out)
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
