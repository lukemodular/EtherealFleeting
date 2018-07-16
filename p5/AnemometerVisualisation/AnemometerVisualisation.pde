//to Do:
//-smooth wind speed reading (a lot)
//-why is goint ot 187 at around 358?


import processing.serial.*;

Serial myPort;  // Create object from Serial class
String data;     // Data received from the serial port
int[] nums;
byte[] inBuffer = new byte[4];

int windSpeed;
int windDir;
float windSpeedCal;


void setup() 
{
  size(600, 600);
  // I know that the first port in the serial list on my mac
  // is always my  FTDI adaptor, so I open Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[1];
  myPort = new Serial(this, portName, 2000000);
  data = "0 0";
}

void draw()
{
  //if ( myPort.available() > 0) 
  //{  // If data is available,
  //  data = myPort.readStringUntil('\n');         // read it and store it in val
  //}

  //println(data); //print it out in the console

  //nums = int(splitTokens(data));

  while (myPort.available() > 0) {
    myPort.readBytes(inBuffer);

    if (inBuffer != null) {
      println(inBuffer);

      windSpeed = (inBuffer[1] & 255) << 8 | (inBuffer[0] & 255);
      windDir = (inBuffer[3] & 255) << 8 | (inBuffer[2] & 255);
      //println(windSpeed);
      //println(windDir);
      windSpeedCal = map(windSpeed, 225, 20000, 1, 50);
    }
  }
  background(255);            
  fill(0);
  translate(width/2, height/2);
  rotate(radians(windDir));
  rect(-3, -250, 6*windSpeedCal, 300);
}
