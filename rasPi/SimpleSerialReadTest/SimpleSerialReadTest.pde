  

// Example by Tom Igoe 
 
import processing.serial.*; 
 
Serial myPort;    // The serial port
PFont myFont;     // The display font
byte[] inBuffer = new byte[5];
int lf = 42;      // ASCII linefeed 
 
void setup() { 
  size(400,200); 
  // You'll need to make this font with the Create Font Tool 
  // List all the available serial ports: 
  printArray(Serial.list()); 
  // I know that the first port in the serial list on my mac 
  // is always my  Keyspan adaptor, so I open Serial.list()[0]. 
  // Open whatever port is the one you're using. 
  myPort = new Serial(this, Serial.list()[0], 115200); 
  myPort.bufferUntil(lf); 
} 
 
void draw() { 
  background(0); 
  //text("received: " + inBuffer, 10,50); 
  println(inBuffer);
} 
 
void serialEvent(Serial p) { 
  inBuffer = p.readBytes(); 
} 
