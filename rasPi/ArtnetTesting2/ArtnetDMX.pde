public class ArtnetDMX {

  String[] ipAddressList = {"10.10.10.11", "10.10.10.12", "10.10.10.13", "10.10.10.14"};
  int numUniverseInTower = 12;
  int numTowers = 4;
  void updateArtnet(ArtNetClient artnet, byte[] dmxData, color[][] pixelBuffer, int universe, int channels) {
    int numChannels = channels;
    int numUniverse = universe;  
    int xoffset = 0;
    for (int j = 0; j < numUniverse; j++) {
      for (int i = 0; i < numChannels/3; i++) {
        dmxData[i*3] = (byte) red(pixelBuffer[i+xoffset][j]);
        dmxData[i*3+1] = (byte) green(pixelBuffer[i+xoffset][j]);
        dmxData[i*3+2] = (byte) blue(pixelBuffer[i+xoffset][j]);
      }
      
      artnet.unicastDmx(ipAddressList[getTowerNumber(j)], 0, j, dmxData);
      println("dmx", j, getTowerNumber(j), ipAddressList[getTowerNumber(j)]);
      //long start = System.nanoTime();
      //while (System.nanoTime()-start < 500000);
      delay(1);
       

      //if (j <= 11) {
      //  //artnet.unicastDmx("10.10.10.11", 0, j, dmxData);
      //  println("less than 11, j:", j, dmxData[j]);
      //  long start = System.nanoTime();
      //  while (System.nanoTime()-start < 1000000);
      //}
      //if (j > 11 && j < 22) {
      //  artnet.unicastDmx("10.10.10.12", 0, j, dmxData);
      //  long start = System.nanoTime();
      //  delay(1);
      //  //while (System.nanoTime()-start < 1000000); 
      //  println("j:", j, dmxData[j]);
      //}
      //if (j <= 35 && j > 23) {
      //  artnet.unicastDmx("10.10.10.13", 0, j, dmxData);
      //  long start = System.nanoTime();
      //  while (System.nanoTime()-start < 1000000);
      //}
      //if (j <= 47 && j > 35) {
      //  artnet.unicastDmx("10.10.10.14", 0, j, dmxData);
      //  long start = System.nanoTime();
      //  while (System.nanoTime()-start < 1000000);
      //}
    }
  }
  int getTowerNumber (int universe) {
    return universe/numUniverseInTower;
  }
  
  /*
  void updateFogArtnet(ArtNetClient artnet, byte[] dmxData, color[][] fogPixelBuffer, int universe, int channels) {
    int numChannels = channels; //12, only take reds
    int j = universe;
    //println("fog", universe);
    for (int i = 0; i < numChannels/3; i++) {
      dmxData[i*3] = (byte) red(fogPixelBuffer[i][j-1]);
      dmxData[i*3+1] = (byte) green(0);
      dmxData[i*3+2] = (byte) blue(0);
    }    
    //artnet.unicastDmx("10.10.10.12", 0, j-1, dmxData);
    //artnet.unicastDmx("10.10.10.12", 0, j, dmxData);
    // to broad cast data
    //artnet.broadcastDmx(0, 0, dmxData);
  }*/
}