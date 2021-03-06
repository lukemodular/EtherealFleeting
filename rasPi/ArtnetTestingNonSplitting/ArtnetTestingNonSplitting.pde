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
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), 
  new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown(), new TraceDown()
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace(), 
  //new FadeTrace()
};

//___________________________ 
// setup leds
int numLeds = 300;
int numStrands = 24;
color led[][];
int size = 8;

//___________________________
// setup artnet 
ArtNetClient artnet;
int numUniverse = 56; // 48 eventually + 4 for smoke machine and 4 for the lighting!!
int numChannels = 450; // channels per universe
byte[] dmxData = new byte[numChannels];
ArtnetDMX Artnetclass = new ArtnetDMX();
color[][] pixelBuffer = new color[numChannels/3][numUniverse];

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
// setup timer
long[] ellapseTimeMs = new long[numUniverse];
long[] ellapseTimeMsStartTime = new long[numUniverse];
float durationMs = 3000;
boolean direction = true; 

//___________________________
// setup read image
PImage texture;
int ledPixels = 170;


//_________________________________________________________
void setup()
{
  size(1800, 600);
  //size(400, 200);
  colorMode(HSB, 360, 100, 100);
  textAlign(CENTER, CENTER);
  textSize(20);
  //frameRate(20);

  // set the number of Leds on one strand
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

  Artnetclass.updateArtnet(artnet, dmxData, pixelBuffer);

  updateEllapseTime();
  println(frameRate);
  //delay(1);
}

// clock function
void updateEllapseTime() {
  for (int j = 0; j < numUniverse; j++) {
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

  for (int i = 0; i < numChannels/3; i++) { 

    // split pattern to alternate universes
    // first half of pattern
    for (int j = 0; j < numUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][j] = get(i*size +size/2, j/2*size+size/2);
      drawPixelBuffer(i, j);
    }
    // second half of pattern
    for (int j = 1; j < numUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][j] = get((i+numLeds/2)*size +size/2, j/2*size+size/2);
      drawPixelBuffer(i, j);
    }
  }

  /* //split 0-6, 7-12
   // first half of pattern
   for (int j = 0; j < numUniverse/2; j++) {
   // read left screen pixels and assign to pixel buffer
   pixelBuffer[i][j] = get(i*size +size/2, j*size+size/2);
   drawPixelBuffer(i, j);
   }
   // second half of pattern
   for (int j = numUniverse/2; j < numUniverse; j++) {
   // read right side of screen pixels and assign to pixel buffer
   pixelBuffer[i][j] = get((i+numLeds/2)*size +size/2, (j-numUniverse/2)*size+size/2);
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
  int pixelFrame = speed % (texture.height - numUniverse); // account for number of universes
  int xOffset = 150; // start more towards middle image
  for (int i = 0; i < numChannels/3; i++) {
    for (int j = 0; j < numUniverse; j+=2) {
      noStroke();
      int pixelPosition = xOffset + i + texture.width  * (j/2+pixelFrame);
      //int pixelPosition = (i+mouseX) + texture.width * (j+mouseY+30);
      pixelBuffer[i][j] = texture.pixels[pixelPosition];
      drawPixelBuffer(i, j);
    }
    for (int j = 1; j < numUniverse; j+=2) {
      noStroke();
      int pixelPosition = xOffset + (i+numLeds/2) + texture.width  * (j/2+pixelFrame);
      //int pixelPosition = (i+mouseX) + texture.width * (j+mouseY+30);
      pixelBuffer[i][j] = texture.pixels[pixelPosition];
      drawPixelBuffer(i, j);
    }
  }
}

void drawPixelBuffer(int i, int j) {
  int YDrawOffset = 200;
  int pixelBSize = 4;
  fill(pixelBuffer[i][j]);
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
