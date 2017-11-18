.PHONY: install build run stop clean test

# Variables
PWD := $(dir $(MAKEPATH))
PROJECTNAME=existenz/webstack
TAGNAME=UNDEF

build:
	if [ "$(TAGNAME)" = "UNDEF" ]; then echo "please provide a valid TAGNAME" && exit 1; fi
	docker build -t $(PROJECTNAME):$(TAGNAME) -f Dockerfile-$(TAGNAME) --pull .

install:
	rm -rf files/s6-overlay
	mkdir files/s6-overlay
	wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz
	gunzip -c /tmp/s6-overlay-amd64.tar.gz | tar -xf - -C files/s6-overlay

run:
	if [ "$(TAGNAME)" = "UNDEF" ]; then echo "please provide a valid TAGNAME" && exit 1; fi
	docker run -d -p 8080:80 --name existenz_webstack_instance $(PROJECTNAME):$(TAGNAME)

stop:
	docker stop -t0 existenz_webstack_instance
	docker rm existenz_webstack_instance

clean:
	if [ "$(TAGNAME)" = "UNDEF" ]; then echo "please provide a valid TAGNAME" && exit 1; fi
	rm -rf files/s6-overlay
	docker rmi $(PROJECTNAME):$(TAGNAME)

test:
	if [ "$(TAGNAME)" = "UNDEF" ]; then echo "please provide a valid TAGNAME" && exit 1; fi
	docker ps | grep existenz_webstack_instance | grep -q "(healthy)"
	docker exec -t existenz_webstack_instance "php --version" | grep -q "PHP $(TAGNAME)"
	
