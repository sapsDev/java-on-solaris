#!/bin/bash

# This is a quick pre-req script to avoid pulling in a mountain
# of mercurial repos and then having the process die because critical
# tools are missing. --Andre@PCOW January 2022.

# pkg install libxext libxcb libxtst libxrender libxt
# pkg install jdk-8
# pkg install autoconf
# pkg install mercurial
# pkg install cups
# pkg install mmheap

intro () {
    echo "Conducting some basic dep checks to ensure the tools you need"
    echo "are present."
    echo ""
}

failwich () {
    echo "Hold up!"
    echo "You're missing a critical part of the build toolchain."
    echo "Without this, your build will not work."
    echo ""
    echo "MISSING PART:" $1
    echo ""
    echo "Script terminating, please fix this and run again until you"
    echo "get a clean result."
    echo ""
    echo "Look in the source of this script for some ideas!"
    exit 1
}

intro

for i in "/bin/autoconf" "/usr/jdk/instances/jdk1.8.0/bin/java" \
    "/usr/bin/hg" \
    "/usr/include/X11/extensions/shape.h" \
    "/usr/include/X11/extensions/XTest.h" \
    "/usr/include/X11/extensions/Xrender.h" \
    "/usr/include/X11/Intrinsic.h" \
    "/usr/include/cups/ppd.h" \
    "/usr/lib/libfreetype.so" \
    "/bin/gmake" \
    "/usr/lib/libmmheap.so.1" \
    ; do stat $i >/dev/null 2>/dev/null || failwich $i ; done



