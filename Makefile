# Variables
PROJECTNAME=existenz/webstack
TAG=UNDEF
PHP_VERSION=$(shell echo "$(TAG)" | sed -e 's/-.*//')

.PHONY: all
all: build start test stop clean

build:
	if [ "$(TAG)" = "UNDEF" ]; then echo "Please provide a valid TAG" && exit 1; fi
	docker build -t $(PROJECTNAME):$(TAG) $(PARAMS) --build-arg="BUILDPLATFORM=linux/amd64" -f $(TAG).Dockerfile --pull .

buildx-and-push:
	docker buildx create --use
	docker buildx build --platform=linux/amd64,linux/arm64 -f $(TAG).Dockerfile -t $(PROJECTNAME):$(TAG) . --push
	docker buildx stop

start:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	docker run -d -p 8080:80 --name existenz_webstack_instance $(PROJECTNAME):$(TAG)

stop:
	docker stop -t0 existenz_webstack_instance || true
	docker rm existenz_webstack_instance || true

clean:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	rm -rf files/s6-overlay || true
	docker rmi $(PROJECTNAME):$(TAG) || true

test:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	while docker ps | grep existenz_webstack_instance | grep -q "(health: starting)"; do sleep 1; done
	docker ps | grep existenz_webstack_instance | grep -q "(healthy)"
	docker exec -t existenz_webstack_instance php-fpm --version | grep -q "PHP $(PHP_VERSION)"
	wget -q localhost:8080 -O- | grep -q "PHP Version $(PHP_VERSION)"

shell:
	docker exec -ti existenz_webstack_instance /bin/sh

logs:
	while true; do docker logs -f existenz_webstack_instance; sleep 1; done