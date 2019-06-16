public class PoofEvents { 

  public int poofEventDurationMin = 1000;  
  public int poofEventDurationMax = 30000;  

  public boolean poof = false;
  public boolean flood = false;

  //random between fog events
  public int poofBetweenEventMin = 60000;
  public int poofBetweenEventMax = 90000; //not used for now

  public int poofDurationMin = 500;
  public int poofDurationMax = 1000;

  public int poofCountMin = 1;
  public int poofCountMax = 5;

  //time before the first poof event
  public int preFogMin = 3000;
  public int preFogMax = 5000; // 60000

  // after all poofs stopped, how much longer to leave floodlights on
  public int floodAddMin = 5000;
  public int floodAddMax = 10000; 

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

  //int totalPoofsDuration = 0;

  public int preFogEventDuration = 3000; // variable

  int floodEventDuration = 5000; // calculate fog duration length and add random
  int additionalFloodTime = 2000;
  boolean gotNewDuration = false;

  //time between Events
  int fogEventDuration = 1000 * 60 * 1; // 5min
  int floodResetDuration = fogEventDuration - preFogEventDuration;
  boolean gotChance;
  float chance = 1;

  //_________________________________________
  // setup pattern gen timers
  boolean resetPattern = false;
  int resetCount = 0;
  float remaining = 0.0;
  float timeStart = 0.0;
  float patternDurationMs = 1.0;

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

    updatePoofTimers();

    return poof;
  }

  boolean updateFloodEvent() {

    // floodlight timer, if not recalculated and poofing has stopped
    if (!gotNewDuration && poofs == poofCount) { 
      // get new floodlight duration: stop after total poof times and a new random

      additionalFloodTime = getNewAddFloodDuration();
      floodEventDuration = additionalFloodTime + (int)getFogEventEllapseTime() ;// get the time at last poof ;

      // get new flood reset time
      preFogEventDuration = getNewPreFogEventDuration();
      floodResetDuration = fogEventDuration - preFogEventDuration;

      gotNewDuration = true;
      println("additional flood time "+additionalFloodTime + " t- flood start "+preFogEventDuration );
      //println(poofCount+ " poof count "++ " "+getFogEventEllapseTime() );

      // determine in floods come on
      if (!gotChance) {
        chance = getRandomFloodChance();
        print("random "+ chance);
        gotChance = true;
      }
      resetCount = 0;
    }

    // check that new poof counts has updated and new flood event duation has calculated
    if (getFogEventEllapseTime() > floodEventDuration && poofs == poofCount) { 
      //println("floodevent"+floodEventDuration);
      resetFloodEvent();  // turm flood off, get new time for when to start again
    }

    // 
    if (getFogEventEllapseTime() > floodResetDuration ) {
      floodEvent(); // check if flood should be on, then turn on, get additional floodtime
      if (resetCount == 0) {
        resetPattern = true;
        resetCount++;
        
        // pattern stuff
        timeStart = millis(); // start pattern at preFogtimer
        patternDurationMs = preFogEventDuration;
      }
    } 

    int floodLength = preFogEventDuration + floodEventDuration;
    //println("flood? "+flood +" "+ floodLength+ " " +poofCount+" "+additionalFloodTime+" "+gotNewDuration);
    return flood;
  }

  // @deprecated
  public boolean shouldReset() {
    boolean value = resetPattern;
    resetPattern = false;
    return value;
  }


  public float calculatePatternRemaining() {
    
    remaining = 1-(millis() - timeStart)/patternDurationMs;
    if (remaining > 0)
      //println("remaining" + remaining);
      remaining = remaining;
    else remaining = 0;

    return remaining;
  }

  void enablePoof() {
    poof = true;
    if (poofNotCounted) { 
      poofs++; 
      //totalPoofsDuration += poofEventDuration;
      poofNotCounted = false;

      // logging next poof stats

      println(
        getPoofEllapseTime() + "ms ellapse " + 
        poofs + " " +
        poofDuration + "ms poof duration " +
        poofEventDuration/1000+ "s between poof " +
        poofCount+ " poof count ");
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
    timeStart = millis(); // restart geometry pattern
    // set pattern duration to leadup time to poof
    // set this to poofDuration if you want fast pattern during the poof
    patternDurationMs = poofEventDuration; 
    
  }

  void resetFogEvent() {
    resetPoofTime(FOG_EVENT_DURATION);
    resetPoofCount();
    gotNewDuration = false;

    //totalPoofsDuration = 0;
    gotChance = false;
    fogEventDuration = getNewBetweenEventDuration();
  }

  // reset 1 of the 3 event timers
  void resetPoofTime(int timer) {
    ellapseTimeMsStartTime[timer] = 0;
  }

  void resetFloodEvent() {
    if (flood) flood = false;
    //gotChance = false;
  }

  void floodEvent() {

    if (chance > .35 && !flood) 
      //print("flooding "+chance);
      flood = true;
  }

  //////
  // RANDOM 

  int getNewPoofEventDuration() {
    return (int)random(poofEventDurationMin, poofEventDurationMax);
  }

  int getNewBetweenEventDuration() {
    return (int)random(poofBetweenEventMin, poofBetweenEventMax);
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

  float getRandomFloodChance() {
    return (float)random(1);
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