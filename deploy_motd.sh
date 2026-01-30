#!/bin/bash

# Author: Norman Kühnberger <info@n0rm.de>

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

function disable_motdnews() {
    check_root
    if [ -f /etc/default/motd-news ]; then
        sed -i 's/^ENABLED=1/ENABLED=0/' /etc/default/motd-news
        say "MOTD news disabled"
    else
    err "MOTD news config file not found!"
    fi
}

function download_motd() {
    check_root
    say "Downloading MOTD file..."
    wget -P /etc/update-motd.d/ https://raw.githubusercontent.com/n00rm/motd/master/01-server-motd
    if [ $? -ne 0 ]; then
        err "Failed to download MOTD file!"
    fi
}

function ask_title() {
    echo
    read -rp "Enter a title for your MOTD: " MOTD_TITLE
    if [ -z "$MOTD_TITLE" ]; then
        err "MOTD title cannot be empty."
    fi
    say "Using MOTD title: $MOTD_TITLE"
}

function ask_tagline() {
    echo
    read -rp "Do you want to add a custom tagline? (y/n): " ADD_TAGLINE
    case "$ADD_TAGLINE" in
        [Yy]* )
            read -rp "Enter your custom tagline: " MOTD_TAGLINE
            if [ -z "$MOTD_TAGLINE" ]; then
                err "Tagline cannot be empty when selected 'yes'."
            fi
            ;;
        [Nn]* )
            MOTD_TAGLINE="Server MOTD by n0rm"
            ;;
        * )
            err "Please answer yes or no."
            ;;
    esac
    say "Using MOTD tagline: $MOTD_TAGLINE"
}

function set_motd() {
    
    if [ ! -f /etc/update-motd.d/01-server-motd ]; then
        check_root
        ask_title
        ask_tagline
        need_pkg update-motd toilet figlet wget
        disable_motdnews
        chmod -x /etc/update-motd.d/*
        download_motd
        chmod +x /etc/update-motd.d/01-server-motd
        sed -i "s/{{TITLE}}/${MOTD_TITLE}/g" /etc/update-motd.d/01-server-motd
        sed -i "s/{{TAGLINE}}/${MOTD_TAGLINE}/g" /etc/update-motd.d/01-server-motd
        update-motd >/dev/null
        say "MOTD set"
    else
        err "MOTD already installed. Update function pending..."
    fi
}

main() {
    export DEBIAN_FRONTEND=noninteractive

    set_motd
    
    say "done!"
}

main "$@" || exit 1