#!/bin/bash

runtest () {
    echo ""
    echo "Testing tag $1"
    echo " > Stopping any running containers.. "
    make stop TAG=$1 > /dev/null 2>&1
    echo -n " > Building... "
    make build TAG=$1 > /dev/null 2>&1
    [[ $? == 0 ]] && echo -e "\e[1;32mOK\e[0m" || echo -e "\e[1;31mFAILURE\e[0m"
    echo " > Starting... "
    make start TAG=$1 > /dev/null 2>&1
    echo -n " > Testing... "
    make test TAG=$1 > /dev/null 2>&1
    [[ $? == 0 ]] && echo -e "\e[1;32mOK\e[0m" || echo -e "\e[1;31mFAILURE\e[0m"
    echo " > Stopping... "
    make stop TAG=$1 > /dev/null 2>&1
}

runtest "8.1"
runtest "8.2"
runtest "8.3"
runtest "8.4-edge"
