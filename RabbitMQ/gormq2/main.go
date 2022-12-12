package main

import (
	"fmt"
	"os/exec"
)

func execStart(msg string) error {
	cmd := "./wechat_notice.sh " + msg
	exe := exec.Command("/bin/bash", "-c", cmd)
	fmt.Println("in execStart cmd:", cmd)
	err := exe.Start()
	if err != nil {
		fmt.Println("in execStart err:" + err.Error())
		return err
	}

	go exe.Wait()
	return err
}

func main() {

	addrs := []string{
		"10.189.6.100:9073",
		"10.189.6.101:9073",
		"10.189.6.144:9073",
		"10.189.6.145:9073",
		"10.189.6.146:9073",
		"10.189.6.147:9073",
		"10.189.6.162:9073",
		"10.189.6.163:9073",
		"10.189.6.164:9073",
	}
	//addrs2 := []string{
	//	"10.189.6.93:5172",
	//}
	rmqProducer(addrs)
	rmqConsumer(addrs)
}
