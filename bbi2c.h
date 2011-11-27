
#ifndef BBI2C_H
#define BBI2C_H

#include <avr/pgmspace.h>

class bbi2c {
   public:
      bbi2c(void);
      void init(int clock_pin, int data_pin);
      void start(void);
      void reset(void);
      uint8_t send_byte(uint8_t b);
      uint8_t recv_byte(uint8_t ack);
      void stop(void);
   protected:
      volatile uint8_t * sck_ddr;
      volatile uint8_t * sck_pin;
      volatile uint8_t * sck_port;
      uint8_t sck_mask;
      volatile uint8_t * sda_ddr;
      volatile uint8_t * sda_pin;
      volatile uint8_t * sda_port;
      uint8_t sda_mask;
   protected:
      inline void sck_is_output(void);
      inline void sck_write(uint8_t hl);
      inline void sda_is_input(void);
      inline uint8_t sda_read(void);
      inline void sda_is_output(void);
      inline void sda_write(uint8_t hl);
      void spacer(void);
};

#endif
