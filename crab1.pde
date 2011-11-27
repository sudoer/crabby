
#include <avr/pgmspace.h>
#include "sht1x.h"

#define LED   13

////////////////////////////////////////////////////////////////////////////////

static sht1x tempsensor;

void setup() {
   Serial.begin(57600);
   Serial.println(__DATE__);
   Serial.println(__TIME__);
   tempsensor.init(5,6);
   pinMode(LED,OUTPUT);
   delay(10); // milliseconds
}

////////////////////////////////////////////////////////////////////////////////

void loop() {
   Serial.println("loop");
   tempsensor.transmission_start();
   uint8_t ack=tempsensor.send_byte(MEASURE_TEMP);
   // sensor chip will set ack=0
   if (tempsensor.wait_for_ready()) { // about 80 millisecs
      uint8_t d1=tempsensor.recv_byte(1);
      uint8_t d2=tempsensor.recv_byte(1);
      uint8_t d3=tempsensor.recv_byte(0);
      tempsensor.stop();
      Serial.print("d1=");
      Serial.print(d1,HEX);
      Serial.print(" d2=");
      Serial.print(d2,HEX);
      Serial.print(" d3=");
      Serial.print(d3,HEX);
      unsigned short temp_c=(((unsigned short)d1 << 8) + (unsigned short)d2)-4010;
      unsigned short temp_f=(temp_c*9/5)+3200;
      Serial.print(" T=");
      Serial.print(temp_c/100,DEC);
      Serial.print(".");
      Serial.print(temp_c%100,DEC);
      Serial.print("*C ");
      Serial.print(temp_f/100,DEC);
      Serial.print(".");
      Serial.print(temp_f%100,DEC);
      Serial.println("*F");
   }
   digitalWrite(LED, LOW);
   delay(2000); // milliseconds
}

////////////////////////////////////////////////////////////////////////////////

