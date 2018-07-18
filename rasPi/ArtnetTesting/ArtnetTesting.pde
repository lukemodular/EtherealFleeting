// Building the brain for the cloud
// artnet based on Artnet for Java and Processing
// patterns based on LED jacket patterns


import ch.bildspur.artnet.*;

ArtNetClient artnet;
byte[] dmxData = new byte[512];

// setup pattern
Pattern patterns[] = {
  new TraceDown()
};

color led[] = new color[20];
long ellapseTimeMs = 0;
long ellapseTimeMsStartTime = 0;

float durationMs = 3000;

void setup()
{
  size(500, 250);
  
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

  background(c);
  
  int pattern = 0;
  for (int i = 0; i <20; i++){
    if (ellapseTimeMs> durationMs){
      ellapseTimeMsStartTime = 0;
    } else {
      float position = i/20.0;
      float remaining = 1.0 - ellapseTimeMs/durationMs;
      led[i] = patterns[pattern].paintLed(position, remaining, led[i]);
      dmxData[i*3] = (byte) red(led[i]);
      dmxData[i*3+1] = (byte) green(led[i]);
      dmxData[i*3+2] = (byte) blue(led[i]);
    }
  }
   

  // fill dmx array
  // choose pattern to run on LED strip
 
  //for (int i = 0; i <20; i++){
  //  dmxData[i*3] = (byte) red(c);
  //  dmxData[i*3+1] = (byte) green(c);
  //  dmxData[i*3+2] = (byte) blue(c);
  //}

  // send dmx to localhost
  //artnet.unicastDmx("10.10.10.117", 0, 0, dmxData);
  
  // to broad cast data
  artnet.broadcastDmx(0, 0, dmxData);
  
  updateEllapseTime();

  // show values
  text("R: " + (int)red(c) + " Green: " + (int)green(c) + " Blue: " + (int)blue(c), width / 2, height / 2);
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
