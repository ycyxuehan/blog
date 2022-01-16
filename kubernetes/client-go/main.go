package main

import (
	"context"
	"log"
	"os"
	"path/filepath"

	appsv1 "k8s.io/api/apps/v1"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	return os.Getenv("USERPROFILE") // windows
}

func connectCluster() (*kubernetes.Clientset, error) {
	conf := filepath.Join(homeDir(), ".kube", "config")
	config, err := clientcmd.BuildConfigFromFlags("", conf)
	if err != nil {
		return nil, err
	} 
	clientset, err := kubernetes.NewForConfig(config)
	return clientset, err
}

func getDeployment(client *kubernetes.Clientset, namespace, name string) (*appsv1.Deployment, error) {
	dp, err := client.AppsV1().Deployments(namespace).Get(context.Background(), name, v1.GetOptions{})
	return dp, err
}

func main() {
	client, err := connectCluster()
	if err != nil {
		log.Fatal(err)
	}
	dp, err := getDeployment(client, "server", "code-bing")
	if err != nil {
		log.Fatal(err)
	}
	for _, c := range dp.Spec.Template.Spec.Containers {
		log.Println(c.Name, c.Image)
	}
}
