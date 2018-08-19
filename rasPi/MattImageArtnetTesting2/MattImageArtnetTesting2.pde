// Building the brain for the cloud
// artnet based on Artnet for Java and Processing
// patterns based on LED jacket patterns

// to run from command-line 
// processing-java --sketch="/home/pi/Documents/git/EtherealFleeting/rasPi/ArtnetTesting/" --run

import ch.bildspur.artnet.*;
import processing.serial.*;

//___________________________
// setup pattern
boolean readFromScreen = false;
boolean readFromImage = true;
boolean writeToScreen = true;
boolean readAnemometerSerial = false;



//___________________________
// setup artnet 
ArtNetClient artnet;
int numLedUniverse = 48; // 48 eventually + 4 for smoke machine and 4 for the lighting
int numLedChannels = 450;
byte[] dmxData = new byte[numLedChannels];
ArtnetDMX LedArtnetclass = new ArtnetDMX();
color[][] pixelBuffer = new color[numLedChannels/3][numLedUniverse];
int numFogChannels = 12; // 4 towers, only use red values
int numFogUniverse = numLedUniverse + 1;
int numFloodChannels = 21; // 7 msg x 3 channels
ArtnetDMX FogArtnetclass = new ArtnetDMX();
color[][] fogPixelBuffer = new color[numFogChannels/3][numFogUniverse];
byte[] dmxFogData = new byte[numFogChannels];


//___________________________
// stetup serial
Serial port;  // Create object from Serial class
String data = "0 0";     // Data received from the serial port
int[] nums;
byte[] inBuffer = new byte[4];

int windSpeed;
int windDir;
float windSpeedCal;

//___________________________ 
// setup leds
int numLeds = 300;
int numStrands = 24;
color led[][];
int size = 8;

//___________________________
// setup timer
long[] ellapseTimeMs = new long[numLedUniverse];
long[] ellapseTimeMsStartTime = new long[numLedUniverse];
float durationMs = 3000;
boolean direction = true; 
boolean directionFog = true; 

int numFogMachines = 4;
long[] ellapseFogTimeMs = new long[numFogMachines];
long[] ellapseFogTimeMsStartTime = new long[numFogMachines];
float durationFogMs = 5000;

//___________________________
// setup read image
int ledPixels = 170;


int maxImages = 5; // Total # of images

// Declaring an array of images.
PImage[] images = new PImage[maxImages];

//_________________________________________________________
void setup()
{
  size(2400, 600);
  //size(400, 200);
  colorMode(HSB, 360, 100, 100);
  textAlign(CENTER, CENTER);
  textSize(20);
  frameRate = 44;

  // set the number of Leds on one strand
  numLeds = 300;
  //numLeds = numLedChannels/3
  led = new color[numLeds][numStrands];
  // create artnet client without buffer (no receving needed)
  artnet = new ArtNetClient(null);
  artnet.start();

  // create port
  if (readAnemometerSerial == true) {
    String portName = Serial.list()[0];
    port = new Serial(this, portName, 2000000);
  }


  for (int i = 0; i < images.length; i ++ ) {
    images[i] = loadImage( "cloud" + i + ".jpg" );
  }
}

//_________________________________________________________
void draw()
{
  // create color
  int c = color(frameCount % 360, 80, 100);

  background(0);
  stroke(0);

  //change direction
  if (ellapseTimeMs[0]> durationMs) direction = !direction;
  // choose pattern to run on LED strip
  // int pattern = 0;  





  int imageStartX = 0;
  int imageStartY = 0;

  int imageWidth = 600*2;
  int imageHeight = 24;



    for (int i = 0; i < images.length; i++) {

      tint(255, imageBrightness(i));

      int verticalPos = imageHeight - frameCount % imageHeight;
      
      image(images[i], imageStartX, imageStartY+verticalPos-imageHeight, imageWidth, imageHeight);
      pushMatrix();
      //rotate(PI);
      scale(1.0, -1.0);
      image(images[i], imageStartX, imageStartY-verticalPos-imageHeight, imageWidth, imageHeight);
      popMatrix(); 
  }

  

  loadPixels();

  updatePixelBufferFromScreen();


  //strokeColor(1)
  stroke(255);
  noFill();
  rect(imageStartX, imageStartY, imageWidth, imageHeight);
  //noStroke();
  stroke(0);

  drawPixelBuffer();

  LedArtnetclass.updateArtnet(artnet, dmxData, pixelBuffer, numLedUniverse, numLedChannels);
  FogArtnetclass.updateFogArtnet(artnet, dmxFogData, fogPixelBuffer, numFogUniverse, numFogChannels);
  delay(1);

  updateEllapseTime();

  println(frameRate);
}

// clock function
void updateEllapseTime() {
  for (int j = 0; j < numLedUniverse; j++) {
    if (ellapseTimeMsStartTime[j] == 0) {
      ellapseTimeMsStartTime[j] = millis();
      ellapseTimeMs[j] = 0;
    } else {
      ellapseTimeMs[j] = millis() - ellapseTimeMsStartTime[j];
    }
  }
}



// storing pixels from screen
void updatePixelBufferFromScreen() {

  for (int i = 0; i < numLedChannels/3; i++) { 

    // first half of pattern
    for (int j = 0; j < numLedUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][j] = get(i, j/2);
    }

    // second half of pattern
    for (int j = 1; j < numLedUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][j] = get(i+numLeds/2, j/2);
    }
  }
}



void drawPixelBuffer() {
  for (int i = 0; i < numLedChannels/3; i++) { 
    for (int j = 0; j < numLedUniverse; j++) {
      drawPixelBuffer(i, j, pixelBuffer);
    }
  }
}


void drawPixelBuffer(int i, int j, color[][] pixelBuffer) {
  int YDrawOffset = 200;
  int pixelBSize = 4;
  color[][] drawPixelBuffer = pixelBuffer;
  fill(drawPixelBuffer[i][j]);
  //rect(i*pixelBSize, (j*pixelBSize), pixelBSize, pixelBSize);
  // recompose the split universes in space
  if (j%2 == 0) {
    rect(i*pixelBSize, YDrawOffset +j/2*pixelBSize, pixelBSize, pixelBSize);
  }
  if (j%2 == 1) {
    rect((i+numLeds/2)*pixelBSize, YDrawOffset +(j-1)/2*pixelBSize, pixelBSize, pixelBSize);
  }
}


int imageBrightness(int index) {

  return (frameCount + index*20) % 255;
  
  
}