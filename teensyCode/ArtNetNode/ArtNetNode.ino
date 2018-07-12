// Receive multiple universes via Artnet and control a strip of ws2811 leds via OctoWS2811
//
// This example may be copied under the terms of the MIT license, see the LICENSE file for details
//  https://github.com/natcl/Artnet
//
// http://forum.pjrc.com/threads/24688-Artnet-to-OctoWS2811?p=55589&viewfull=1#post55589
// Ideas for improving performance with WIZ820io / WIZ850io Ethernet:
// https://forum.pjrc.com/threads/45760-E1-31-sACN-Ethernet-DMX-Performance-help-6-Universe-Limit-improvements


// DmxSimple is available from: http://code.google.com/p/tinkerit/
// Help and support: http://groups.google.com/group/dmxsimple

// Fog machinge DMX Channel Assignments and Values
// 1-CH
// Channel     Function        Value      Percent/Setting
// 1          Fog Output       000>005    No function
//                             006>255    0–100%
// Note: Fog output is variable, depending on the status of the heater and environment


#include <Artnet.h>
#include <Ethernet.h>
#include <EthernetUdp.h>
#include <SPI.h>
#include <OctoWS2811.h>

#include <DmxSimple.h>

#include <IRremote.h>

//_____________________________
// OctoWS2811 settings
const int ledsPerStrip = 240; // change for your setup
const byte numStrips = 8; // change for your setup
DMAMEM int displayMemory[ledsPerStrip * 6];
int drawingMemory[ledsPerStrip * 6];
const int config = WS2811_GRB | WS2811_800kHz;
OctoWS2811 leds(ledsPerStrip, displayMemory, drawingMemory, config);

//_____________________________
// Artnet settings
Artnet artnet;
const int startUniverse = 0; // CHANGE FOR YOUR SETUP most software this is 1, some software send out artnet first universe as zero.
const int numberOfChannels = ledsPerStrip * numStrips * 3; // Total number of channels you want to receive (1 led = 3 channels)
byte channelBuffer[numberOfChannels]; // Combined universes into a single array

// Check if we got all universes
const int maxUniverses = numberOfChannels / 512 + ((numberOfChannels % 512) ? 1 : 0);
bool universesReceived[maxUniverses];
bool sendFrame = 1;

// Change ip and mac address for your setup
byte ip[] = {192, 168, 2, 2};
byte mac[] = {0x04, 0xE9, 0xE5, 0x00, 0x69, 0xEC};

//_____________________________
//IR wire settings
IRsend irsend;
#define NEC_BITS          32
#define NEC_HDR_MARK    9000
#define NEC_HDR_SPACE   4500
#define NEC_BIT_MARK     560
#define NEC_ONE_SPACE   1690
#define NEC_ZERO_SPACE   560
#define NEC_RPT_SPACE   2250

//_____________________________
//GPIO
#define RELAY_PIN 19
#define SERVO_PIN 23

//_____________________________
//Variables
#define FOG_RX 0


void setup()
{
  Serial.begin(115200);

  //_____________________________
  // Artnet Setup
  artnet.begin(mac, ip);

  //_____________________________
  // OctoWS2811 setup
  leds.begin();
  initTest();
  // this will be called for each packet received
  artnet.setArtDmxCallback(onDmxFrame);

  //_____________________________
  // DMX setup
  DmxSimple.usePin(1);
  DmxSimple.maxChannel(1);

  //_____________________________
  //IR wire setup

  //_____________________________
  //GPIO setup
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(SERVO_PIN, OUTPUT);

}

void loop()
{
  // we call the read function inside the loop
  artnet.read();

  sendDMX(FOG_RX);

}

void onDmxFrame(uint16_t universe, uint16_t length, uint8_t sequence, uint8_t* data)
{
  sendFrame = 1;

  // Store which universe has got in
  if (universe < maxUniverses)
    universesReceived[universe] = 1;

  for (int i = 0 ; i < maxUniverses ; i++)
  {
    if (universesReceived[i] == 0)
    {
      //Serial.println("Broke");
      sendFrame = 0;
      break;
    }
  }

  // read universe and put into the right part of the display buffer
  for (int i = 0 ; i < length ; i++)
  {
    int bufferIndex = i + ((universe - startUniverse) * length);
    if (bufferIndex < numberOfChannels) // to verify
      channelBuffer[bufferIndex] = byte(data[i]);
  }

  // send to leds
  for (int i = 0; i < ledsPerStrip * numStrips; i++)
  {
    leds.setPixel(i, channelBuffer[(i) * 3], channelBuffer[(i * 3) + 1], channelBuffer[(i * 3) + 2]);
  }

  if (sendFrame)
  {
    leds.show();
    // Reset universeReceived to 0
    memset(universesReceived, 0, maxUniverses);
  }
}

void initTest()
{
  for (int i = 0 ; i < ledsPerStrip * numStrips ; i++)
    leds.setPixel(i, 127, 0, 0);
  leds.show();
  delay(500);
  for (int i = 0 ; i < ledsPerStrip * numStrips  ; i++)
    leds.setPixel(i, 0, 127, 0);
  leds.show();
  delay(500);
  for (int i = 0 ; i < ledsPerStrip * numStrips  ; i++)
    leds.setPixel(i, 0, 0, 127);
  leds.show();
  delay(500);
  for (int i = 0 ; i < ledsPerStrip * numStrips  ; i++)
    leds.setPixel(i, 0, 0, 0);
  leds.show();
}

void sendDMX(uint16_t fogOut)
{
  //wrote on DMX channel, fogOut
  DmxSimple.write(1, fogOut);
}


/*
You just add the code to handle a pin (supplied by a changed constructor) and have modulated and unmodulated output in parallel.

 void  IRsend::sendNEC (unsigned long data,  int nbits)
{
    // Set IR carrier frequency
    enableIROut(38);

    // Header
    mark(NEC_HDR_MARK);
    space(NEC_HDR_SPACE);

    // Data
    for (unsigned long  mask = 1UL << (nbits - 1);  mask;  mask >>= 1) {
        if (data & mask) {
            mark(NEC_BIT_MARK);
            space(NEC_ONE_SPACE);
        } else {
            mark(NEC_BIT_MARK);
            space(NEC_ZERO_SPACE);
        }
    }

    // Footer
    mark(NEC_BIT_MARK);
    space(0);  // Always end with the LED off
}

//You just add the code to handle a pin (supplied by a changed constructor) and have modulated and unmodulated output in parallel.
 */
