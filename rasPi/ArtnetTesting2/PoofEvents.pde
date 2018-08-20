public class PoofEvents { 

  public int poofEventDurationMin = 1000;  //1000
  public int poofEventDurationMax = 3000;  //30000

  public boolean poof = false;
  public boolean flood = false;

  public int poofBetweenMin = 1500;
  public int poofBetweenMax = 2500;

  public int poofDurationMin = 500;
  public int poofDurationMax = 1500;

  public int poofCountMin = 1;
  public int poofCountMax = 5;

  public int preFogMin = 3000;
  public int preFogMax = 5000; // 60000

  // after all poofs stopped, how much longer to leave floodlights on
  public int floodAddMin = 2000;
  public int floodAddMax = 5000; 

  static final int POOF_DURATION = 0;
  static final int POOF_EVENT_DURATION = 1;
  static final int FOG_EVENT_DURATION = 2;

  long[] ellapseTimeMs = new long[3];
  long[] ellapseTimeMsStartTime = new long[3];

  int poofCount = 3;
  int poofs = 0;
  boolean poofNotCounted = true;

  int poofDuration = 2000;
  int poofEventDuration = 1000;
  int totalPoofsDuration = 0;
  int fogEventDuration = 15000; // 5min
  int preFogEventDuration = 3000; // variable
  int floodResetDuration = fogEventDuration - preFogEventDuration;
  int floodEventDuration = 5000; // calculate fog duration length and add random
  int additionalFloodTime = 2000;
  boolean gotNewDuration = false;

  boolean updatePoofEvent() {

    //background(poof ? 255 : 0);

    // check if we are in a poof
    if (getPoofEllapseTime() > poofDuration) {
      disablePoof();
    } else {
      enablePoof();
    }

    // check if there are more poofs in this fog event
    if (poofs < poofCount) {

      // start the next poof?
      if (getPoofEllapseTime() > poofEventDuration) {
        resetPoofEvent();
      }
    }

    // start the next fog event (reset poof counts)
    if (getFogEventEllapseTime() > fogEventDuration ) {
      resetFogEvent();
    }

    //println(getPoofEllapseTime() + " " + poofs + " " +poofDuration + " " +poofEventDuration+ " " +poofCount+ " "); 
    updatePoofTimers();

    if (poofs == poofCount) {
      //  println("not poofing");
    }
    return poof;
  }

  boolean updateFloodEvent() {

    // floodlight timer
    if (!gotNewDuration && poofs == poofCount) { // if not recalculated and poofing has stopped
      // get new floodlight duration: stop after total poof times and a new random

      additionalFloodTime = getNewAddFloodDuration();
      floodEventDuration = additionalFloodTime + totalPoofsDuration ;

      preFogEventDuration = getNewPreFogEventDuration();
      floodResetDuration = fogEventDuration - preFogEventDuration;
      gotNewDuration = true;
      println("poof duration"+totalPoofsDuration+" "+additionalFloodTime + " "+preFogEventDuration);
    }

    if (getFogEventEllapseTime() > floodEventDuration){
      //println("floodevent"+floodEventDuration);
      resetFloodEvent();  // turm flood off, get new time for when to start again
    }

    // 
    if (getFogEventEllapseTime() > floodResetDuration) {
      floodEvent(); // check if flood should be on, then turn on, get additional floodtime
    } 

    int floodLength = preFogEventDuration + floodEventDuration;
    //println("flood? "+flood +" "+ floodLength+ " " +poofCount+" "+additionalFloodTime+" "+gotNewDuration);
    return flood;
  }

  void enablePoof() {
    poof = true;
    if (poofNotCounted) { 
      poofs++; 
      totalPoofsDuration += poofEventDuration;
      poofNotCounted = false;
    }
  }

  void disablePoof() {
    poof = false;
    poofNotCounted = true; // poof chain event is over
  }

  void resetPoofCount() {
    poofs = 0;
    poofNotCounted = true;
    poofCount = getNewPoofCount();
  }

  ////////
  // RESET EVENTS

  void resetPoofEvent() {
    resetPoofTime(POOF_DURATION);
    poofDuration = getNewPoofDuration();
    poofEventDuration = getNewPoofEventDuration();
    totalPoofsDuration = 0;
  }

  void resetFogEvent() {
    resetPoofTime(FOG_EVENT_DURATION);
    resetPoofCount();
    gotNewDuration = false;
  }

  // reset 1 of the 3 event timers
  void resetPoofTime(int timer) {
    ellapseTimeMsStartTime[timer] = 0;
  }

  void resetFloodEvent() {
    flood = false;
  }

  void floodEvent() {
    flood = true;
  }



  //////
  // RANDOM 

  int getNewPoofEventDuration() {
    return (int)random(poofEventDurationMin, poofEventDurationMax);
  }

  int getNewBetweenDuration() {
    return (int)random(poofBetweenMin, poofBetweenMax);
  }

  int getNewPoofDuration() {
    return (int)random(poofDurationMin, poofDurationMax);
  }

  int getNewPoofCount() {
    return (int)random(poofCountMin, poofCountMax);
  }

  int getNewPreFogEventDuration() {
    return (int)random(preFogMin, preFogMax);
  }

  int getNewAddFloodDuration() {
    return (int)random(floodAddMin, floodAddMax);
  }
  ///////
  // TIMERS

  long getPoofEllapseTime() {
    return getEventTime(POOF_DURATION);
  }

  long getPoofEventEllapseTime() {
    return getEventTime(POOF_EVENT_DURATION);
  }

  long getFogEventEllapseTime() {
    return getEventTime(FOG_EVENT_DURATION);
  }

  long getEventTime(int timer) {
    return ellapseTimeMs[timer];
  }

  // clock function
  void updatePoofTimers() {
    for (int j = 0; j < ellapseTimeMs.length; j++) {
      if (ellapseTimeMsStartTime[j] == 0) {
        ellapseTimeMsStartTime[j] = millis();
        ellapseTimeMs[j] = 0;
      } else {
        ellapseTimeMs[j] = millis() - ellapseTimeMsStartTime[j];
      }
    }
  }
}