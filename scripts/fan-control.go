package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/stianeikeland/go-rpio/v4"
)

const (
	channel1     = 18 // BCM 18 (物理引脚 12)
	tempFanStop  = 43.0
	tempFanStart = 48.0
	tempFanMax   = 53.0
	pwmStart     = 50
	pwmMax       = 100
)

var (
	tempFile *os.File
	lastPwm  int = -1 // 记录上次 PWM 值，用于精简日志
)

// 初始化温度文件句柄，避免重复打开关闭
func initTempSensor() {
	var err error
	tempFile, err = os.OpenFile("/sys/class/thermal/thermal_zone0/temp", os.O_RDONLY, 0)
	if err != nil {
		log.Fatalf("无法打开温度文件: %v", err)
	}
}

func cpuTemp() float64 {
	// 将偏移量移回文件开头
	_, err := tempFile.Seek(0, 0)
	if err != nil {
		return 0
	}
	data := make([]byte, 10)
	n, err := tempFile.Read(data)
	if err != nil {
		return 0
	}
	tempStr := strings.TrimSpace(string(data[:n]))
	tempInt, _ := strconv.Atoi(tempStr)
	return float64(tempInt) / 1000.0
}

func runAuto(pin rpio.Pin) {
	fmt.Printf("[%s] 自动温控服务已启动 (2s检测频率)\n", time.Now().Format("15:04:05"))
	pin.Mode(rpio.Pwm)
	pin.Freq(10000)
	pin.DutyCycle(0, 100)

	isClose := true
	var pwm int

	for {
		temp := cpuTemp()

		if isClose {
			if temp > tempFanStart {
				pwm = int(((temp - tempFanStart) / (tempFanMax - tempFanStart)) * float64(pwmMax-pwmStart) + float64(pwmStart))
				if pwm > 100 { pwm = 100 }
				// 启动瞬时全速
				pin.DutyCycle(100, 100)
				time.Sleep(1 * time.Second)
				pin.DutyCycle(uint32(pwm), 100)
				isClose = false
			} else {
				pwm = 0
			}
		} else {
			pwm = int(((temp - tempFanStart) / (tempFanMax - tempFanStart)) * float64(pwmMax-pwmStart) + float64(pwmStart))
			if pwm > 100 { pwm = 100 }
			if pwm < pwmStart { pwm = pwmStart }

			pin.DutyCycle(uint32(pwm), 100)

			if temp < tempFanStop {
				pwm = 0
				pin.DutyCycle(0, 100)
				isClose = true
			}
		}

		// 只有当 PWM 发生变化时才输出日志，保护 SD 卡
		if pwm != lastPwm {
			fmt.Printf("[%s] 温度: %.2f℃ | 调整 PWM -> %d\n", time.Now().Format("15:04:05"), temp, pwm)
			lastPwm = pwm
		}

		time.Sleep(2 * time.Second)
	}
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("用法: sudo ./fan_control [auto|on|off]")
		return
	}

	cmd := os.Args[1]

	if err := rpio.Open(); err != nil {
		log.Fatalf("GPIO初始化失败: %v", err)
	}
	defer rpio.Close()
	pin := rpio.Pin(channel1)

	// 优雅退出处理
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChan
		fmt.Println("\n正在关闭程序，正在重置风扇...")
		pin.Mode(rpio.Output)
		pin.Low() // 关闭风扇
		tempFile.Close()
		rpio.Close()
		os.Exit(0)
	}()

	initTempSensor()

	switch cmd {
	case "auto":
		runAuto(pin)
	case "on":
		pin.Mode(rpio.Output)
		pin.High()
		fmt.Println("风扇已强制开启")
	case "off":
		pin.Mode(rpio.Output)
		pin.Low()
		fmt.Println("风扇已强制关闭")
	default:
		fmt.Println("未知指令")
	}
}