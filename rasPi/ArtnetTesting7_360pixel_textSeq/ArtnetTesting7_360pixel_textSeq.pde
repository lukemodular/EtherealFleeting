// Building the brain for EtherealFleeting 
// by @adellelin @lukemodular @mpinner and @sophi
// artnet based on Artnet for Java and Processing
// patterns based on DMXLedJacketPatterns in https://github.com/adellelin/ChatStar

// to run from command-line 
// processing-java --sketch="/home/pi/Documents/git/EtherealFleeting/rasPi/ArtnetTesting/" --run

// to do:
// anemometer on smoke and vent intensity: 255 * colorFraction --> intensity * windInfluence * colorFraction

import ch.bildspur.artnet.*;
import processing.serial.*;
import rita.*;

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
int numLedUniverse = 36; // 48 eventually + 4 for smoke machine and 4 for the lighting
//int numLedUniverse = 18; // 48 eventually + 4 for smoke machine and 4 for the lighting
int numPixelUniverse = 42;
//int numPixelUniverse = 21;
int numLedChannels = 360;  //per Universe
byte[][] dmxData = new byte[numPixelUniverse][numLedChannels];
ArtnetDMX LedArtnetclass = new ArtnetDMX();
color[][] pixelBuffer = new color[numLedChannels/3][numPixelUniverse];
int numFloodChannels = 21; // 7 msg x 3 channels

//___________________________
// setup pixelbuffer

int pixelRows = 42;
//int pixelRows = 21;
int numTowers = 2;
//int numTowers = 1;
int numStripsInTower = 18;
int pixelRowsInTower = numPixelUniverse/numTowers;
int YDrawOffset = 120;
int pixelBSize = 4;


//___________________________
// setup serial
Serial port;  // Create object from Serial class
String data = "0 0";     // Data received from the serial port
int[] nums;
byte[] inBuffer = new byte[5];
int lf = 42;      // ASCII linefeed 

int windSpeed;
int windDir;
float windSpeedCal;

//___________________________ 
// setup leds
int numLeds = 360;
int numStrands = 12;
color led[][];
int size = 3;

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
boolean poofFan = false;
color poofColor = color(0, 0, 0);
boolean flood = false;

//___________________________
// setup read image
PImage texture;
color[][] imageLed = new color[numLedChannels/3][numLedUniverse];
int imageStartX = 0;
int imageStartY = 0;
int imageWidth = 360* size;
int imageHeight = 12*size;


// Declaring an array of images
int defaultImageIndex = 0;
int maxImages = 1; // total # of images
PImage[] images = new PImage[maxImages];


//text generation
String poem = "In short, Everything is becoming absurd. Since they are no longer able to decode them, their lives become a function of their own images: Imagination has turned into hallucination. Changing the questionfree from what? intofree for what? ' ; this change that occurs when freedom has been achieved has accompanied me on my migrations like a basso continuo. This reversal of the function of the images they create. Human beings forget they created the images in order to orientate themselves in the world. This is what we are like, those of us who are nomads, who come out of the collapse of a settled way of life. Our thoughts, feelings, desires and actions are being robotized; lifeis coming to mean feeding apparatuses and being fed by them. So where is there room for human freedom? Essentially this is a question ofamnesia '. For there is a general desire to be endlessly remembered and endlessly repeatable.";
RiMarkov markov;
//String[] files = { "wittgenstein.txt", "flusser.txt" };
String[] files = { "flusser.txt" };

//_________________________________________________________
void setup()
{
  size(1800, 270);
  //size(400, 200);
  colorMode(HSB, 360, 100, 100);
  textAlign(CENTER, CENTER);
  textSize(20);
  frameRate = 50;

  //numLeds = numLedChannels/3
  led = new color[numLeds][numStrands];
  imageLed = new color[numLeds][numStrands];
  // create artnet client without buffer (no receving needed)
  artnet = new ArtNetClient(null);
  artnet.start();

  // create port
  if (readAnemometerSerial == true) {
    String portName = Serial.list()[0];
    println(portName);
    //port = new Serial(this, portName, 250000);
    port = new Serial(this, portName, 115200);
    port.bufferUntil(lf);
  }

  // load an image
  texture = loadImage("cloud1.jpg");
  int dimension = texture.width * texture.height;
  print(dimension + " " + texture.width  + " " + texture.height);
  texture.loadPixels();
  texture.updatePixels();

  // preload images
  for (int i = 0; i < images.length; i++) {
    images[i] = loadImage("cloud" + i + ".jpg");
  }

  // generate text

  // create a markov model w' n=3 from the files
  markov = new RiMarkov(3);
  markov.loadFrom(files, this);

  String[] lines = markov.generateSentences(10);
  poem = RiTa.join(lines, " ");

  poem = poem.replaceAll("\\s+", "");
  poem = poem.replaceAll("\\?", "");
  poem = poem.replaceAll("\\;", "");
  poem = poem.replaceAll("\\'", "");
  poem = poem.replaceAll("\\-", "");
  poem = poem.replaceAll("\\:", "");
  poem = poem.replaceAll("\\(", "");
  poem = poem.replaceAll("\\)", "");
  poem = poem.replaceAll("\\.", "");
  poem = poem.replaceAll("\\,", "");
  poem = poem.toLowerCase();

  println(poem);
}


//_________________________________________________________
void draw()
{
  // create color
  int c = color(frameCount % 360, 80, 100);

  background(0);
  stroke(0);

  if (readAnemometerSerial == true) { 
    //readAnemometer();
  }

  //change direction
  //if (ellapseTimeMs[0]> durationMs) direction = !direction;

  drawImageToScreen();

  loadPixels();

  drawPatternToScreen();

  // fog pattern and draw
  poof = poofEvent.updatePoofEvent();
  poofFan = poofEvent.updateFanEvent(); 
  flood = poofEvent.updateFloodEvent();
  updateFogPixels(poof);
  updateFanPixels(poofFan);
  //updateFloodPixels(flood);
  colorMode(HSB, 360, 100, 100);
  // read pattern from screen draw
  if (readFromScreen == true) {
    updatePixelBufferFromScreen();
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
void updatePixelBufferFromScreen() {

  for (int i = 0; i < numLedChannels/3; i++) { 

    // split pattern to alternate universes
    // first half of pattern
    for (int j = 0; j < numLedUniverse; j+=3) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][getPixelRow(j)] = get(i*size +size/3, j/3*size+size/3);
    }
    // second half of pattern
    for (int j = 1; j < numLedUniverse; j+=3) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][getPixelRow(j)] = get((i+numLeds/3)*size +size/3, j/3*size+size/3);
    }
    // third half of pattern
    for (int j = 2; j < numLedUniverse; j+=3) {
      // read left screen pixels and assign to pixel buffer
      pixelBuffer[i][getPixelRow(j)] = get((i+(numLeds*2)/3)*size +size/3, j/3*size+size/3);
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

      fill(defaultPattern.paintLed(position, remaining, get(i*size +size/3, j*size+size/3)));
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
    for (int j = 0; j < numPixelUniverse; j+=3) {
      // read left screen pixels and assign to pixel buffer
      drawSinglePixelBuffer(i, j, pixelBuffer);
    }

    // second half of pattern
    for (int j = 1; j < numPixelUniverse; j+=3) {
      // read left screen pixels and assign to pixel buffer
      drawSinglePixelBuffer(i, j, pixelBuffer);
    }
    // third half of pattern
    for (int j = 2; j < numPixelUniverse; j+=3) {
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
  if (j%3 == 0) {
    rect(i*pixelBSize, YDrawOffset +j/3*pixelBSize, pixelBSize, pixelBSize);
  }
  if (j%3 == 1) {
    rect((i+numLeds/3)*pixelBSize, YDrawOffset +(j-1)/3*pixelBSize, pixelBSize, pixelBSize);
  }
  if (j%3 == 2) {
    rect(((i+numLeds*2)/3)*pixelBSize, YDrawOffset +(j-2)/3*pixelBSize, pixelBSize, pixelBSize);
  }
}


void serialEvent(Serial p) { 
  p.readBytes(inBuffer);
  if (inBuffer != null) {
    //println(inBuffer);
    windSpeed = (inBuffer[1] & 255) << 8 | (inBuffer[0] & 255);
    windDir = (inBuffer[3] & 255) << 8 | (inBuffer[2] & 255);
    println(windSpeed);
    println(windDir);
    windSpeedCal = map(windSpeed, 225, 20000, 1, 50);
  }
} 


//void readAnemometer() {
//  if (readAnemometerSerial == true) {
//    while (port.available() > 0) {
//      port.readBytes(inBuffer);
//      if (inBuffer != null) {
//        //println(inBuffer);
//        windSpeed = (inBuffer[1] & 255) << 8 | (inBuffer[0] & 255);
//        windDir = (inBuffer[3] & 255) << 8 | (inBuffer[2] & 255);
//        println(windSpeed);
//        println(windDir);
//        windSpeedCal = map(windSpeed, 225, 20000, 1, 50);
//      }
//    }
//    //port.clear();
//  }
//}


void updateFogPixels(boolean poof) {

  for (int tower = 0; tower < numTowers; tower++) {
    int colorFraction = poof ? 1 : 0;
    colorMode(RGB, 255);
    color fogPixelColor = color(255 * colorFraction, 0, 0);
    //color fogPixelColor = color(0, 100* colorFraction, 100 * colorFraction);
    pixelBuffer[0][tower*pixelRowsInTower+numStripsInTower] = fogPixelColor;
    //println("poof?" + poof);
    //poofColor = poof ? color(0, 100, 100) : 0;
    // draw fog pixels seperately
    fill(fogPixelColor);
    rect(pixelBSize * numLedChannels*3/3 + 100, YDrawOffset + 10, 100, 100);
    //drawPixelBuffer(0, tower*pixelRowsInTower+numStripsInTower, pixelBuffer);
  }
}


void updateFanPixels(boolean poofFan) {

  for (int tower = 0; tower < numTowers; tower++) {
    int colorFraction = poofFan? 1 : 0;
    colorMode(RGB, 255);
    color fanPixelColor = color(0, 255 * colorFraction, 0);
    //color fanPixelColor = color(120 * colorFraction, 100* colorFraction, 100 * colorFraction);
    pixelBuffer[0][tower*pixelRowsInTower+numStripsInTower+1] = fanPixelColor;
    //println("poof?" + poof);
    //poofColor = poof ? color(120, 100, 100) : 0;
    // draw fan pixels seperately
    fill(fanPixelColor);
    rect(pixelBSize * numLedChannels*3/3 + 200, YDrawOffset + 10, 100, 100);
    //drawPixelBuffer(0, tower*pixelRowsInTower+numStripsInTower, pixelBuffer);
  }
}

//void updateFloodPixels(boolean flood) {
//  for (int tower = 0; tower < numTowers; tower++) {
//    int colorFraction = flood ? 1 : 0;
//    color floodPixelColor = color(120 * colorFraction, 100* colorFraction, 100 * colorFraction);
//    pixelBuffer[0][tower*pixelRowsInTower+numStripsInTower+1] = floodPixelColor;
//    //println("poof?" + poof);
//    // draw fog pixels seperately
//    fill(floodPixelColor);
//    rect(pixelBSize * numLedChannels*3/3 + 200, YDrawOffset + 10, 100, 100);
//    //drawPixelBuffer(0, tower*pixelRowsInTower+numStripsInTower, pixelBuffer);
//  }
//}

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
  currentImageIndex = (defaultImageIndex + millis() / (10000*10)) % maxImages;

  PImage displayImage = images[currentImageIndex];

  // use current image height
  int displayImageHeight = displayImage.height;
  //imageWidth = displayImage.width;

  // create a scrolling effect by changing the vertical position
  int verticalPos = (millis()/50) % displayImageHeight;
  //int verticalPos = (millis()/playBackSpeed(50)) % displayImageHeight;

  // UNCOMMENT to test using the mouseX position for troubleshooting
  //int verticalPos = (mouseX/10) % displayImageHeight;

  // fade in 
  //tint(255, imageBrightness(200));

  // draw image at vertical position
  //if( d
  image(displayImage, imageStartX, imageStartY + verticalPos, imageWidth, displayImageHeight);

  //draw image an image height behind the vertical position
  image(displayImage, imageStartX, imageStartY + verticalPos - displayImageHeight, imageWidth, displayImageHeight);

  // flips the second image
  // pushMatrix();
  // scale(1.0, -1.0);
  //image(displayImage, imageStartX, imageStartY + verticalPos - imageHeight, imageWidth, imageHeight);
  //popMatrix();

  // blackout screen where image is not used for painting pixels;
  fill(0);
  rect(0, imageHeight+1, imageWidth, 270-imageHeight);
}


int imageBrightness(int index) {
  return (frameCount + index*2)% 255 + 100;
}


int playBackSpeed(int index) {
  return (frameCount + index)% 130 + 130;
}


// @deprecated
// scroll through an image from top to bottom
void updatePixelBufferFromImage() {
  int speed = frameCount/3;
  int pixelFrame = speed % (texture.height - numLedUniverse); // account for number of universes
  int xOffset = 150; // start more towards middle image
  for (int i = 0; i < numLedChannels/3; i++) {
    for (int j = 0; j < numLedUniverse; j+=3) {
      noStroke();
      int pixelPosition = xOffset + i + texture.width  * (j/3+pixelFrame);
      //int pixelPosition = (i+mouseX) + texture.width * (j+mouseY+30);

      pixelBuffer[i][getPixelRow(j)] = texture.pixels[pixelPosition];
      //print(texture.pixels[pixelPosition]);
      drawSinglePixelBuffer(i, getPixelRow(j), pixelBuffer);
      //imageLed[i][j/2] = texture.pixels[pixelPosition];
    }
    for (int j = 1; j < numLedUniverse; j+=3) {
      noStroke();
      int pixelPosition = xOffset + (i+numLeds/3) + texture.width  * (j/3+pixelFrame);
      //int pixelPosition = (i+mouseX) + texture.width * (j+mouseY+30);
      pixelBuffer[i][getPixelRow(j)] = texture.pixels[pixelPosition];
      drawSinglePixelBuffer(i, getPixelRow(j), pixelBuffer);
    }
    for (int j = 2; j < numLedUniverse; j+=3) {
      noStroke();
      int pixelPosition = xOffset + (i+(numLeds*2)/3) + texture.width  * (j/3+pixelFrame);
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
