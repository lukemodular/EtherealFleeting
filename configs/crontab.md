# enter this into your user environment by `crontab -e`

#trying this https://github.com/processing/processing/wiki/Running-without-a-Display
# install sudo apt-get install xvfb libxrender1 libxtst6 libxi6 


SHELL=/bin/bash

#for calling manually via ssh
#DISPLAY=":0"

# send to log for troubleshooting
#@reboot /home/alien/Downloads/processing-3.4/processing-java  --sketch="/home/alien/Documents/git/EtherealFleeting/rasPi/ArtnetTesting2" --run  > /home/alien/startup.log 2>&1 &

#send to /dev/null for performance/stability
@reboot xvfb-run /home/alien/Downloads/processing-3.4/processing-java  --sketch="/home/alien/Documen\|
ts/git/EtherealFleeting/rasPi/ArtnetTesting2" --run  > /dev/null 2>&1 &





