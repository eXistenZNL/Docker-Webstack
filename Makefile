# Variables
S6TAG=v1.22.1.0
PROJECTNAME=existenz/webstack
TAG=UNDEF
PHP_VERSION=$(shell echo "$(TAG)" | sed -e 's/-.*//')

.PHONY: all
all: build start test stop clean

build:
	if [ "$(TAG)" = "UNDEF" ]; then echo "Please provide a valid TAG" && exit 1; fi
	docker build -t $(PROJECTNAME):$(TAG) --build-arg="S6TAG=$(S6TAG)" -f Dockerfile-$(TAG) --pull .

buildx-and-push:
	docker buildx create --use
	docker buildx build --platform=linux/amd64,linux/arm64 --build-arg="S6TAG=$(S6TAG)" -f Dockerfile-$(TAG) -t $(PROJECTNAME):$(TAG) . --push
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
	sleep 10
	docker ps | grep existenz_webstack_instance | grep -q "(healthy)"
	docker exec -t existenz_webstack_instance php-fpm --version | grep -q "PHP $(PHP_VERSION)"
	wget -q localhost:8080 -O- | grep -q "PHP Version $(PHP_VERSION)"
