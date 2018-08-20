public class PoofEvents { 

  public int poofEventDurationMin = 1000;  
  public int poofEventDurationMax = 30000;  

  public boolean poof = false;

  public int poofBetweenMin = 5000;
  public int poofBetweenMax = 10000;

  public int poofDurationMin = 500;
  public int poofDurationMax = 1000;

  public int poofCountMin = 1;
  public int poofCountMax = 5;

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
  int fogEventDuration = 1000 * 60 * 5; // 5min

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



    println(
      getPoofEllapseTime() + "ms ellapse " + 
      poofs + " " +
      poofDuration + "ms poof duration " +
      poofEventDuration/1000+ "s between poof " +
      poofCount+ " poof count "); 

    updatePoofTimers();

    return poof;
  }


  void enablePoof() {
    poof = true;
    if (poofNotCounted) { 
      poofs++; 
      poofNotCounted = false;
    }
  }

  void disablePoof() {
    poof = false;
    poofNotCounted = true;
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
  }

  void resetFogEvent() {
    resetPoofTime(FOG_EVENT_DURATION);
    resetPoofCount();
  }

  void resetPoofTime(int timer) {
    ellapseTimeMsStartTime[timer] = 0;
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