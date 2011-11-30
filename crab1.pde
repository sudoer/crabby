
#include <LiquidCrystal.h>
#include <avr/pgmspace.h>
#include <SD.h>
#include "sht1x.h"

// hardware pins
#define LED        -1  // digital
#define LIGHTMETER  0  // analog
#define BACKLIGHT  -1  // PWM
#define SDCARD_CS  10  // digital

#define FILENAME  "crabby.txt"

// timing
#define LOOP_MS 10000
#define FADE_MS 10

// temperature/humidity ranges (x100)
#define TEMP_LO 7200
#define TEMP_HI 8000
#define HUMI_LO 7000
#define HUMI_HI 8000
typedef enum { LO, OK, HI } lohi_t;
char * describe[] = {"LOW","OK","HIGH"};

////////////////////////////////////////////////////////////////////////////////

static sht1x tempsensor;
static LiquidCrystal lcd(4,5,6,7,8,9);
static unsigned long loopnum=0;

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
   #if (LED >= 0)
      pinMode(LED,OUTPUT);
   #endif
   #if (BACKLIGHT >= 0)
      pinMode(BACKLIGHT,OUTPUT);
   #endif
   // SD card
   pinMode(SDCARD_CS, OUTPUT);
   if (!SD.begin(SDCARD_CS)) {
      Serial.println("Card failed, or not present");
   } else {
      Serial.println("card initialized.");
   }
}

////////////////////////////////////////////////////////////////////////////////

void loop() {
   char str[21];

   loopnum++;

   static int current_light_level=0;
   #if (BACKLIGHT >= 0)
      analogWrite(BACKLIGHT,current_light_level);
   #endif

   int target_light_level=map(analogRead(LIGHTMETER),1023,0,0,255);  // adjust to 0-255 range
   target_light_level=constrain(target_light_level,1,255);  // bound within 0-255

   // starting to read sensors
   #if (LED >= 0)
      digitalWrite(LED, HIGH);
   #endif

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
   #if (LED >= 0)
      digitalWrite(LED, LOW);
   #endif

   // compute relative humidity
   unsigned short t_in=d1*256 + d2;
   unsigned short h_in=d4*256 + d5;
   float adj_temp_c;
   float adj_rel_humid;
   tempsensor.calc(t_in,h_in,adj_temp_c,adj_rel_humid);

   // integer values for printing
   unsigned short int_tc=(unsigned short)(adj_temp_c * 100.0);
   unsigned short int_tf=(int_tc*9/5)+3200;
   unsigned short int_rh=(unsigned short)(adj_rel_humid * 100.0);

   // prepare displays
   Serial.println("loop: ");
   lcd.clear();

   // line 1
   ///sprintf(str,"%02X,%02X%02X%02X,%02X%02X%02X",target_light_level,d1,d2,d3,d4,d5,d6);
   sprintf(str,"%s %d",__TIME__,loopnum);
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

   // if the file is available, write to it:
   File dataFile = SD.open(FILENAME, FILE_WRITE);
   if (dataFile) {
      sprintf(str,"%ld,",loopnum);
      dataFile.print(str);
      sprintf(str,"%d.%02d,",int_tf/100,int_tf%100);
      dataFile.print(str);
      sprintf(str,"%d.%02d%",int_rh/100,int_rh%100);
      dataFile.println(str);
      dataFile.close();
   } else {
      Serial.println("error opening " FILENAME);
   }

   // fade backlight
   for (int i=0; i<LOOP_MS; i+=FADE_MS) {
      if (current_light_level<target_light_level) current_light_level++;
      if (current_light_level>target_light_level) current_light_level--;
      #if (BACKLIGHT >= 0)
         analogWrite(BACKLIGHT,current_light_level);
      #endif
      delay(FADE_MS); // ms
   }
}

////////////////////////////////////////////////////////////////////////////////

