// Mega Pixel Artnet Controller for Ethereal Fleeting

// Baseed on:
// E1.31 Receiver and pixel controller by Chris Rees (crees@bearrivernet.net) for the Teensy 3.2 This code was modified from
// Andrew Huxtable base code. (andrew@hux.net.au)
// This code may be freely distributed and used as you see fit for non-profit
// purposes and as long as the original author is credited and it remains open
// source
//
// Please configure your Lighting product to use Unicast to the IP the device is given from your DHCP server
// Multicast is not currently supported at the moment


// You will need the, Teensy utility installed with the added Ethernet One Socket and FastLed Libraries from:
// [url]https://www.pjrc.com/teensy/teensyduino.html[/url]
// [url]https://github.com/mrrees/MegaPixel-One-Socket-Ethernet[/url]
// [url]https://github.com/FastLED/FastLED/releases[/url]
//
// Please note the one socket library may throw errors in compiling. The error was in realation to the chip speed detection and using the
// correct SPI speed.
//
// The Teensy with the Octows2811 and FastLED will allow up to 5440 Pixels (32 Universes) to run.  One thing to note is if you desire
// high frame rates your pixel count must not exceed over 680 Pixels per Octo Pin.  The reason why is the ammount of time to write out to
// these LED's takes time to shift from one LED to the next.  The more LED's per SPI or Octo Pin the more time it takes and the less frame
// rate you will acheive.  In the Pixel Controller Wolrd 680 per SPI port is the desired balance.   For the Teensy this is a perfect balance
// any more pixels and memory starts to become an issue.  Those who whish to push more pixels per port can do so but must sacrifice the
// fastLED and or Octows2811 libraries to free up buffer space..  but your on your own and we welcome you to share your improved methods
// with the community!


// in the code structure there is some serial feedback.  Please note enableing serial feedback will interrupt with the pixel performance
// and will slow it down.  use only for debugging and omit during production run.

//Compiling the software
//
//It is very important you DO NOT cache the compiled core. You WILL experience problems if you do this.
//  Go to file->preferences and ensure ‘Aggressively cache compiled core’ is NOT checked.
//  You must also compile with the following settings
//
//  - Tools->CPU Speed -> 120Mhz (overclock)
//  - Tools->Optimize->Fastest
//
//    If you receive the error, ‘SPIFIFO.begin(ss_pin, SPI_CLOCK_30MHz); // W5100 is 14 MHz max’, you have the incorrect Ethernet library installed.


#include <SPI.h>
#include <Ethernet.h>
#include <EthernetUdp.h>
#include <OctoWS2811.h>
#define USE_OCTOWS2811
#include <FastLED.h>
#include <DmxSimple.h>
//#include <i2c_t3.h>

//ARTNET STUFF
#define short_get_high_byte(x) ((HIGH_BYTE & x) >> 8)
#define short_get_low_byte(x)  (LOW_BYTE & x)
#define bytes_to_short(h,l) ( ((h << 8) & 0xff00) | (l & 0x00FF) );

//*********************************************************************************

//ARTNET
//customisation: Artnet SubnetID + UniverseID
//edit this with SubnetID + UniverseID you want to receive
byte SubnetID = {0};
byte UniverseID = {0};
short select_universe = ((SubnetID * 16) + UniverseID);

// Set a different MAC address for each controller IMPORTANT!!!! you can change the last value but make sure its HEX!...
byte mac[] = { 0x74, 0x69, 0x69, 0x2D, 0x30, 0x14 };
//byte mac[] = { 0x74, 0x69, 0x69, 0x2D, 0x30, 0x15 };
//byte mac[] = { 0x74, 0x69, 0x69, 0x2D, 0x30, 0x16 };
//byte mac[] = { 0x74, 0x69, 0x69, 0x2D, 0x30, 0x17 };


// Uncomment if you want to use static IP
//*******************************************************
// ethernet interface ip address
IPAddress ip(10, 10, 10, 11);  //IP address of ethernet shield
//IPAddress ip(10, 10, 10, 12);  //IP address of ethernet shield
//IPAddress ip(10, 10, 10, 13);  //IP address of ethernet shield
//IPAddress ip(10, 10, 10, 14);  //IP address of ethernet shield
//*******************************************************

// E1.31 and artenet is UDP.  One socket library will only allow one protocol to be defined.
EthernetUDP Udp;


//Leave this alone.  At current a full e1.31 frame is 636 bytes..
//#define ETHERNET_BUFFER 636 //540 is artnet leave at 636 for e1.31
#define ETHERNET_BUFFER 576 //540 is artnet leave at 636 for e1.31
/// Change Values and needed.

#define NUM_STRIPS 7
#define NUM_LEDS_PER_STRIP 360
#define NUM_LEDS 2520 // with current fastLED and OctoWs2811 libraries buffers... do not go higher than this - Runs out of SRAM
#define CHANNEL_COUNT 7560 //because it divides by 3 nicely
#define UNIVERSE_COUNT 20
#define LEDS_PER_UNIVERSE 120

//ARTNET PACKET
const int art_net_header_size = 17;
const int max_packet_size = 576;
char ArtNetHead[8] = "Art-Net";
char OpHbyteReceive = 0;
char OpLbyteReceive = 0;
//short is_artnet_version_1=0;
//short is_artnet_version_2=0;
//short seq_artnet=0;
//short artnet_physical=0;
short incoming_universe = 0;
boolean is_opcode_is_dmx = 0;
boolean is_opcode_is_artpoll = 0;
boolean match_artnet = 1;
short Opcode = 0;


//***********************************************************
// BEGIN  Dont Modify unless you know what your doing below
//***********************************************************

// Define the array of leds
CRGB leds[NUM_STRIPS * NUM_LEDS_PER_STRIP];

// Pin layouts on the teensy 3:
// OctoWS2811: 2,14,7,8,6,20,21,5


unsigned char packetBuffer[ETHERNET_BUFFER];
int c = 0;
float fps = 0;
unsigned long currentMillis = 0;
unsigned long previousMillis = 0;

int dmxWriteCount = 0;

// Setup i2c
#define MEM_LEN 1
char databuf[MEM_LEN];
//slave adress
uint8_t target = 0x66;


//Setup GPIO
int smokePin = 18;
int fanPin = 19;


void setup() {


  // Setup DMX
  //DmxSimple.usePin(1);
  //DmxSimple.maxChannel(1);
  //delay(10);

  //  Wire.begin(I2C_MASTER, 0x00, I2C_PINS_18_19, I2C_PULLUP_EXT, 400000);
  //  Wire.setDefaultTimeout(1000); // 1ms


  //Setup GPIO
  pinMode(smokePin, OUTPUT);
  pinMode(fanPin, OUTPUT);


  // Data init
  memset(databuf, 0, sizeof(databuf));

  delay(10);

  //WIZNET RESET AND INITIALIZE
  pinMode(9, OUTPUT);
  digitalWrite(9, LOW);   // reset the WIZ820io
  delay(10);
  digitalWrite(9, HIGH);   // reset the WIZ820io

  //SD CARD INITIALIZE
  //pinMode(10, OUTPUT); // For SD Card Stuff
  //digitalWrite(10, HIGH);  // de-select WIZ820io
  //pinMode(4, OUTPUT); //SD Card Stuff
  //digitalWrite(4, HIGH);   // de-select the SD Card

  //Serial Port Stuff
  Serial.begin(115200);
  delay(10);


  // Using different LEDs or colour order? Change here...
  // ********************************************************
  LEDS.addLeds<OCTOWS2811>(leds, NUM_LEDS_PER_STRIP);
  LEDS.setBrightness(100);
  // ********************************************************

  //pins 3,4,22 are to the RGB Status LED

  // ********************************************************
  Ethernet.begin(mac, ip);

  //SANC
  //Udp.begin(5568);
  //ARTNET
  Udp.begin(6454);

  //DEFINE AND Turn Framing LED OFF
  pinMode(4, OUTPUT);
  digitalWrite(4, HIGH);
  //DEFINE AND TURN STATUS LED ON
  pinMode(3, OUTPUT);

  digitalWrite(3, LOW);
  delay(9000);
  //Turn Status LED OFF
  digitalWrite(3, HIGH);
  // ********************************************************
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());

  //Once the Ethernet is initialised, run a test on the LEDs
  initTest();
}



static inline void fps2(const int seconds) {
  // Create static variables so that the code and variables can
  // all be declared inside a function
  static unsigned long lastMillis;
  static unsigned long frameCount;
  static unsigned int framesPerSecond;

  // It is best if we declare millis() only once
  unsigned long now = millis();
  frameCount ++;
  if (now - lastMillis >= seconds * 1000) {
    framesPerSecond = frameCount / seconds;
    Serial.print("FPS @ ");
    Serial.println(framesPerSecond);
    frameCount = 0;
    lastMillis = now;
  }
}



void artnetDMXReceived(unsigned char* pbuff, int count, int unicount) {
  if (count > CHANNEL_COUNT) count = CHANNEL_COUNT;
  //read incoming universe
  byte b = bytes_to_short(pbuff[15], pbuff[14]);
  byte s = pbuff[12]; //sequence
  //Serial.println(b);
  //turn framing LED OFF
  digitalWrite(4, HIGH);

  //Serial.println(s);

  if ( b >= UniverseID && b <= UniverseID + UNIVERSE_COUNT ) {


    int ledNumber = (b - UniverseID) * LEDS_PER_UNIVERSE;
    // artnet packets come in seperate RGB but we have to set each led's RGB value together
    // this 'reads ahead' for all 3 colours before moving to the next led.
    // Serial.println(b);
    for (int i = 18; i < 18 + count; i = i + 3) {
      byte charValueR = pbuff[i];
      byte charValueG = pbuff[i + 1];
      byte charValueB = pbuff[i + 2];
      leds[ledNumber] = CRGB(charValueR, charValueG, charValueB);
      //Serial.println(ledNumber);
      ledNumber++;
    }


    //Serial.println(unicount);
    if (unicount == UNIVERSE_COUNT) {
      //Turn Framing LED ON
      digitalWrite(4, LOW);
      LEDS.show();

      //Frames Per Second Function fps(every_seconds)
      fps2(10);

    }


  }

}


//Check ARTNET header for Art-Net. Only look for three Char "A" "-" "t" in hex
int checkARTHeaders(unsigned char* messagein, int messagelength) {
  if ( messagein[0] == 65 && messagein[3] == 45 && messagein[6] == 116) {
    //check if its not artpoll
    //Serial.println(messagein[0]);

    //operator code enables to know wich type of message Art-Net it is
    Opcode = bytes_to_short(packetBuffer[9], packetBuffer[8]);
    //Serial.println(Opcode);
    //if opcode is DMX type - artpoll opcode is 0x2000
    if (Opcode == 20480) {
      int addresscount = (messagein[16] << 8) + (messagein[17]); // number of values plus start code
      //Serial.println(addresscount);
      return addresscount - 1; //Return how many values are in the packet.

    } else {
      return 0;
    }
  }

  return 0;

}


void initTest() //runs at board boot to make sure pixels are working
{
  LEDS.showColor(CRGB(255, 0, 0)); //turn all pixels on red
  delay(1000);
  LEDS.showColor(CRGB(0, 255, 0)); //turn all pixels on green
  delay(1000);
  LEDS.showColor(CRGB(0, 0, 255)); //turn all pixels on blue
  delay(1000);
  LEDS.showColor(CRGB(255, 255, 255)); //turn all pixels on blue
  delay(1000);
  LEDS.showColor(CRGB(0, 0, 0)); //turn all pixels off
}


void loop() {

  //Process packets
  int packetSize = Udp.parsePacket(); //Read UDP packet count
  if (c > UNIVERSE_COUNT) {
    c = 0;
  }

  if (packetSize) {

    Udp.read(packetBuffer, ETHERNET_BUFFER); //read UDP packet
    //Serial.println(packetSize);

    //SACN
    //int count = checkACNHeaders(packetBuffer, packetSize);

    //ARTNET
    int count = checkARTHeaders(packetBuffer, packetSize);
    if (count) {
      //Serial.println(count);
      //Serial.println(packetSize);

      if (packetBuffer[14] == 18) {
        byte fog = packetBuffer[18];
        //DmxSimple.write(1, fog);
        if (fog == 255) {
          digitalWrite(smokePin, HIGH);
          Serial.print("fog high");
          Serial.println(fog);
        }
        else {
          digitalWrite(smokePin, LOW);
        }
      }

      if (packetBuffer[14] == 19) {
        byte vent = packetBuffer[19];
        //DmxSimple.write(2, vent);
        if (vent == 255) {
          digitalWrite(fanPin, HIGH);
          Serial.print("vent high");
          Serial.println(vent);
        }
        else {
          digitalWrite(fanPin, LOW);
        }
      }

      //        if (packetBuffer[14] == 19) {
      //          byte flood = packetBuffer[19];
      //          databuf[0] = flood;
      //          Wire.beginTransmission(target);   // Slave address
      //          Wire.write(databuf, strlen(databuf) + 1); // Write string to I2C Tx buffer (incl. string null at end)
      //          Wire.endTransmission();           // Transmit to Slave          // Transmit to Slave
      //          Serial.print("flood ");
      //          Serial.println(flood);
      //        }


      artnetDMXReceived(packetBuffer, count, packetBuffer[14]); //process data function
      //Serial.print("LED Universe");
      //Serial.println(packetBuffer[14]);
      //Serial.println(c);
      //c = c + 1;
    }

  }

}


//______________
//sACN leftovers


//SACN
// enter desired universe and subnet  (sACN first universe is 1)
//#define DMX_SUBNET 0
//#define DMX_UNIVERSE 1 //**Start** universe

//void sacnDMXReceived(unsigned char* pbuff, int count, int unicount) {
//  if (count > CHANNEL_COUNT) count = CHANNEL_COUNT;
//  byte b = pbuff[113]; //DMX Subnet
//  if ( b == DMX_SUBNET) {
//    b = pbuff[114];  //DMX Universe
//    byte s = pbuff[111]; //sequence
//   //turn framing LED OFF
//   digitalWrite(4, HIGH);
//
//    //Serial.println(s );
//    if ( b >= DMX_UNIVERSE && b <= DMX_UNIVERSE + UNIVERSE_COUNT ) {
//
//      if ( pbuff[125] == 0 ) {  //start code must be 0
//      int ledNumber = (b - DMX_UNIVERSE) * LEDS_PER_UNIVERSE;
//       // sACN packets come in seperate RGB but we have to set each led's RGB value together
//       // this 'reads ahead' for all 3 colours before moving to the next led.
//       //Serial.println("*");
//       for (int i = 126;i < 126+count;i = i + 3){
//          byte charValueR = pbuff[i];
//          byte charValueG = pbuff[i+1];
//          byte charValueB = pbuff[i+2];
//          leds[ledNumber] = CRGB(charValueR,charValueG,charValueB);
//          //Serial.println(ledNumber);
//          ledNumber++;
//        }
//
//
//
//
//
//        //Serial.println(unicount);
//        if (unicount == UNIVERSE_COUNT){
//        //Turn Framing LED ON
//        digitalWrite(4, LOW);
//        LEDS.show();
//
//         //Frames Per Second Function fps(every_seconds)
//        fps2(10);
//
//        }
//
//
//      }
//
//
//
//    }
//  }
//
//}

////Check SACN header
//int checkACNHeaders(unsigned char* messagein, int messagelength) {
//  //Do some VERY basic checks to see if it's an E1.31 packet.
//  //Bytes 4 to 12 of an E1.31 Packet contain "ACN-E1.17"
//  //Only checking for the A and the 7 in the right places as well as 0x10 as the header.
//  //Technically this is outside of spec and could cause problems but its enough checks for us
//  //to determine if the packet should be tossed or used.
//  //This improves the speed of packet processing as well as reducing the memory overhead.
//  //On an Isolated network this should never be a problem....
//  if ( messagein[1] == 0x10 && messagein[4] == 0x41 && messagein[12] == 0x37) {
//      int addresscount = (byte) messagein[123] * 256 + (byte) messagein[124]; // number of values plus start code
//      return addresscount -1; //Return how many values are in the packet.
//    }
//  return 0;
//}

