public class ArtnetDMX {

  String[] ipAddressList = {"10.10.10.11", "10.10.10.12", "10.10.10.13", "10.10.10.14"};
  int numUniverseInTower = 14;
  int numTowers = 4;
  int xoffset = 0;

  void updateArtnet(ArtNetClient artnet, byte[] dmxData, color[][] pixelBuffer, int universe, int channels) {
    int numChannels = channels;
    int numUniverse = universe;

    for (int j = 0; j < numUniverse; j++) {
      for (int i = 0; i < numChannels/3; i++) {
        dmxData[i*3] = (byte) red(pixelBuffer[i+xoffset][j]);
        dmxData[i*3+1] = (byte) green(pixelBuffer[i+xoffset][j]);
        dmxData[i*3+2] = (byte) blue(pixelBuffer[i+xoffset][j]);
      }
      // split into 4 towers
      
      artnet.unicastDmx(ipAddressList[getTowerNumber(j)], 0, j%14, dmxData);
      //println("dmx", j, getTowerNumber(j), ipAddressList[getTowerNumber(j)]);
      //artnet.unicastDmx("10.10.10.11", 0, j, dmxData);
      long start = System.nanoTime();
      while (System.nanoTime()-start < 300000);
      // to broad cast data
      //artnet.broadcastDmx(0, 0, dmxData);
    }
  }

  void updateFogArtnet(ArtNetClient artnet, byte[] dmxData, color[][] fogPixelBuffer, int universe, int channels) {
    int numChannels = channels; //12, only take reds
    int j = universe;
    println("fog", universe);
    for (int i = 0; i < numChannels/3; i++) {
      dmxData[i*3] = (byte) red(fogPixelBuffer[i][j-1]);
      dmxData[i*3+1] = (byte) green(0);
      dmxData[i*3+2] = (byte) blue(0);
    }    
    //artnet.unicastDmx("10.10.10.12", 0, j-1, dmxData);
    //artnet.unicastDmx("10.10.10.12", 0, j, dmxData);
    // to broad cast data
    //artnet.broadcastDmx(0, 0, dmxData);
  }

  int getTowerNumber(int universe) {
    return universe/numUniverseInTower;
  }
}