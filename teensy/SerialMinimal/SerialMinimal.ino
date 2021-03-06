// Wiring / Arduino Code
// Code for sensing a switch status and writing the value to the serial port.

int switchPin = 4;                       // Switch connected to pin 4

int led = 13;


void setup() {
  pinMode(switchPin, INPUT);             // Set pin 0 as an input
  Serial.begin(115200);                    // Start serial communication at 9600 bps
  //Serial.begin(38400);
  //Serial.begin(250000);

  pinMode(led, OUTPUT);
  digitalWrite(led, HIGH);
}

void loop() {
  //if (digitalRead(switchPin) == HIGH) {  // If switch is ON,
  Serial.write(1);               // send 1 to Processing
  digitalWrite(led, HIGH);
  //} else {                               // If the switch is not ON,
  delay(500);
  Serial.write(0);               // send 0 to Processing
  digitalWrite(led, LOW);
  //}
  delay(1000);                            // Wait 100 milliseconds
}
