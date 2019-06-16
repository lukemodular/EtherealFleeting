public class ArtnetDMX {

  String[] ipAddressList = {"10.10.10.11", "10.10.10.12", "10.10.10.13", "10.10.10.14"};
  int numUniverseInTower = 21;
  int numTowers = 2;
  int xoffset = 0;

  void updateArtnet(ArtNetClient artnet, byte[][] dmxData, color[][] pixelBuffer, int universe, int channels) {
    int numChannels = channels;
    int numUniverse = universe;

    color currentPixel;

    for (int j = 0; j < numUniverse; j++) {
      for (int i = 0; i < numChannels/3; i++) {
        //dmxData[j][i*3] = (byte) red(pixelBuffer[i+xoffset][j]);
        //dmxData[j][i*3+1] = (byte) green(pixelBuffer[i+xoffset][j]);
        //dmxData[j][i*3+2] = (byte) blue(pixelBuffer[i+xoffset][j]);

        currentPixel = pixelBuffer[i+xoffset][j];       
        dmxData[j][i*3] = (byte)((currentPixel >> 16) & 0xFF);
        dmxData[j][i*3+1] = (byte)((currentPixel >> 8) & 0xFF);
        dmxData[j][i*3+2] = (byte)(currentPixel & 0xFF);
      }
    }
  }

  void sendArtnet(byte[][] dmxData, int numUniverse) {
    for (int j = 0; j < numUniverse; j++) {
      artnet.unicastDmx(ipAddressList[getTowerNumber(j)], 0, j%numUniverseInTower, dmxData[j]);
      //println("dmx", j, getTowerNumber(j), ipAddressList[getTowerNumber(j)]);
      waitNanoseconds(300000);
    }
  }

  void waitNanoseconds(long wait) {
    long start = System.nanoTime();
    while (System.nanoTime()-start < wait);
  }

  int getTowerNumber(int universe) {
    return universe/numUniverseInTower;
  }
}
