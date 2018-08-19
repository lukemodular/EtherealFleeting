public class TraceDown extends Pattern {
  
  color paintLed (float position, float remaining, color previous){
    
    // create color
    int c = color(frameCount % 360, 80, 100);
    if (abs(remaining/2-position) < .07)
    return c;
    
    if (abs(1.0-remaining/2-position) < .07) 
    return c;

    
    // return fade
    return color(0,0,0);
  }
}
