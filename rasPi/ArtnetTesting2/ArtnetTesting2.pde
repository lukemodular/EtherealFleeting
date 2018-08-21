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

// pick a pattern (todo: flip between patterns with some logic)
//Pattern defaultPattern = new TraceDown();
Pattern defaultPattern = new SingleTrace();


//___________________________
// setup artnet 
ArtNetClient artnet;
int numLedUniverse = 48; // 48 eventually + 4 for smoke machine and 4 for the lighting
int numPixelUniverse = 56;
int numLedChannels = 450;
byte[][] dmxData = new byte[numPixelUniverse][numLedChannels];
ArtnetDMX LedArtnetclass = new ArtnetDMX();
color[][] pixelBuffer = new color[numLedChannels/3][numPixelUniverse];
int numFloodChannels = 21; // 7 msg x 3 channels

//___________________________
// setup pixelbuffer

int pixelRows = 56;
int numTowers = 4;
int numStripsInTower = 12;
int imageRows = 48;
int pixelRowsInTower = numPixelUniverse/numTowers;
int YDrawOffset = 150;
int pixelBSize = 4;


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
int size = 2;

//___________________________
// setup timer
long[] ellapseTimeMs = new long[numLedUniverse];
long[] ellapseTimeMsStartTime = new long[numLedUniverse];
float durationMs = 3000;
boolean direction = true; 
boolean directionFog = true; 

//___________________________
// setup Fog timer
PoofEvents poofEvent = new PoofEvents();
boolean poof = false;
color poofColor = color(0, 0, 0);
boolean flood = false;

//___________________________
// setup read image
PImage texture;
int ledPixels = 170;
color[][] imageLed = new color[numLedChannels/3][numLedUniverse];
int imageStartX = 0;
int imageStartY = 0;
int imageWidth = 300* size;
int imageHeight = 24*size;


// Declaring an array of images
int defaultImageIndex = 11;
int maxImages = 12; // total # of images
PImage[] images = new PImage[maxImages];


//_________________________________________________________
void setup()
{
  size(1800, 270);
  //size(400, 200);
  colorMode(HSB, 360, 100, 100);
  textAlign(CENTER, CENTER);
  textSize(20);
  frameRate = 44;

  // set the number of Leds on one strand
  numLeds = 300;
  //numLeds = numLedChannels/3
  led = new color[numLeds][numStrands];
  imageLed = new color[numLeds][numStrands];
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

  // preload images
  for (int i = 0; i < images.length; i++) {
    images[i] = loadImage("cloud" + i + ".jpg");
  }
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
  //if (ellapseTimeMs[0]> durationMs) direction = !direction;

  drawImageToScreen();

  loadPixels();

  drawPatternToScreen();

  // fog pattern and draw
  poof = poofEvent.updatePoofEvent();  
  flood = poofEvent.updateFloodEvent();
  updateFogPixels(poof);
  updateFloodPixels(flood);

  // read pattern from screen draw
  if (readFromScreen == true) {
    updatePixelBufferFromPattern();
  } 

  LedArtnetclass.updateArtnet(artnet, dmxData, pixelBuffer, numPixelUniverse, numLedChannels);
  LedArtnetclass.sendArtnet(dmxData, numPixelUniverse);

  updateEllapseTime();

  drawPixelBuffer();

  println(frameRate);
}  // end draw()


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
      pixelBuffer[i][getPixelRow(j)] = get(i*size +size/2, j/2*size+size/2);
    }
    // second half of pattern
    for (int j = 1; j < numLedUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][getPixelRow(j)] = get((i+numLeds/2)*size +size/2, j/2*size+size/2);
    }
  }
}

float patternRemaining = 0.0;

void drawPatternToScreen() {

  // get pattern based on poof
  float remaining = poofEvent.calculatePatternRemaining();
  
  //println("Time "+ remaining);
  // remaining = 1.0 - ellapseTimeMs[j]/durationMs;

  
  // draw pattern
  for (int i = 0; i <numLeds; i++) {
    for (int j = 0; j < numStrands; j++) {

      if (ellapseTimeMs[j]> durationMs) {
        ellapseTimeMsStartTime[j] = 0;
      } 

      float position = i/(float)(numLeds);

      fill(defaultPattern.paintLed(position, remaining, get(i*size +size/2, j*size+size/2)));
      rect(i*size, j*size, size, size);
    }
  }
}



// draw stored pixels from screen
void drawPixelBuffer() {

  // bounding box for image capture region
  stroke(255);
  noFill();
  rect(0, 0, imageWidth, imageHeight);

  noStroke();

  for (int i = 0; i < numLedChannels/3; i++) { 

    // split pattern to odd and even rows

    // first half of pattern
    for (int j = 0; j < numPixelUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      drawSinglePixelBuffer(i, j, pixelBuffer);
    }

    // second half of pattern
    for (int j = 1; j < numPixelUniverse; j+=2) {
      // read left screen pixels and assign to pixel buffer
      drawSinglePixelBuffer(i, j, pixelBuffer);
    }
  }
}


void drawSinglePixelBuffer(int i, int j, color[][] pixelBuffer) {
  color[][] pixelBufferColor = pixelBuffer;
  fill(pixelBufferColor[i][j]);
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


void updateFogPixels(boolean poof) {
  //if (directionFog) {
  //  colorFraction = ellapseFogTimeMs/ durationFogMs;
  //} else {
  //  colorFraction = (durationFogMs-ellapseFogTimeMs)/ durationFogMs;
  //}

  for (int tower = 0; tower < numTowers; tower++) {
    int colorFraction = poof ? 1 : 0;
    color fogPixelColor = color(0, 100* colorFraction, 100 * colorFraction);
    pixelBuffer[0][tower*pixelRowsInTower+numStripsInTower] = fogPixelColor;
    //println("poof?" + poof);
    //poofColor = poof ? color(0, 100, 100) : 0;
    // draw fog pixels seperately
    fill(fogPixelColor);
    rect(pixelBSize * numLedChannels*2/3 + 100, YDrawOffset + 10, 100, 100);
    //drawPixelBuffer(0, tower*pixelRowsInTower+numStripsInTower, pixelBuffer);
  }
}

void updateFloodPixels(boolean flood) {
  for (int tower = 0; tower < numTowers; tower++) {
    int colorFraction = flood ? 1 : 0;
    color floodPixelColor = color(120 * colorFraction, 100* colorFraction, 100 * colorFraction);
    pixelBuffer[0][tower*pixelRowsInTower+numStripsInTower+1] = floodPixelColor;
    //println("poof?" + poof);
    // draw fog pixels seperately
    fill(floodPixelColor);
    rect(pixelBSize * numLedChannels*2/3 + 200, YDrawOffset + 10, 100, 100);
    //drawPixelBuffer(0, tower*pixelRowsInTower+numStripsInTower, pixelBuffer);
  }
}

// space imagepixels to pixelbuffer
int getPixelRow(int imageRow) {
  int towerNumber =  (int)(imageRow/numStripsInTower); 
  int towerRow = imageRow%numStripsInTower;
  return towerNumber*pixelRowsInTower + towerRow;
}


// Draw image to screen;
void drawImageToScreen() {

  int currentImageIndex = defaultImageIndex;

  // UNCOMMENT to cycle images
  currentImageIndex = (defaultImageIndex + millis() / (500*10)) % maxImages;

  PImage displayImage = images[currentImageIndex];

  // use current image height
  int displayImageHeight = displayImage.height;
  //imageWidth = displayImage.width;

  // create a scrolling effect by changing the vertical position
  //  int verticalPos = (millis()/100) % displayImageHeight;
  int verticalPos = (millis()/60) % displayImageHeight;


  // UNCOMMENT to test using the mouseX position for troubleshooting
  //int verticalPos = (mouseX/10) % displayImageHeight;

  // fade in 
  tint(255, imageBrightness(0));

  // draw image at vertical position
  image(displayImage, imageStartX, imageStartY + verticalPos, imageWidth, displayImageHeight);

  //draw image an image height behind the vertical position
  image(displayImage, imageStartX, imageStartY + verticalPos - displayImageHeight, imageWidth, displayImageHeight);

  // flips the second image
  // pushMatrix();
  // scale(1.0, -1.0);
  //image(displayImage, imageStartX, imageStartY + verticalPos - imageHeight, imageWidth, imageHeight);
  //popMatrix();

  //println(millis() +" " + verticalPos);

  // blackout screen where image is not used for painting pixels;
  fill(0);
  rect(0, imageHeight+1, imageWidth, 270-imageHeight);
}


int imageBrightness(int index) {
  return (frameCount + index*20)% 255;
}



// @deprecated
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
      //print(texture.pixels[pixelPosition]);
      drawSinglePixelBuffer(i, getPixelRow(j), pixelBuffer);
      //imageLed[i][j/2] = texture.pixels[pixelPosition];
    }
    for (int j = 1; j < numLedUniverse; j+=2) {
      noStroke();
      int pixelPosition = xOffset + (i+numLeds/2) + texture.width  * (j/2+pixelFrame);
      //int pixelPosition = (i+mouseX) + texture.width * (j+mouseY+30);
      pixelBuffer[i][getPixelRow(j)] = texture.pixels[pixelPosition];
      drawSinglePixelBuffer(i, getPixelRow(j), pixelBuffer);
    }
  }
}

/*
void reverseFogDirection() {
 if (ellapseFogTimeMs > durationFogMs) {
 directionFog = !directionFog;    
 ellapseFogTimeMsStartTime = 0;
 }
 }*/