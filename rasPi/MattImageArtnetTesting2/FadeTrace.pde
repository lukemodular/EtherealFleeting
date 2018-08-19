public class FadeTrace extends Pattern {

  color paintLed (float position, float remaining, color previous) {

    // create color
    int c = color(frameCount % 360, 80, 100);
    if (abs(remaining/2-position) < .02)
      return c;

    if (abs(1.0-remaining/2-position) < .02) 
      return c;


    // return fade
    return color(
      hue (previous), 
      saturation(previous), 
      brightness(previous - 10));
  }
}