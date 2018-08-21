public class SingleTrace extends Pattern {

  color paintLed (float position, float remaining, color previous) {

      if (remaining == 0) return color(0, 0, 0);

    //// trace
    //if (abs(remaining-position) < .1)
    if (abs(1.0 - remaining-position) < .1)
      return color(255, 0, 255);

    //fade
    return color(
      hue(previous), 
      saturation(previous), 
      brightness(previous)-2);
  }

}