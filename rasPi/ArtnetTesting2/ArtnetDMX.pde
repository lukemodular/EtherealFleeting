public class ArtnetDMX {

  void updateArtnet(ArtNetClient artnet, byte[] dmxData, color[][] pixelBuffer) {
    int numChannels = 150*3;
    int numUniverse = 12;
    int xoffset = 0;
    for (int j = 0; j < numUniverse; j++) {
      for (int i = 0; i < numChannels/3; i++) {
        dmxData[i*3] = (byte) red(pixelBuffer[i+xoffset][j]);
        dmxData[i*3+1] = (byte) green(pixelBuffer[i+xoffset][j]);
        dmxData[i*3+2] = (byte) blue(pixelBuffer[i+xoffset][j]);
      }
      artnet.unicastDmx("10.10.10.11", 0, j, dmxData);
      //artnet.unicastDmx("10.10.10.12", 0, j, dmxData);
      //artnet.unicastDmx("10.10.10.13", 0, j, dmxData);
      //artnet.unicastDmx("10.10.10.14", 0, j, dmxData);
      //artnet.unicastDmx("10.10.10.15", 0, j, dmxData);
      delay(1);

      // to broad cast data
      //artnet.broadcastDmx(0, 0, dmxData);
    }
  }
}
