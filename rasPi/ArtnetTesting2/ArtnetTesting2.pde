// Building the brain for the cloud
// artnet based on Artnet for Java and Processing
// patterns based on LED jacket patterns

// to run from command-line 
// processing-java --sketch="/home/pi/Documents/git/EtherealFleeting/rasPi/ArtnetTesting/" --run

import ch.bildspur.artnet.*;
import processing.serial.*;

//___________________________
// setup pattern
boolean readFromScreen = true;
boolean readFromImage = false;
boolean writeToScreen = true;
boolean readAnemometerSerial = false;

Pattern patterns[] = {
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown()
  //new FadeTrace(), new FadeTrace(), new FadeTrace(), new FadeTrace(), new FadeTrace(), new FadeTrace(), 
  //new FadeTrace(), new FadeTrace(), new FadeTrace(), new FadeTrace(), new FadeTrace(), new FadeTrace(), 
};


//___________________________
// setup artnet 
ArtNetClient artnet;
int numLedUniverse = 48; // 48 eventually + 4 for smoke machine and 4 for the lighting
int numPixelUniverse = 56;
int numLedChannels = 450;
byte[] dmxData = new byte[numLedChannels];
ArtnetDMX LedArtnetclass = new ArtnetDMX();
color[][] pixelBuffer = new color[numLedChannels/3][numPixelUniverse];
int numFogChannels = 12; // 4 towers, only use red values
int numFogUniverse = numLedUniverse + 1;
int numFloodChannels = 21; // 7 msg x 3 channels
ArtnetDMX FogArtnetclass = new ArtnetDMX();
color[][] fogPixelBuffer = new color[numFogChannels/3][numFogUniverse];
byte[] dmxFogData = new byte[numFogChannels];

//___________________________
// setup pixelbuffer

int pixelRows = 56;
int numTowers = 4;
int numStripsInTower = 12;
int imageRows = 48;
int pixelRowsInTower = numPixelUniverse/numTowers;


//___________________________
// setup serial
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
int size = 4;

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

long[] ellapseFogEventTimeMs = new long[numFogMachines];
long[] ellapseFogEventTimeMsStartTime = new long[numFogMachines];

float durationFogMs = 5000;
float durationFogEventMs = 5000;

//___________________________
// setup read image
PImage texture;
int ledPixels = 170;


//_________________________________________________________
void setup()
{
  size(1200, 200);
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

  // load an image
  texture = loadImage("fish.jpeg");
  int dimension = texture.width * texture.height;
  print(dimension + " " + texture.width  + " " + texture.height);
  texture.loadPixels();
  texture.updatePixels();
}

//_________________________________________________________
void draw()
{
  // create color
  int c = color(frameCount % 360, 80, 100);

  background(0);
  stroke(0);

  if (readAnemometerSerial == true) { 
    readAnemometer();
  }

  //change direction
  if (ellapseTimeMs[0]> durationMs) direction = !direction;
  // choose pattern to run on LED strip
  // int pattern = 0;  

  for (int i = 0; i <numLeds; i++) {
    for (int j = 0; j < numStrands; j++) {
      if (ellapseTimeMs[j]> durationMs) {
        ellapseTimeMsStartTime[j] = 0;
      } else if (direction==true) {
        float position = i/(float)(numLeds);
        float remaining = 1.0 - ellapseTimeMs[j]/durationMs;
        if (readFromScreen == false && readFromImage == false) {
          pixelBuffer[i][j] = patterns[j].paintLed(position, remaining, pixelBuffer[i][j]);
        } else {
          led[i][j] = patterns[j].paintLed(position, remaining, led[i][j]);
        }
      } else {
        float position = 1.0 - (i/(float)(numLeds));
        float remaining = ellapseTimeMs[j]/durationMs;
        if (readFromScreen == false && readFromImage == false) {
          pixelBuffer[i][j] = patterns[j].paintLed(position, remaining, pixelBuffer[i][j]);
        } else {
          led[i][j] = patterns[j].paintLed(position, remaining, led[i][j]);
        }
      }
    }
  }

  // show loaded image on screen
  if (writeToScreen == true) {
    showPattern(numLeds);
    image(texture, width*2/3, 200);
  }

  // read pattern from screen draw
  if (readFromScreen == true) {
    updatePixelBufferFromPattern();
  } 

  // read pattern from screen draw
  if (readFromImage == true) {
    updatePixelBufferFromImage();
  } 

  updateFogPixels();

  LedArtnetclass.updateArtnet(artnet, dmxData, pixelBuffer, numPixelUniverse, numLedChannels);
  //FogArtnetclass.updateFogArtnet(artnet, dmxFogData, fogPixelBuffer, numFogUniverse, numFogChannels);
  delay(1);

  updateEllapseTime();

  if (ellapseFogTimeMs[0]> durationFogMs) {
    directionFog = !directionFog;    
    ellapseFogTimeMsStartTime[0] = 0;
  }
  updateEllapseFogTime();
  println(frameRate);

  // show values
  //text("R: " + (int)red(c) + " Green: " + (int)green(c) + " Blue: " + (int)blue(c), width-200, height-50);
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
void updatePixelBufferFromPattern() {

  for (int i = 0; i < numLedChannels/3; i++) { 

    // split pattern to alternate universes
    // first half of pattern
    for (int j = 0; j < numLedUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      // for (int pixels = 0; pixels < pixelRows/3-2; pixels+=2) {
      pixelBuffer[i][getPixelRow(j)] = get(i*size +size/2, j/2*size+size/2);
      drawPixelBuffer(i, getPixelRow(j), pixelBuffer);
    }


    // second half of pattern

    for (int j = 1; j < numLedUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][getPixelRow(j)] = get((i+numLeds/2)*size +size/2, j/2*size+size/2);
      drawPixelBuffer(i, getPixelRow(j), pixelBuffer);
    }
  }

  /* //split 0-6, 7-12
   // first half of pattern
   for (int j = 0; j < numLedUniverse/2; j++) {
   // read left screen pixels and assign to pixel buffer
   pixelBuffer[i][j] = get(i*size +size/2, j*size+size/2);
   drawPixelBuffer(i, j);
   }
   // second half of pattern
   for (int j = numLedUniverse/2; j < numLedUniverse; j++) {
   // read right side of screen pixels and assign to pixel buffer
   pixelBuffer[i][j] = get((i+numLeds/2)*size +size/2, (j-numLedUniverse/2)*size+size/2);
   drawPixelBuffer(i, j);
   }
   */
}

// draw pattern on screen
void showPattern(int numLeds) {
  for (int i = 0; i < numLeds; i++) {
    for (int j = 0; j < numStrands; j++) {
      // show only pixel buffer if not reading from screen
      if (readFromScreen) {
        fill(led[i][j]);
        rect(i*size, j*size, size, size);
      }
    }
  }
}

// scroll through an image from top to bottom
void updatePixelBufferFromImage() {
  int speed = frameCount/3;
  int pixelFrame = speed % (texture.height - numLedUniverse); // account for number of universes
  int xOffset = 150; // start more towards middle image
  for (int i = 0; i < numLedChannels/3; i++) {
    for (int j = 0; j < numLedUniverse; j+=2) {
      noStroke();
      int pixelPosition = xOffset + i + texture.width  * (j/2+pixelFrame);
      //int pixelPosition = (i+mouseX) + texture.width * (j+mouseY+30);
      pixelBuffer[i][getPixelRow(j)] = texture.pixels[pixelPosition];
      drawPixelBuffer(i, getPixelRow(j), pixelBuffer);
    }
    for (int j = 1; j < numLedUniverse; j+=2) {
      noStroke();
      int pixelPosition = xOffset + (i+numLeds/2) + texture.width  * (j/2+pixelFrame);
      //int pixelPosition = (i+mouseX) + texture.width * (j+mouseY+30);
      pixelBuffer[i][getPixelRow(j)] = texture.pixels[pixelPosition];
      drawPixelBuffer(i, getPixelRow(j), pixelBuffer);
    }
  }
}

void drawPixelBuffer(int i, int j, color[][] pixelBuffer) {
  int YDrawOffset = 100;
  int pixelBSize = 3;
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

void readAnemometer() {
  if (readAnemometerSerial == true) {
    while (port.available() > 0) {
      port.readBytes(inBuffer);

      if (inBuffer != null) {
        //println(inBuffer);

        windSpeed = (inBuffer[1] & 255) << 8 | (inBuffer[0] & 255);
        windDir = (inBuffer[3] & 255) << 8 | (inBuffer[2] & 255);
        println(windSpeed);
        println(windDir);
        windSpeedCal = map(windSpeed, 225, 20000, 1, 50);
      }
    }
  }
}

void updateFogPixels() {
  for (int tower = 0; tower < numTowers; tower++) {
    float colorFraction;
    if (directionFog) {
      colorFraction = ellapseFogTimeMs[0]/ durationFogMs;
    } else {
      colorFraction = (durationFogMs-ellapseFogTimeMs[0])/ durationFogMs;
    }
    colorFraction = 1;
    pixelBuffer[0][tower*pixelRowsInTower+numStripsInTower] = color(0, 100* colorFraction, 100 * colorFraction);
    drawPixelBuffer(0, tower*pixelRowsInTower+numStripsInTower, pixelBuffer);
  }
}

// fog clock function singe event
void updateEllapseFogTime() {
  for (int i = 0; i < numFogMachines; i++) {
    if (ellapseFogTimeMsStartTime[i] == 0) {
      ellapseFogTimeMsStartTime[i] = millis();
      ellapseFogTimeMs[i] = 0;
    } else {
      ellapseFogTimeMs[i] = millis() - ellapseFogTimeMsStartTime[i];
    }
  }
}

// fog clock function event handling
void updateEllapseFogTimeEvent() {
  for (int i = 0; i < numFogMachines; i++) {
    if (ellapseFogEventTimeMsStartTime[i] == 0) {
      ellapseFogEventTimeMsStartTime[i] = millis();
      ellapseFogEventTimeMs[i] = 0;
    } else {
      ellapseFogEventTimeMs[i] = millis() - ellapseFogEventTimeMsStartTime[i];
    }
  }
}

// space imagepixels to pixelbuffer
int getPixelRow(int imageRow) {
  int towerNumber =  (int)(imageRow/numStripsInTower); 
  int towerRow = imageRow%numStripsInTower;
  return towerNumber*pixelRowsInTower + towerRow;
}
