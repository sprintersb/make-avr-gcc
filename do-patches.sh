#!/bin/bash

what=$1     # What to do (apply, copy, ...)
patches=$2  # Folder with patches like patches-15/gcc
dir=$3      # Apply them here.

case $what in
    copy)
	mkdir -p $dir/share/patches
	for p in ${patches}-*.diff ${patches}-*.patch; do
	    if [ -f "$p" ]; then
		cp $p $dir/share/patches
	    fi
	done
	;;

    apply)
	for p in ${patches}-*.diff ${patches}-*.patch; do
	    if [ -f "$p" ]; then
		( cd $dir && patch -p1 < ../$p )
	    fi
	done
	;;
esac
