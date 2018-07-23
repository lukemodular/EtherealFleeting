public class ArtnetDMX {

  void updateArtnet(ArtNetClient artnet, byte[] dmxData, color[][] pixelBuffer) {
    int numChannels = 170*3;
    int numUniverse = 14;
    int xoffset = 0;
    for (int j = 0; j < numUniverse; j++) {
      for (int i = 0; i < numChannels/3; i++) {
        dmxData[i*3] = (byte) red(pixelBuffer[i+xoffset][j]);
        dmxData[i*3+1] = (byte) green(pixelBuffer[i+xoffset][j]);
        dmxData[i*3+2] = (byte) blue(pixelBuffer[i+xoffset][j]);
      }
      // send dmx to localhost
      artnet.unicastDmx("192.168.2.11", 0, j, dmxData);
      delay(1);
      artnet.unicastDmx("192.168.2.12", 0, j, dmxData);
      delay(1);
      //artnet.unicastDmx("192.168.2.13", 0, j, dmxData);
      //delay(1);
      //artnet.unicastDmx("192.168.2.14", 0, j, dmxData);
      //delay(1);
      //artnet.unicastDmx("192.168.2.15", 0, j, dmxData);
      //delay(1);
    }
  }

  // to broad cast data
  //artnet.broadcastDmx(0, 0, dmxData);
}
