.PHONY: install build run stop clean test

build:
	docker build -t existenz/webstack:5.6 -f Dockerfile-5.6 --pull .
	docker build -t existenz/webstack:7.0 -f Dockerfile-7.0 --pull .
	docker build -t existenz/webstack:7.1 -f Dockerfile-7.1 --pull .

install:
	rm -rf files/s6-overlay
	mkdir files/s6-overlay
	wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz
	gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C files/s6-overlay

run:
	docker run -d -p 8056:80 --name existenz_webstack_56 existenz/webstack:5.6
	docker run -d -p 8070:80 --name existenz_webstack_70 existenz/webstack:7.0
	docker run -d -p 8071:80 --name existenz_webstack_71 existenz/webstack:7.1

stop:
	docker stop -t0 existenz_webstack_56
	docker stop -t0 existenz_webstack_70
	docker stop -t0 existenz_webstack_71
	docker rm existenz_webstack_56
	docker rm existenz_webstack_70
	docker rm existenz_webstack_71

clean:
	rm -rf files/s6-overlay
	docker rmi existenz/webstack:5.6
	docker rmi existenz/webstack:7.0
	docker rmi existenz/webstack:7.1

test:
	docker ps | grep webstack_56 | grep -q "(healthy)"
	docker ps | grep webstack_70 | grep -q "(healthy)"
	docker ps | grep webstack_71 | grep -q "(healthy)"
