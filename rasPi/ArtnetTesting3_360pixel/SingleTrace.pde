public class SingleTrace extends Pattern {

  color paintLed (float position, float remaining, color previous) {

    //if (remaining == 0) return color(0, 0, 0);

    //// trace
    //if (abs(remaining-position) < .1)
    float limit = .09;
    remaining -= limit;
    float active = abs(1.0 - remaining-position);
    if (active < limit) {
      float value = (1.0 - active / limit) * 110;
      return color(hue(previous), 255, value);
    }

    return previous;
  }
}