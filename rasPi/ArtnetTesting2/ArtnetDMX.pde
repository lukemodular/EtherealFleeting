public class ArtnetDMX {

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
      artnet.unicastDmx("10.10.10.11", 0, j, dmxData);
      //artnet.unicastDmx("10.10.10.12", 0, j, dmxData);
      //artnet.unicastDmx("10.10.10.13", 0, j, dmxData);
      //artnet.unicastDmx("10.10.10.14", 0, j, dmxData);
      //artnet.unicastDmx("10.10.10.15", 0, j, dmxData);
      
      //artnet.unicastDmx("10.10.10.117", 0, j, dmxData);
      delay(1);

      // to broad cast data
      //artnet.broadcastDmx(0, 0, dmxData);
    }
  }
  
  void updateFogArtnet(ArtNetClient artnet, byte[] dmxData, color[][] fogPixelBuffer, int universe, int channels) {
    int numChannels = channels; //12, only take reds
    int j = universe;
    println("fog",universe);
    for (int i = 0; i < numChannels/3; i++) {
        dmxData[i*3] = (byte) red(fogPixelBuffer[i][j-1]);
        dmxData[i*3+1] = (byte) green(0);
        dmxData[i*3+2] = (byte) blue(0);
      }    
      artnet.unicastDmx("10.10.10.16", 0, j-1, dmxData);
      
      //artnet.unicastDmx("10.10.10.117", 0, j, dmxData);
      delay(1);

      // to broad cast data
      //artnet.broadcastDmx(0, 0, dmxData);
    }
  
}