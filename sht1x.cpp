
#include <wiring.h>
#include <avr/pgmspace.h>
#include "sht1x.h"

////////////////////////////////////////////////////////////////////////////////

sht1x::sht1x(void) {
}

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
