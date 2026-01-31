# Variables
PROJECTNAME=existenz/webstack
TAG=UNDEF
MODE=default
PHP_VERSION=$(shell echo "$(TAG)" | sed -e 's/-.*//')

.PHONY: all
all: build start test stop clean

build:
	if [ "$(TAG)" = "UNDEF" ]; then echo "Please provide a valid TAG" && exit 1; fi
	@if [ "$(MODE)" = "default" ]; then \
		docker build -t $(PROJECTNAME):$(TAG) --target $(MODE) --build-arg="BUILDPLATFORM=linux/amd64" -f $(TAG).Dockerfile --pull .; \
	else \
		docker build -t $(PROJECTNAME):$(TAG)-$(MODE) --target $(MODE) --build-arg="BUILDPLATFORM=linux/amd64" -f $(TAG).Dockerfile --pull .; \
	fi

buildx-and-push:
	if [ "$(TAG)" = "UNDEF" ]; then echo "Please provide a valid TAG" && exit 1; fi
	docker buildx create --use
	@if [ "$(MODE)" = "default" ]; then \
		docker buildx build --platform=linux/amd64,linux/arm64 --target $(MODE) -f $(TAG).Dockerfile -t $(PROJECTNAME):$(TAG) . --push; \
	else \
		docker buildx build --platform=linux/amd64,linux/arm64 --target $(MODE) -f $(TAG).Dockerfile -t $(PROJECTNAME):$(TAG)-$(MODE) . --push; \
	fi
	docker buildx stop

start:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	@if [ "$(MODE)" = "rootless" ]; then \
		docker run -d -p 8080:8080 --user nobody --name existenz_webstack_instance $(PROJECTNAME):$(TAG)-rootless; \
	elif [ "$(MODE)" = "default" ]; then \
		docker run -d -p 8080:80 --name existenz_webstack_instance $(PROJECTNAME):$(TAG); \
	fi

stop:
	docker stop -t0 existenz_webstack_instance || true
	docker rm existenz_webstack_instance || true

clean:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	rm -rf files/s6-overlay || true
	@if [ "$(MODE)" = "default" ]; then \
		docker rmi $(PROJECTNAME):$(TAG) || true; \
	else \
		docker rmi $(PROJECTNAME):$(TAG)-$(MODE) || true; \
	fi

test:
	if [ "$(TAG)" = "UNDEF" ]; then echo "please provide a valid TAG" && exit 1; fi
	while docker ps | grep existenz_webstack_instance | grep -q "(health: starting)"; do sleep 1; done
	docker ps | grep existenz_webstack_instance | grep -q "(healthy)"
	docker exec -t existenz_webstack_instance php-fpm --version | grep -q "PHP $(PHP_VERSION)"
	wget -q localhost:8080 -O- | grep -q "PHP Version $(PHP_VERSION)"
	if [ "$(MODE)" = "rootless" ]; then \
		wget -q localhost:8080 -O- | grep -q '<tr><td class="e">USER </td><td class="v">nobody </td></tr>'; \
	else \
		wget -q localhost:8080 -O- | grep -q '<tr><td class="e">USER </td><td class="v">php </td></tr>'; \
	fi

shell:
	docker exec -ti existenz_webstack_instance /bin/sh

logs:
	while true; do docker logs -f existenz_webstack_instance; sleep 1; done