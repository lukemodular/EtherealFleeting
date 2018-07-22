public class ArtnetDMX {

  void updateArtnet(ArtNetClient artnet, byte[] dmxData, color[][] pixelBuffer) {
    int numChannels = 170*3;
    int numUniverse = 10;
    
    for (int j = 0; j < numUniverse; j++) {
      for (int i = 0; i < numChannels/3; i++) {
        dmxData[i*3] = (byte) red(pixelBuffer[i][j]);
        dmxData[i*3+1] = (byte) green(pixelBuffer[i][j]);
        dmxData[i*3+2] = (byte) blue(pixelBuffer[i][j]); 
      }
      // send dmx to localhost
      artnet.unicastDmx("10.10.10.117", 0, j, dmxData);
     
    }
  }
  
  // to broad cast data
  //artnet.broadcastDmx(0, 0, dmxData);
}
