import rita.*;

RiMarkov markov;
String line = "click to (re)generate!";
String[] files = { "wittgenstein.txt", "flusser.txt" };
//String[] files = { "flusser.txt" };
int x = 160, y = 240;

void setup()
{
  size(50, 50);

  fill(0);
  textFont(createFont("times", 16));

  // create a markov model w' n=3 from the files
  markov = new RiMarkov(4);
  markov.loadFrom(files, this);
}

void draw()
{
  background(250);
    if (frameCount%60==0) {
    if (!markov.ready()) return;
    String[] lines = markov.generateSentences(10);
    line = RiTa.join(lines, " ");
    println(line);
  }
}
