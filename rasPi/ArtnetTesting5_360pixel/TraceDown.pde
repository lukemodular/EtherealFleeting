public class TraceDown extends Pattern {

  color paintLed (float position, float remaining, color previous) {

    float limit = .07;
    remaining -= limit;
    float active = abs(1.0 - remaining-position);
    if (active < limit) {
      float value = (1.0 - active / limit) * brightness(previous);
      return color(frameCount % 360, 80, value);
    }
    
    active = abs(remaining-position);
    if (active < limit) {
      float value = (1.0 - active / limit) * brightness(previous);
      return color(frameCount % 360, 80, value);
    }
    

    // return fade

    return previous;
  }
}
