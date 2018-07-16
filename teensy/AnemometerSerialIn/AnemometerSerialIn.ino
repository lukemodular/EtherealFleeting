//To do:
//-why is goint ot 187 and 165 at around 358?
//-1 sec or 2 sec readings for wind speed?

//based on:
//http://cactus.io/hookups/weather/anemometer/davis/hookup-arduino-to-davis-anemometer-software

#include "TimerOne.h"
#include <math.h>

#define WindSensorPin (2) // The pin location of the anemometer sensor
#define WindVanePin (A0) // The pin the wind vane sensor is connected to
#define VaneOffset 0; // define the anemometer offset from magnetic north

int VaneValue; // raw analog value from wind vane
int Direction; // translated 0 - 360 direction
int16_t CalDirection; // converted value with offset applied
int LastValue; // last direction value
byte buf[4];

//smothing
const int numReadings = 50;
int readings[numReadings];      // the readings from the analog input
int readIndex = 0;              // the index of the current reading
int total = 0;                  // the running total
int average = 0;                // the average

volatile bool IsDirSampleRequired;
volatile bool IsSpeedSampleRequired;
volatile unsigned int TimerCount;
volatile unsigned long Rotations; // cup rotation counter used in interrupt routine
volatile unsigned long CurrentRotations;
volatile unsigned long ContactBounceTime; // Timer to avoid contact bounce in isr

float WindSpeed; // speed miles per hour
int16_t WindSpeedInt; //speed * 100

void setup() {

  LastValue = 0;

  IsDirSampleRequired = false;
  IsSpeedSampleRequired = false;

  TimerCount = 0;
  Rotations = 0; // Set Rotations to 0 ready for calculations
  CurrentRotations = 0;
  Serial.begin(2000000);

  pinMode(WindSensorPin, INPUT);
  attachInterrupt(digitalPinToInterrupt(WindSensorPin), isr_rotation, FALLING);

  // Setup the timer interupt
  Timer1.initialize(10000);// Timer interrupt every 0.01 seconds
  Timer1.attachInterrupt(isr_timer);

  // initialize all the readings to 0:
  for (int thisReading = 0; thisReading < numReadings; thisReading++) {
    readings[thisReading] = 0;

  }
}

void loop() {

  getWindDirection();

  if (IsDirSampleRequired) {

    IsDirSampleRequired = false;

    if (IsSpeedSampleRequired) {
      IsSpeedSampleRequired = false;

      //According to the Davis Anemometer technical document 1 mile per hour is equal to 1600 revolutions per hour.
      // convert to mp/h using the formula V=P(2.25/T)
      // V = P(2.25/1) = P * 2.25
      // V is speed in miles per hour, P is number of pulses per sample period, T is the sample period in seconds
      CurrentRotations = Rotations;
      WindSpeed = CurrentRotations * 2.25;
      Rotations = 0; // Reset count for next sample
    }

    WindSpeedInt = WindSpeed * 100;

        buf[0] = WindSpeedInt & 255;
        buf[1] = (WindSpeedInt >> 8) & 255;
        buf[2] = CalDirection & 255;
        buf[3] = (CalDirection >> 8) & 255;
        //buf[4] = 42;
        Serial.write(buf, sizeof(buf));

    //    //debug
    //
    //        Serial.print(CurrentRotations); Serial.print("\t");
    //        Serial.print(WindSpeed); Serial.print("\t\t");
    //        Serial.print(CalDirection);
    //        getHeading(CalDirection); Serial.print("\t\t");
    //        getWindStrength(WindSpeed);

  }
}

// isr handler for timer interrupt
void isr_timer() {
  IsDirSampleRequired = true;
  TimerCount++;
  if (TimerCount == 101)
  {
    IsSpeedSampleRequired = true;
    TimerCount = 0;
  }
}

// This is the function that the interrupt calls to increment the rotation count
void isr_rotation() {
  if ((millis() - ContactBounceTime) > 15 ) { // debounce the switch contact.
    Rotations++;
    ContactBounceTime = millis();
  }
}

// Convert MPH to Knots
float getKnots(float speed) {
  return speed * 0.868976;
}

// Get Wind Direction
void getWindDirection() {

  VaneValue = analogRead(WindVanePin);

  //smoothing, only change if the change is greater than 5
  if (abs(VaneValue - LastValue) > 5) {
    LastValue = VaneValue;
  }

  total = total - readings[readIndex];
  // read from the sensor:
  readings[readIndex] = LastValue;
  // add the reading to the total:
  total = total + readings[readIndex];
  // advance to the next position in the array:
  readIndex = readIndex + 1;

  // if we're at the end of the array...
  if (readIndex >= numReadings) {
    // ...wrap around to the beginning:
    readIndex = 0;
  }

  // calculate the average:
  average = total / numReadings;

  Direction = map(average, 0, 1023, 0, 359);
  CalDirection = Direction + VaneOffset;
  if (CalDirection > 360)
    CalDirection = CalDirection - 360;
  if (CalDirection < 0)
    CalDirection = CalDirection + 360;
}

// Converts compass direction to heading
void getHeading(int direction) {
  if (direction < 22)
    Serial.print(" N");
  else if (direction < 67)
    Serial.print(" NE");
  else if (direction < 112)
    Serial.print(" E");
  else if (direction < 157)
    Serial.print(" SE");
  else if (direction < 212)
    Serial.print(" S");
  else if (direction < 247)
    Serial.print(" SW");
  else if (direction < 292)
    Serial.print(" W");
  else if (direction < 337)
    Serial.print(" NW");
  else
    Serial.print(" N");
}

// converts wind speed to wind strength
void getWindStrength(float speed) {
  if (speed < 2)
    Serial.println("Calm");
  else if (speed >= 2 && speed < 4)
    Serial.println("Light Air");
  else if (speed >= 4 && speed < 8)
    Serial.println("Light Breeze");
  else if (speed >= 8 && speed < 13)
    Serial.println("Gentle Breeze");
  else if (speed >= 13 && speed < 18)
    Serial.println("Moderate Breeze");
  else if (speed >= 18 && speed < 25)
    Serial.println("Fresh Breeze");
  else if (speed >= 25 && speed < 31)
    Serial.println("Strong Breeze");
  else if (speed >= 31 && speed < 39)
    Serial.println("Near Gale");
  else
    Serial.println("RUN");
}
