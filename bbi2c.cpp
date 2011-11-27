
#include <wiring.h>
#include "bbi2c.h"

// BITWISE OPERATIONS
#define MASKSET(name,mask)  ((name)|=(mask))
#define MASKCLR(name,mask)  ((name)&=~(mask))
#define MASKTST(name,mask)  ((name) & (mask))
#define MASKNOT(name,mask)  ((name)^=(mask))
//#define BITSET(name,bitn)  ((name)|=(0x01<<(bitn)))
//#define BITCLR(name,bitn)  ((name)&=~(0x01<<(bitn)))
//#define BITTST(name,bitn)  ((name) & (0x01<<(bitn)))
//#define BITNOT(name,bitn)  ((name)^=(0x01<<(bitn)))

////////////////////////////////////////////////////////////////////////////////

typedef struct {
   int digital_output;
   uint8_t ddr;
   uint8_t pin;
   uint8_t port;
   uint8_t mask;
} pin_map_t;

static pin_map_t pin_map[] {
   {  0,  DDRD,  PIND,  PORTD,  0x01 },
   {  1,  DDRD,  PIND,  PORTD,  0x02 },
   {  2,  DDRD,  PIND,  PORTD,  0x04 },
   {  3,  DDRD,  PIND,  PORTD,  0x08 },
   {  4,  DDRD,  PIND,  PORTD,  0x10 },
   {  5,  DDRD,  PIND,  PORTD,  0x20 },
   {  6,  DDRD,  PIND,  PORTD,  0x40 },
   {  7,  DDRD,  PIND,  PORTD,  0x80 },
   {  8,  DDRB,  PINB,  PORTB,  0x01 },
   {  9,  DDRB,  PINB,  PORTB,  0x02 },
   { 10,  DDRB,  PINB,  PORTB,  0x04 },
   { 11,  DDRB,  PINB,  PORTB,  0x08 },
   { 12,  DDRB,  PINB,  PORTB,  0x10 },
   { 13,  DDRB,  PINB,  PORTB,  0x20 },
};

////////////////////////////////////////////////////////////////////////////////

bbi2c::bbi2c(void) {
}

////////////////////////////////////////////////////////////////////////////////

void bbi2c::init(int clock_pin, int data_pin) {
   sck_ddr = (volatile uint8_t *) pin_map[clock_pin].ddr;
   sck_pin = (volatile uint8_t *) pin_map[clock_pin].pin;
   sck_port = (volatile uint8_t *) pin_map[clock_pin].port;
   sck_mask = pin_map[clock_pin].mask;
   sda_ddr = (volatile uint8_t *) pin_map[data_pin].ddr;
   sda_pin = (volatile uint8_t *) pin_map[data_pin].pin;
   sda_port = (volatile uint8_t *) pin_map[data_pin].port;
   sda_mask = pin_map[data_pin].mask;
   // SCK is always an output
   sck_is_output();
   sda_write(1);
   // SDA is an output for now
   sda_is_output();
   sda_write(1);
}

////////////////////////////////////////////////////////////////////////////////

void bbi2c::start(void) {
   sda_is_output();
   sda_write(0);
   spacer();
   sck_write(0);
   spacer();
}

////////////////////////////////////////////////////////////////////////////////

void bbi2c::reset(void) {
   sda_is_output();
   sda_write(1);
   sck_write(0);
   int i;
   for(i=0;i<9;i++) {
      sck_write(1);
      spacer();
      sck_write(0);
      spacer();
   }
}

////////////////////////////////////////////////////////////////////////////////

uint8_t bbi2c::send_byte(uint8_t b) {
   uint8_t errors=0;
   uint8_t mask;
   sda_is_output();
   for(mask=0x80;mask;mask>>=1) {
      // present the data bit while the clock is low
      sda_write((b&mask)?1:0);
      spacer();
      // pulse clock line
      sck_write(1);
      spacer();
      sck_write(0);
      spacer();
   }
   // send ACK pulse, read his ACK
   sda_is_input();
   sck_write(1);
   // receiver should pull SDA low here
   spacer();
   errors=sda_read();
   sck_write(0);
   sda_is_output();
   spacer();
   return errors;
}

////////////////////////////////////////////////////////////////////////////////

uint8_t bbi2c::recv_byte(uint8_t ack) {
   uint8_t b=0;
   // release SDA line
   sda_is_input();
   // cycle clock and read bits in
   uint8_t mask;
   for(mask=0x80;mask;mask>>=1) {
      sck_write(1);
      spacer();
      uint8_t inbit = sda_read();
      if (inbit) b=b|mask;
      sck_write(0);
      spacer();
   }
   // send ACK pulse
   sda_is_output();
   sda_write(ack?0:1);
   sck_write(1);
   spacer();
   sck_write(0);
   spacer();
   // release data line
   sda_is_input();
   return b;
}

////////////////////////////////////////////////////////////////////////////////

void bbi2c::stop(void) {
   sda_is_output();
   sda_write(0);
   spacer();
   sck_write(1);
   spacer();
   sda_write(1);
   spacer();
}

////////////////////////////////////////////////////////////////////////////////
//   PRIMITIVE PIN OPERATIONS
////////////////////////////////////////////////////////////////////////////////

inline void bbi2c::sck_is_output(void)    { MASKSET(*sck_ddr,sck_mask); }
inline void bbi2c::sck_write(uint8_t hl)  { if (hl) MASKSET(*sck_port,sck_mask); else MASKCLR(*sck_port,sck_mask); }
inline void bbi2c::sda_is_input(void)     { MASKCLR(*sda_ddr,sda_mask); MASKSET(*sda_port,sda_mask); }
inline uint8_t bbi2c::sda_read(void)      { return MASKTST(*sda_pin,sda_mask)?1:0; }
inline void bbi2c::sda_is_output(void)    { MASKSET(*sda_ddr,sda_mask); }
inline void bbi2c::sda_write(uint8_t hl)  { if (hl) MASKSET(*sda_port,sda_mask); else MASKCLR(*sda_port,sda_mask); }
void bbi2c::spacer(void)                  { delayMicroseconds(100); }

////////////////////////////////////////////////////////////////////////////////

