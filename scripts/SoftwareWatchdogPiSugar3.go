/*
 * Copyright (c) 2026. All rights reserved.
 * File Name: pisugar_watchdog.go
 * Description: 基于 PiSugar3 寄存器协议的软件看门狗监控程序（日志优化版）
 * Author: Gemini
 * Create Date: 2026-04-07
 */

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"periph.io/x/conn/v3/i2c"
	"periph.io/x/conn/v3/i2c/i2creg"
	"periph.io/x/host/v3"
)

const (
	I2CBus           = 1
	DeviceAddr       = 0x57
	WpRegister       = 0x0B
	WpWriteCode      = 0x29
	WpExpected       = 0x01
	WdtCtrlRegister  = 0x06
	WdtTimeoutReg    = 0x07
	WdtEnableMask    = 0x80
	WdtFeedMask      = 0x20
	WatchdogTimeout  = 15   // 30秒
	RetryTimes       = 3
	RetryInterval    = 1 * time.Second
)

type PiSugar struct {
	dev *i2c.Dev
}

func NewPiSugar() (*PiSugar, error) {
	if _, err := host.Init(); err != nil {
		return nil, fmt.Errorf("硬件环境初始化失败: %v", err)
	}
	bus, err := i2creg.Open(fmt.Sprintf("/dev/i2c-%d", I2CBus))
	if err != nil {
		return nil, fmt.Errorf("无法打开 I2C 总线: %v", err)
	}
	return &PiSugar{dev: &i2c.Dev{Bus: bus, Addr: DeviceAddr}}, nil
}

func (p *PiSugar) writeReg(reg byte, val byte) error {
	var err error
	for i := 1; i <= RetryTimes; i++ {
		if err = p.dev.Tx([]byte{reg, val}, nil); err == nil {
			return nil
		}
		time.Sleep(RetryInterval)
	}
	return err
}

func (p *PiSugar) readReg(reg byte) (byte, error) {
	var err error
	buf := make([]byte, 1)
	for i := 1; i <= RetryTimes; i++ {
		if err = p.dev.Tx([]byte{reg}, buf); err == nil {
			return buf[0], nil
		}
		time.Sleep(RetryInterval)
	}
	return 0, err
}

func (p *PiSugar) DisableWriteProtection() error {
	for i := 1; i <= 10; i++ {
		_ = p.writeReg(WpRegister, WpWriteCode)
		status, err := p.readReg(WpRegister)
		if err == nil && (status&0x01 == WpExpected) {
			log.Printf("[成功] 写保护已解除 (寄存器 0x0B: 0x%02X)", status)
			return nil
		}
		time.Sleep(5 * time.Second)
	}
	return fmt.Errorf("无法解除写保护")
}

func (p *PiSugar) StartWatchdog() error {
	if err := p.writeReg(WdtTimeoutReg, WatchdogTimeout); err != nil {
		return err
	}
	curr, err := p.readReg(WdtCtrlRegister)
	if err != nil {
		return err
	}
	newVal := curr | WdtEnableMask
	if err := p.writeReg(WdtCtrlRegister, newVal); err != nil {
		return err
	}
	log.Printf("[状态] 软件看门狗已激活 (寄存器 0x06: 0x%02X)", newVal)
	return nil
}

func (p *PiSugar) StopWatchdog() error {
	curr, err := p.readReg(WdtCtrlRegister)
	if err != nil {
		return err
	}
	newVal := curr &^ WdtEnableMask
	return p.writeReg(WdtCtrlRegister, newVal)
}

func (p *PiSugar) Feed() error {
	curr, err := p.readReg(WdtCtrlRegister)
	if err != nil {
		return err
	}
	return p.writeReg(WdtCtrlRegister, curr|WdtFeedMask)
}

func main() {
	log.SetFlags(log.LstdFlags | log.Lmsgprefix)
	
	sugar, err := NewPiSugar()
	if err != nil {
		log.Fatalf("[错误] %v", err)
	}

	if err := sugar.DisableWriteProtection(); err != nil {
		log.Fatalf("[错误] %v", err)
	}

	if err := sugar.StartWatchdog(); err != nil {
		log.Fatalf("[错误] %v", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 喂狗协程：静默运行
	go func() {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				// 仅在出错时输出日志
				if err := sugar.Feed(); err != nil {
					log.Printf("[警告] 喂狗失败: %v", err)
				}
			case <-ctx.Done():
				return
			}
		}
	}()

	log.Println("[信息] 服务已就绪，正在静默监控系统状态...")
	
	<-sigChan
	cancel()
	
	if err := sugar.StopWatchdog(); err != nil {
		log.Printf("[错误] 关闭看门狗失败: %v", err)
	}
	log.Println("[信息] 硬件看门狗已安全关闭，程序正常退出。")
}