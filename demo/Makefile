IMAGE="registry.bing89.com/tools/demo:1.0"

# Build the docker image
docker-build: 
	docker build . -t ${IMAGE}

# Push the docker image
docker-push: docker-build
	docker push ${IMAGE}

