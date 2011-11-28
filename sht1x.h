
#ifndef SHT1X_H
#define SHT1X_H

#include "bbi2c.h"

                           //adr cmnd r/w
#define STATUS_REG_W 0x06  //000 0011 0
#define STATUS_REG_R 0x07  //000 0011 1
#define MEASURE_TEMP 0x03  //000 0001 1
#define MEASURE_HUMI 0x05  //000 0010 1
#define RESET        0x1e  //000 1111 0

class sht1x : public bbi2c {
   public:
      void transmission_start(void);
      int wait_for_ready(void);
      void calc(unsigned short t_in, unsigned short h_in, float & t_out ,float & h_out);
};

#endif // SHT1X_H
