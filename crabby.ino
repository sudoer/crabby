
#include <LiquidCrystal.h>
#include <avr/pgmspace.h>
#include <SD.h>
#include "sht1x.h"
#include <Wire.h>
#include "RTClib.h"

// hardware pins
//#define LED        13  // digital
//#define BACKLIGHT   4  // PWM
//#define LIGHTMETER  0  // analog
#define TEMP_SDA     9
#define TEMP_SCL     8
#define SDCARD_CS   10
#define LCD_I2CADDR  0
//#define LCD_RS       A2
//#define LCD_EN       A3
//#define LCD_DB4      4
//#define LCD_DB5      5
//#define LCD_DB6      6
//#define LCD_DB7      7
#define FILENAME_DEFAULT "crabby.txt"
#define FILENAME_LEN  13 // 8.3\0

// timing
#define LOOP_MS 30000
#define FADE_MS 10

// temperature/humidity ranges (x100)
#define TEMP_LO 7000
#define TEMP_HI 8000
#define HUMI_LO 6500
#define HUMI_HI 8000
typedef enum { LO, OK, HI } lohi_t;
char * describe[] = {"LOW","OK","HIGH"};

////////////////////////////////////////////////////////////////////////////////

static sht1x tempsensor;
#ifdef LCD_I2CADDR
   static LiquidCrystal lcd(LCD_I2CADDR);
#else
   static LiquidCrystal lcd(LCD_RS,LCD_EN,LCD_DB4,LCD_DB5,LCD_DB6,LCD_DB7);
#endif
static long loopnum=0;
static RTC_DS1307 RTC;
static char filename[FILENAME_LEN];

////////////////////////////////////////////////////////////////////////////////

void setup() {

   // set up serial port
   Serial.begin(57600);
   Serial.println(__DATE__);
   Serial.println(__TIME__);

   // set up temperature/humidity sensor
   tempsensor.init(TEMP_SCL,TEMP_SDA);

   // LCD
   #ifdef LCD_I2CADDR
      // no special setup
   #else
      pinMode(LCD_RS,OUTPUT);
      pinMode(LCD_EN,OUTPUT);
      pinMode(LCD_DB4,OUTPUT);
      pinMode(LCD_DB5,OUTPUT);
      pinMode(LCD_DB6,OUTPUT);
      pinMode(LCD_DB7,OUTPUT);
   #endif
   lcd.begin(20,4);
   lcd.noCursor();
   lcd.clear();
   lcd.setCursor(0, 0);
   lcd.print(__DATE__);
   lcd.setCursor(0, 1);
   lcd.print(__TIME__);
   lcd.setBacklight(1);

   // set up GPIOs
   #ifdef LED
      pinMode(LED,OUTPUT);
   #endif
   #ifdef BACKLIGHT
      pinMode(BACKLIGHT,OUTPUT);
   #endif

   // SD card
   pinMode(SDCARD_CS, OUTPUT);
   if (!SD.begin(SDCARD_CS)) {
      Serial.println("Card failed, or not present");
   } else {
      Serial.println("card initialized.");
   }

   // RT clock
   Wire.begin();
   RTC.begin();
   if (RTC.isrunning()) {
      Serial.println("RTC is running!");
   } else {
      Serial.println("RTC is NOT running!");
      strcpy(filename,FILENAME_DEFAULT);
      // following line sets the RTC to the date & time this sketch was compiled
      // RTC.adjust(DateTime(__DATE__, __TIME__));
      RTC.adjust(DateTime(__DATE__,__TIME__));
   }
   DateTime now = RTC.now();
   sprintf(filename,"%02d%02d%02d%02d.dat",
      now.month(),now.day(),now.hour(),now.minute());

   // take a deep breath
   delay(1000);
}

////////////////////////////////////////////////////////////////////////////////

void loop() {
   char str[21];
   int target_light_level=128; // default

   DateTime now = RTC.now();
   loopnum++;

   static int current_light_level=0;
   #ifdef BACKLIGHT
      analogWrite(BACKLIGHT,current_light_level);
   #endif

   #ifdef LIGHTMETER
      target_light_level=map(analogRead(LIGHTMETER),1023,0,0,255);  // adjust to 0-255 range
      target_light_level=constrain(target_light_level,1,255);  // bound within 0-255
   #endif

   // starting to read sensors
   #ifdef LED
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
   #ifdef LED
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

   // find ranges: LO-OK-HI
   lohi_t temp_ok=LO;
   if (int_tf >= TEMP_LO) temp_ok=OK;
   if (int_tf > TEMP_HI) temp_ok=HI;
   lohi_t humi_ok=LO;
   if (int_rh >= HUMI_LO) humi_ok=OK;
   if (int_rh > HUMI_HI) humi_ok=HI;

   // prepare displays
   Serial.println();
   lcd.clear();

   // line 1
   ///sprintf(str,"%02X,%02X%02X%02X,%02X%02X%02X",target_light_level,d1,d2,d3,d4,d5,d6);
   ///sprintf(str,"%s %d",__TIME__,loopnum);
   char weekdays[]="SMTWHFS";
   sprintf(str,"%c%02d %d:%02d:%02d #%ld",
      weekdays[now.dayOfWeek()],now.day(),
      now.hour(),now.minute(),now.second(),
      loopnum);
   Serial.print("1>>");
   Serial.println(str);
   lcd.setCursor(0, 0);
   lcd.print(str);

   // line 2
   sprintf(str,"T= %d.%01dC %d.%01dF %s",int_tc/100,int_tc%100/10,int_tf/100,int_tf%100/10,describe[temp_ok]);
   Serial.print("2>>");
   Serial.println(str);
   lcd.setCursor(0, 1);
   lcd.print(str);

   // line 3
   sprintf(str,"humidity=%d.%01d%% %s",int_rh/100,int_rh%100/10,describe[humi_ok]);
   Serial.print("3>>");
   Serial.println(str);
   lcd.setCursor(0, 2);
   lcd.print(str);

   // line 4
   if ((temp_ok==OK)&&(humi_ok==OK)) {
      sprintf(str,"happy crabby!");
   } else {
      sprintf(str,"");
   }
   Serial.print("4>>");
   Serial.println(str);
   lcd.setCursor(0, 3);
   lcd.print(str);

   // if the file is available, write to it:
   File dataFile = SD.open(filename, FILE_WRITE);
   if (dataFile) {
      sprintf(str,"%ld,",loopnum);
      dataFile.print(str);
      sprintf(str,"%ld,",now.unixtime());
      dataFile.print(str);
      sprintf(str,"%02d,%d:%02d:%02d,",now.day(),now.hour(),now.minute(),now.second());
      dataFile.print(str);
      sprintf(str,"%d.%02d,",int_tf/100,int_tf%100);
      dataFile.print(str);
      sprintf(str,"%d.%02d%",int_rh/100,int_rh%100);
      dataFile.println(str);
      dataFile.close();
   } else {
      Serial.print("error opening ");
      Serial.println(filename);
   }

   // end loop
   Serial.println();

   // fade backlight
   for (int i=0; i<LOOP_MS; i+=FADE_MS) {
      if (current_light_level<target_light_level) current_light_level++;
      if (current_light_level>target_light_level) current_light_level--;
      #ifdef BACKLIGHT
         analogWrite(BACKLIGHT,current_light_level);
      #endif
      delay(FADE_MS); // ms
   }
}

////////////////////////////////////////////////////////////////////////////////

