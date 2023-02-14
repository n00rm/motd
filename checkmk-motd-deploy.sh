#!/bin/bash

# Author: Norman Kühnberger <norman.kuehnberger@itswf.citadelle.ag>

#
# SCRIPT TO DEPLOY MOTD ON UBUNTU SERVER
#

## variables ##

SOURCES_FETCHED=false
timestamp=$(date +"%Y-%m-%dT%TZ")

## functions ##

function say() {
    echo "$timestamp MOTD INSTALLER: $1"
}

function err() {
    say "$1" >&2
    exit 1
}

function check_root() {
    if [ $EUID != 0 ]; then err "You must run this command as root."; fi
}

function need_pkg() {
    check_root
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done
    
    if [ ! "$SOURCES_FETCHED" = true ]; then
        apt-get update -q >/dev/null
        SOURCES_FETCHED=true
    fi
    
    if ! dpkg -s ${@:1} >/dev/null 2>&1; then
        LC_CTYPE=C.UTF-8 apt-get install -yq ${@:1} >/dev/null
    fi
}

function set_motd() {
    
    if [ ! -f /etc/update-motd.d/01-checkmk-motd ]; then
        check_root
        need_pkg update-motd toilet figlet lolcat wget
        chmod -x /etc/update-motd.d/*
        wget -P /etc/update-motd.d/ https://raw.githubusercontent.com/n00rm/motd/master/01-checkmk-motd 
        chmod +x /etc/update-motd.d/01-checkmk-motd
        update-motd >/dev/null
        say "MOTD Set"
    fi
    #todo: update motd
}

main() {
    export DEBIAN_FRONTEND=noninteractive

    set_motd
    
    say "done!"
}

main "$@" || exit 1