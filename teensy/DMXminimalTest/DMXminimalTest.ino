/* Welcome to DmxSimple. This library allows you to control DMX stage and
** architectural lighting and visual effects easily from Arduino. DmxSimple
** is compatible with the Tinker.it! DMX shield and all known DIY Arduino
** DMX control circuits.
**
** DmxSimple is available from: http://code.google.com/p/tinkerit/
** Help and support: http://groups.google.com/group/dmxsimple       */

/* To use DmxSimple, you will need the following line. Arduino will
** auto-insert it if you select Sketch > Import Library > DmxSimple. */

#include <DmxSimple.h>

void setup() {
  pinMode(13, OUTPUT);
  digitalWrite(13, HIGH);
  /* The most common pin for DMX output is pin 3, which DmxSimple
  ** uses by default. If you need to change that, do it here. */
  DmxSimple.usePin(1);

  /* DMX devices typically need to receive a complete set of channels
  ** even if you only need to adjust the first channel. You can
  ** easily change the number of channels sent here. If you don't
  ** do this, DmxSimple will set the maximum channel number to the
  ** highest channel you DmxSimple.write() to. */
  DmxSimple.maxChannel(1);
}

void loop() {

  DmxSimple.write(1, 255);
  delay(500);

  DmxSimple.write(1, 0);
  delay(20000);
  
  DmxSimple.write(1, 255);
  delay(300);

  DmxSimple.write(1, 0);
  delay(15000);

  DmxSimple.write(1, 255);
  delay(500);

  DmxSimple.write(1, 0);
  delay(60000);


}
