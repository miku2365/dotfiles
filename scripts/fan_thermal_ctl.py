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
    # use BCM-->14 pin control the fan, 也就是40pin的物理引脚8，可改成别的引脚
    channel1 = 14
    temp_fan_stop = 45
    temp_fan_start = 50
    temp_fan_max = 65
    pwm_start = 50
    pwm_max = 100
    pwm = 0

    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    # close air fan first
    GPIO.setup(channel1, GPIO.OUT, initial=GPIO.LOW)
    pwm1 = GPIO.PWM(channel1,100)
    GPIO.setwarnings(False)
    is_close = True
    while True:
        temp = cpu_temp()
        if is_close:
            if temp > temp_fan_start:
                pwm1.start(0)
                pwm = int(((temp-temp_fan_start)/(temp_fan_max-temp_fan_start))*(pwm_max-pwm_start)+pwm_start)
                if(pwm >= 100):
                    pwm = 100
                print(time.ctime(), temp, '℃ open air fan PWM=', pwm)
                pwm1.ChangeDutyCycle(100)
                time.sleep(1.0)
                pwm1.ChangeDutyCycle(pwm)
                is_close = False
        else:
            pwm1.start(0)
            pwm = int(((temp-temp_fan_start)/(temp_fan_max-temp_fan_start))*(pwm_max-pwm_start)+pwm_start)
            if(pwm >= 100):
                pwm = 100
            if(pwm < pwm_start):
                pwm = pwm_start
            print(time.ctime(), temp, '℃ open air fan PWM=', pwm)
            pwm1.ChangeDutyCycle(pwm)

            if temp < temp_fan_stop:
                pwm = 0
                print(time.ctime(), temp, '℃ open air fan PWM=', pwm)
                pwm1.stop()
                is_close = True
        time.sleep(2.0)
        print(time.ctime(), temp, '℃ PWM=', pwm)
if __name__ == '__main__':
    main()
