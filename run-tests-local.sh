#!/bin/bash

# Color codes
RED="\e[1;31m"
GREEN="\e[1;32m"
RESET="\e[0m"

runtest-default () {
    local tag=$1
    echo ""
    echo "========================================"
    echo "Testing $tag (default mode)"
    echo "========================================"
    echo ""

    echo " > Stopping any running containers..."
    make stop TAG=$tag > /dev/null 2>&1

    echo -n "   > Building... "
    if make build TAG=$tag MODE=default > /dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}FAILURE${RESET}"
        return 1
    fi

    echo -n "   > Starting... "
    if make start TAG=$tag MODE=default > /dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}FAILURE${RESET}"
        return 1
    fi

    echo -n "   > Testing... "
    if make test TAG=$tag MODE=default > /dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}FAILURE${RESET}"
        make stop TAG=$tag > /dev/null 2>&1
        return 1
    fi

    echo -n "   > Stopping... "
    make stop TAG=$tag > /dev/null 2>&1
    echo -e "${GREEN}OK${RESET}"

    echo ""
    echo -e "${GREEN}✓ Default mode passed for $tag${RESET}"
    return 0
}

runtest-rootless () {
    local tag=$1
    echo ""
    echo "========================================"
    echo "Testing $tag (rootless mode)"
    echo "========================================"
    echo ""

    echo " > Stopping any running containers..."
    make stop TAG=$tag > /dev/null 2>&1

    echo -n "   > Building... "
    if make build TAG=$tag MODE=rootless > /dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}FAILURE${RESET}"
        return 1
    fi

    echo -n "   > Starting... "
    if make start TAG=$tag MODE=rootless > /dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}FAILURE${RESET}"
        return 1
    fi

    echo -n "   > Testing... "
    if make test TAG=$tag MODE=rootless > /dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}FAILURE${RESET}"
        make stop TAG=$tag > /dev/null 2>&1
        return 1
    fi

    echo -n "   > Stopping... "
    make stop TAG=$tag > /dev/null 2>&1
    echo -e "${GREEN}OK${RESET}"

    echo ""
    echo -e "${GREEN}✓ Rootless mode passed for $tag${RESET}"
    return 0
}

# PHP 8.2 - default only
runtest-default "8.2"

# PHP 8.3 - both modes
runtest-default "8.3"
runtest-rootless "8.3"

# PHP 8.4 - both modes
runtest-default "8.4"
runtest-rootless "8.4"

# PHP 8.5 - both modes
runtest-default "8.5"
runtest-rootless "8.5"

# PHP 8.5-edge - default only
runtest-default "8.5-edge"
