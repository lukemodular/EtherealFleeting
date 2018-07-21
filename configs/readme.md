copy the dhcpcd.conf from here to /etc/dhcpcd.conf
in your Raspi if you want to set static ip address

then restart network
```
sudo service networking restart

sudo ifconfig eth0 down

sudo ifconfig eth0 up
```

otherwise to edit file directly

```
sudo nano /etc/dhcpcd.conf
```
Edit the following lines in the file:

interface eth0
static ip_address=192.168.1.XX/24
