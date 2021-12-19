#!/usr/bin/env bash
S6_VERSION=v1.22.1.0

usage(){
    echo "Usage: ./build.sh <PHP Version>"
    exit 1
}

main () {
	[[ -z "$1" ]] && usage
    rm -fR files/s6-overlay
    mkdir -p files/s6-overlay
    wget -c https://github.com/just-containers/s6-overlay/releases/download/"$S6_VERSION"/s6-overlay-amd64.tar.gz -O - | tar -xz -C files/s6-overlay
    docker build -t juancbdm/webstack:"$1" -f Dockerfile-"$1" --pull .
    docker run -d -p 8080:80 --name juancbdm_webstack_instance juancbdm/webstack:"$1"
    echo "Testeing version $1..."
	sleep 10
	docker exec -t juancbdm_webstack_instance php-fpm --version | grep -q "PHP $1" && echo "PHP Version is $1" || echo "Container PHP Version Fail "
	wget -q localhost:8080 -O- | grep -q "PHP Version $1" && echo "Container up and running" || echo "Container is up Fail"
	docker ps | grep juancbdm_webstack_instance | grep -q "(healthy)" && echo "Container is healthy" || echo "Container healthy Fail"
    echo "Clean, build, running and testing juancbdm/webstack:$1"
    }
main "$@"