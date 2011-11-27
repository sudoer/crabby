
#include <LiquidCrystal.h>
#include <avr/pgmspace.h>
#include "sht1x.h"

#define LED   13

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
   Serial.print("loop: ");
   digitalWrite(LED, HIGH);
   tempsensor.transmission_start();
   uint8_t ack=tempsensor.send_byte(MEASURE_TEMP);
   // sensor chip will set ack=0
   if (tempsensor.wait_for_ready()) { // about 80 millisecs
      uint8_t d1=tempsensor.recv_byte(1);
      uint8_t d2=tempsensor.recv_byte(1);
      uint8_t d3=tempsensor.recv_byte(0);
      tempsensor.stop();
      // prepare
      char str[21];
      lcd.clear();
      // line 1
      sprintf(str,"d1=%02X d2=%02X d3=%02X",d1,d2,d3);
      Serial.print(str);
      Serial.print(" ");
      lcd.setCursor(0, 0);
      lcd.print(str);
      // line 2
      unsigned short temp_c=(((unsigned short)d1 << 8) + (unsigned short)d2)-4010;
      unsigned short temp_f=(temp_c*9/5)+3200;
      sprintf(str,"T=%d.%02dC %d.%02dF",temp_c/100,temp_c%100,temp_f/100,temp_f%100);
      Serial.print(str);
      lcd.setCursor(0, 1);
      lcd.print(str);
      // line 3
      // line 4
   }
   Serial.println("");
   digitalWrite(LED, LOW);
   delay(2000); // milliseconds
}

////////////////////////////////////////////////////////////////////////////////

