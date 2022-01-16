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

no_studio () {
    echo "Compiling the JDK requires Oracle Solaris Studio 12.4."
    echo "Other versions are not likely to work. GCC will not work."
    echo "You will need to install studio to complete this build."
    echo ""
}

tarball_studio () {
    no_studio
    echo "You have Solaris Studio 12.4 installed, but this script cannot"
    echo "detect an IPS install."
    echo ""
    echo "If you have installed from a tarball distribution from Oracle,"
    echo "there is a good chance that this build will fail in annoying and"
    echo "hard to diagnose ways, such as random libharfbuff errors."
    echo ""
    echo "If you have just copied Solaris Studio from an IPS installed host"
    echo "by hand and the installation is from the proper IPS repositories,"
    echo "you can ignore this warning."
    echo ""
}

chk_pkg_studio () {
    echo "Checking IPS pkg list, this may take a few seconds ..."
    echo ""
    pkg list | grep "developer/solarisstudio-124" >/dev/null 2>/dev/null || tarball_studio
}

intro

stat /opt/solarisstudio12.4/bin/cc >/dev/null 2>/dev/null || no_studio
stat /opt/solarisstudio12.4/bin/cc >/dev/null 2>/dev/null && chk_pkg_studio


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



