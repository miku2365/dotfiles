#coding=utf-8
#!/usr/bin/python
import sys
import time
try:
	import RPi.GPIO as GPIO
except RuntimeError:
    print("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")
def cpu_temp():
    with open("/sys/class/thermal/thermal_zone0/temp", 'r') as f:
        return float(f.read())/1000
def main():
    # use BCM-->4 pin control the fan 
    channel1 = 14

# GPIO.setmode(GPIO.BOARD)
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    # close air fan first
    temp = cpu_temp()
    GPIO.setup(channel1, GPIO.OUT, initial=GPIO.HIGH)
    print(time.ctime(), temp, 'open air fan')
    GPIO.output(channel1, 1)
    
if __name__ == '__main__':
    main()
