#!/bin/bash

function mkd() {
	mkdir -p "$@" && cd "$_" || exit 1;
}