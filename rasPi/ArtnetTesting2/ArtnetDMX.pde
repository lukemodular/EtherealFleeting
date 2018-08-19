public class ArtnetDMX {

  String[] ipAddressList = {"10.10.10.11", "10.10.10.12", "10.10.10.13", "10.10.10.14"};
  int numUniverseInTower = 14;
  int numTowers = 4;
  int xoffset = 0;

  void updateArtnet(ArtNetClient artnet, byte[][] dmxData, color[][] pixelBuffer, int universe, int channels) {
    int numChannels = channels;
    int numUniverse = universe;

    for (int j = 0; j < numUniverse; j++) {
      for (int i = 0; i < numChannels/3; i++) {
        dmxData[j][i*3] = (byte) red(pixelBuffer[i+xoffset][j]);
        dmxData[j][i*3+1] = (byte) green(pixelBuffer[i+xoffset][j]);
        dmxData[j][i*3+2] = (byte) blue(pixelBuffer[i+xoffset][j]);
      }
    }
  }

  void sendArtnet(byte[][] dmxData, int numUniverse) {
    for (int j = 0; j < numUniverse; j++) {
      artnet.unicastDmx(ipAddressList[getTowerNumber(j)], 0, j%14, dmxData[j]);
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