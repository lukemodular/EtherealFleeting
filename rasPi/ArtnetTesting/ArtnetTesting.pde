// Building the brain for the cloud
// artnet based on Artnet for Java and Processing
// patterns based on LED jacket patterns

// to run from command-line 
// processing-java --sketch="/home/pi/Documents/git/EtherealFleeting/rasPi/ArtnetTesting/" --run
import ch.bildspur.artnet.*;

// setup pattern
Pattern patterns[] = {
  new TraceDown()
};

// setup timer
long ellapseTimeMs = 0;
long ellapseTimeMsStartTime = 0;
float durationMs = 3000;

// setup artnet 
ArtNetClient artnet;
int numUniverse = 10;
int numChannels = 510;
byte[] dmxData = new byte[numChannels];

// setup leds
int numLeds = 88;
color led[] = new color[numChannels/3];

int size = 12;
color[][] pixelBuffer = new color[numChannels/3][numUniverse];

void setup()
{
  
  size(1020, 250);
  
  colorMode(HSB, 360, 100, 100);
  textAlign(CENTER, CENTER);
  textSize(20);

  // create artnet client without buffer (no receving needed)
  artnet = new ArtNetClient(null);
  artnet.start();
}

void draw()
{
  // create color
  int c = color(frameCount % 360, 80, 100);
  
  background(0);
  stroke(0);
  
  // choose pattern to run on LED strip
  int pattern = 0;
  for (int i = 0; i <numChannels/3; i++){
    if (ellapseTimeMs> durationMs){
      ellapseTimeMsStartTime = 0;
    } else {
      float position = i/(float)(numChannels/3);
      float remaining = 1.0 - ellapseTimeMs/durationMs;
      led[i] = patterns[pattern].paintLed(position, remaining, led[i]);
    }
  }
  
  // draw pattern on screen
  for (int i = 0; i < numChannels/3; i++) {
    for (int j = 0; j < numUniverse; j++) {
      fill(led[i]);
      rect(i*size/2, j*size, size/2, size);
    }
  }
  
  updatePixelBuffer();
  updateArtnet();

  // to broad cast data
  //artnet.broadcastDmx(0, 0, dmxData);
  
  updateEllapseTime();
  
  // show values
  text("R: " + (int)red(c) + " Green: " + (int)green(c) + " Blue: " + (int)blue(c), width-200, height-50);
}


// clock function
void updateEllapseTime() {
  if (ellapseTimeMsStartTime == 0) {
    ellapseTimeMsStartTime = millis();
    ellapseTimeMs = 0;
  }
  else
    ellapseTimeMs = millis() - ellapseTimeMsStartTime;
}

// storing pixels from screen
void updatePixelBuffer(){
    for (int i = 0; i < numChannels/3; i++) {
    for (int j = 0; j < numUniverse; j++) {
      pixelBuffer[i][j] = get(i*size/2+(size/4), j*size+size/2);
      fill(pixelBuffer[i][j]);
      stroke(pixelBuffer[i][j]);
      rect(125+i, 200+j, 1, 1);
    }
  }
}

// fill dmx array, deploying to artnet
void updateArtnet(){
  for (int i = 0; i < numChannels/3; i++) {
    for (int j = 0; j < numUniverse; j++) {
      dmxData[i*3] = (byte) red(pixelBuffer[i][j]);
      dmxData[i*3+1] = (byte) green(pixelBuffer[i][j]);
      dmxData[i*3+2] = (byte) blue(pixelBuffer[i][j]);
      // send dmx to localhost
      artnet.unicastDmx("10.10.10.117", 0, j, dmxData);
    }

  }
}
