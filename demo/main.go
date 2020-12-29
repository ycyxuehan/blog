package main

import (
	"fmt"
	"log"
	"os"
	"net/http"
	"net"
)

func get(resp http.ResponseWriter, req *http.Request){
	hostname, err := os.Hostname()
	if err != nil {
		resp.Write([]byte(fmt.Sprintf("get hostname error:%v", err)))
		return
	}
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		resp.Write([]byte(fmt.Sprintf("get ip address error:%v", err)))
		return
	}
	addrString := ""
	for _, addr := range addrs{
		addrString += " " + addr.String()
	}
	resp.Write([]byte(fmt.Sprintf("response from host: %s, ip is:%s", hostname, addrString)))
}

//read the file which path is "/data/test.txt"
func readFile(resp http.ResponseWriter, req *http.Request){
	file, err := os.Open("/data/test.txt")
	if err != nil {
		resp.Write([]byte(fmt.Sprintf("open /data/test.txt error:%v", err)))
		return
	}
	defer file.Close()
	data := make([]byte, 1024)
	n, err := file.Read(data)
	if err != nil {
		resp.Write([]byte(fmt.Sprintf("read /data/test.txt error:%v", err)))
		return
	}
	resp.Write(data[0:n])
}

//write a string to the file
func writeFile(resp http.ResponseWriter, req *http.Request){
	file, err := os.OpenFile("/data/test.txt", os.O_RDWR|os.O_APPEND, os.ModePerm)
	if err != nil {
		resp.Write([]byte(fmt.Sprintf("open /data/test.txt error:%v", err)))
		return
	}
	defer file.Close()
	hostname, _ := os.Hostname()
	_, err = file.Write([]byte(fmt.Sprintf("write by pod %s", hostname)))
	if err != nil {
		resp.Write([]byte(fmt.Sprintf("write /data/test.txt error:%v", err)))
		return
	}
	resp.Write([]byte("write file successed."))
}

func main (){
	router := http.DefaultServeMux
	router.HandleFunc("/", get)
	router.HandleFunc("/read", readFile)
	router.HandleFunc("/write", writeFile)
	log.Println("listen on 0.0.0.0:8080")
	err := http.ListenAndServe("0.0.0.0:8080", nil)
	if err != nil {
		log.Fatalln(err)
	}
}