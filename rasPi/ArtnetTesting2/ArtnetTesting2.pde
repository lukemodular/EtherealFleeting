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
boolean writeToScreen = true;
boolean readAnemometerSerial = false;

Pattern patterns[] = {
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new FadeTrace(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown(), 
  new TraceDown() 
};


//___________________________
// setup artnet 
ArtNetClient artnet;
int numUniverse = 15;
int numChannels = 510;
byte[] dmxData = new byte[numChannels];
ArtnetDMX Artnetclass = new ArtnetDMX();

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
int numLeds = 88;
color led[][] = new color[numChannels/3][numUniverse];
int size = 8;
color[][] pixelBuffer = new color[numChannels/3][numUniverse];

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

  size(1500, 500);
  colorMode(HSB, 360, 100, 100);
  textAlign(CENTER, CENTER);
  textSize(20);

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

  image(texture, 0, 100);
  
  //change direction
  if (ellapseTimeMs[0]> durationMs) direction = !direction;
  // choose pattern to run on LED strip
  // int pattern = 0;  
  for (int i = 0; i <numChannels/3; i++) {
    for (int j = 0; j < numUniverse; j++) {
      if (ellapseTimeMs[j]> durationMs) {
        ellapseTimeMsStartTime[j] = 0;
      } else if (direction==true) {
        float position = i/(float)(numChannels/3);
        float remaining = 1.0 - ellapseTimeMs[j]/durationMs;
        if (readFromScreen == false) {
          pixelBuffer[i][j] = patterns[j].paintLed(position, remaining, led[i][j]);
        } else {
          led[i][j] = patterns[j].paintLed(position, remaining, led[i][j]);
        }
      } else {
        float position = 1.0 - (i/(float)(numChannels/3));
        float remaining = ellapseTimeMs[j]/durationMs;
        if (readFromScreen == false) {
          pixelBuffer[i][j] = patterns[j].paintLed(position, remaining, led[i][j]);
        } else {
          led[i][j] = patterns[j].paintLed(position, remaining, led[i][j]);
        }
      }
    }
  }

  if (writeToScreen == true) {
    showPattern();
  }

  // choose between read from pattern or scrolling image
  if (readFromScreen == true) {
    //updatePixelBufferFromPattern();
    updatePixelBufferFromImage();
  } 


  Artnetclass.updateArtnet(artnet, dmxData, pixelBuffer);
  //oldUpdateArtnet();

  updateEllapseTime();
  //println(frameRate);

  // show values
  //text("R: " + (int)red(c) + " Green: " + (int)green(c) + " Blue: " + (int)blue(c), width-200, height-50);
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
    for (int j = 0; j < numUniverse; j++) {
      // read screen pixels and assign to pixel buffer
      //pixelBuffer[i][j] = get(i*size/2+(size/4), j*size+size/2);
      pixelBuffer[i][j] = get(i*size +size/2, j*size+size/2);
      drawPixelBuffer(i, j);

    }
  }
}

// draw pattern on screen
void showPattern() {
  for (int i = 0; i < numChannels/3; i++) {
    for (int j = 0; j < numUniverse; j++) {
      // show only pixel buffer if not reading from screen
      if (readFromScreen == false) {
        drawPixelBuffer(i, j);
      } else {
        fill(led[i][j]);
        rect(i*size, j*size, size, size);
      }
      
    }
  }
}

// scroll through an image from top to bottom
void updatePixelBufferFromImage() {
  int speed = frameCount;
  int pixelFrame = speed % (texture.height - numUniverse); // account for number of universes
  int xOffset = 150; // start more towards middle image
  for (int j = 0; j < numUniverse; j++) {
    for (int i = 0; i < numChannels/3; i++) {
      noStroke();
      int pixelPosition = xOffset + i + texture.width  * (j+pixelFrame);
      //int pixelPosition = (i+mouseX) + texture.width * (j+mouseY+30);
      pixelBuffer[i][j] = texture.pixels[pixelPosition];
      drawPixelBuffer(i, j);
    }
  }
}

void drawPixelBuffer(int i, int j){
   fill(pixelBuffer[i][j]);
   int pixelBSize = 2;
   //rect(i*pixelBSize, (j*pixelBSize), pixelBSize, pixelBSize);
   rect( width/2+i*pixelBSize, size * numUniverse + 100+j*pixelBSize, pixelBSize, pixelBSize);

  
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

// fill dmx array, deploying to artnet
//void oldUpdateArtnet() {
//  for (int j = 0; j < numUniverse; j++) {  
//    for (int i = 0; i < numChannels/3; i++) {
//      dmxData[i*3] = (byte) red(pixelBuffer[i][j]);
//      dmxData[i*3+1] = (byte) green(pixelBuffer[i][j]);
//      dmxData[i*3+2] = (byte) blue(pixelBuffer[i][j]);
//      // send dmx to localhost
//      artnet.unicastDmx("10.10.10.117", 0, j, dmxData);
//    }
//  }
//}
