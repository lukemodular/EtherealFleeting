// -------------------------------------------------------------------------------------------
// Basic Slave
// -------------------------------------------------------------------------------------------
//
// This creates a simple I2C Slave device which will print whatever text string is sent to it.
// It will retain the text string in memory and will send it back to a Master device if
// requested.  It is intended to pair with a Master device running the basic_master sketch.
//
// This example code is in the public domain.
//
// -------------------------------------------------------------------------------------------

#include <i2c_t3.h>
#include <IRremote.h>

// Function prototypes
void receiveEvent(size_t count);
void requestEvent(void);

// Memory
#define MEM_LEN 1
char databuf[MEM_LEN];
volatile uint8_t received;

int lastfloodState  = 0;     // previous state of the button
int floodState      = 0;     // remember current led state

IRsend irsend;

//
// Setup
//
void setup()
{
  pinMode(LED_BUILTIN, OUTPUT); // LED

  // Setup for Slave mode, address 0x66, pins 18/19, external pullups, 400kHz
  Wire.begin(I2C_SLAVE, 0x66, I2C_PINS_18_19, I2C_PULLUP_EXT, 400000);

  // Data init
  received = 0;
  memset(databuf, 0, sizeof(databuf));

  // register events
  Wire.onReceive(receiveEvent);
  Wire.onRequest(requestEvent);

  delay(100);
  irsend.sendNEC(0xF740BF, 32); //OFF
  delay(100);

  Serial.begin(115200);
}

void loop()
{
  // print received data - this is done in main loop to keep time spent in I2C ISR to minimum
  if (received)
  {
    digitalWrite(LED_BUILTIN, HIGH);
    floodState = int(databuf[0]);
    //Serial.print("Slave received: ");
    //Serial.println(floodState);

    if (floodState != lastfloodState) {
      Serial.print("floodstate received: ");
      Serial.println(floodState);
      if (floodState == 255) {
        irsend.sendNEC(0xF7C03F, 32);  //ON
        Serial.print("Floodstate ON");
        delay(50);
      } else {
        irsend.sendNEC(0xF740BF, 32); //OFF
        Serial.print("Floodstate OFF");
        delay(50);
      }
      lastfloodState = floodState;
    }
    received = 0;
    digitalWrite(LED_BUILTIN, LOW);
  }

}

//
// handle Rx Event (incoming I2C data)
//
void receiveEvent(size_t count)
{
  Wire.read(databuf, count);  // copy Rx data to databuf
  received = count;           // set received flag to count, this triggers print in main loop
}

//
// handle Tx Event (outgoing I2C data)
//
void requestEvent(void)
{
  Wire.write(databuf, MEM_LEN); // fill Tx buffer (send full mem)
}



/*
   ON:
   Decoded NEC: F7C03F (32 bits)
  Raw (68): 9100 -4550 600 -550 550 -600 550 -600 550 -600 550 -550 550 -600 550 -600 550 -600 550 -1700 600 -1650 600 -1650 600 -1700 550 -550 600 -1700 550 -1700 550 -1700 600 -1650 600 -1650 600 -550 550 -600 550 -600 550 -600 550 -600 550 -600 550 -550 550 -600 550 -1700 600 -1700 550 -1700 550 -1700 600 -1650 600 -1650 600

   OFF:
  Decoded NEC: F740BF (32 bits)
  Raw (68): 9100 -4550 600 -500 650 -500 650 -500 650 -500 600 -550 600 -550 600 -500 650 -500 650 -1600 650 -1650 600 -1650 600 -1650 600 -550 600 -1650 600 -1650 650 -1650 600 -500 650 -1650 600 -500 650 -500 650 -500 600 -550 600 -550 600 -550 600 -1650 600 -550 600 -1650 600 -1650 600 -1650 650 -1600 650 -1650 600 -1650 600

   Luminosity down:
  Decoded NEC: F7807F (32 bits)
  Raw (68): 9100 -4500 650 -500 650 -500 650 -500 600 -550 600 -550 600 -550 600 -500 650 -500 650 -1600 650 -1650 600 -1650 600 -1650 600 -550 600 -1650 600 -1650 650 -1600 650 -1650 600 -500 650 -500 650 -500 600 -550 600 -550 600 -550 600 -500 650 -500 650 -1600 650 -1650 600 -1650 600 -1650 600 -1650 650 -1600 650 -1650 600

   Luminosity up:
  Decoded NEC: F700FF (32 bits)
  Raw (68): 9100 -4500 650 -500 650 -500 600 -550 600 -550 600 -550 600 -500 650 -500 650 -500 600 -1650 650 -1600 650 -1650 600 -1650 600 -550 600 -1650 600 -1650 600 -1650 650 -500 600 -550 600 -550 600 -550 600 -500 650 -500 650 -500 650 -500 600 -1650 650 -1600 650 -1650 600 -1650 600 -1650 600 -1650 650 -1600 650 -1650 600

   White:
  Decoded NEC: F7E01F (32 bits)
  Raw (68): 9100 -4550 600 -550 550 -600 550 -550 600 -550 600 -550 600 -550 600 -550 550 -600 550 -1700 550 -1700 600 -1650 600 -1650 600 -550 600 -1650 600 -1700 550 -1700 550 -1700 600 -1650 600 -1650 600 -550 600 -550 600 -550 550 -600 550 -600 550 -550 600 -550 600 -550 600 -1650 600 -1650 600 -1700 550 -1700 550 -1700 600

   Fade:
   Decoded NEC: F7C837 (32 bits)
  Raw (68): 9100 -4550 550 -550 600 -550 600 -550 600 -550 550 -600 550 -600 550 -550 600 -550 600 -1650 600 -1700 550 -1700 550 -1700 600 -550 600 -1650 600 -1650 600 -1650 600 -1700 550 -1700 550 -600 550 -600 550 -1700 550 -600 550 -550 600 -550 600 -550 600 -550 550 -1700 600 -1650 600 -550 600 -1650 600 -1650 600 -1700 550

   Smooth:
   Decoded NEC: F7E817 (32 bits)
  Raw (68): 9100 -4550 600 -500 650 -500 650 -500 650 -500 600 -550 600 -550 600 -500 650 -500 650 -1600 650 -1650 600 -1650 600 -1650 650 -500 600 -1650 650 -1600 650 -1600 650 -1650 600 -1650 600 -1650 600 -550 600 -1650 600 -550 600 -550 600 -550 600 -500 650 -500 650 -500 600 -1650 650 -500 600 -1650 650 -1650 600 -1650 600
  F

*/
