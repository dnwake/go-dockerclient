package main

import (
	"github.com/dnwake/go-dockerclient"
	"os"
	"strings"
)

func main() {
	client, _ := docker.NewClientFromEnv()
	arg := os.Args[1]
	tagIndex := strings.LastIndex(arg, ":")
	tag := "latest"
	repository := arg

	if tagIndex != -1 {
		tag = arg[tagIndex+1:]
		repository = arg[:tagIndex]
	}

	spec := docker.PullImageOptions{Repository: repository, Tag: tag, OutputStream: os.Stdout}
	authConfiguration := docker.AuthConfiguration{}
	client.PullImage(spec, authConfiguration)
}
