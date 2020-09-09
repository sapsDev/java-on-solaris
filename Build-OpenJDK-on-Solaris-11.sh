set -xe


# Oracle Developer Studio 12.4 and JDK 8 are needed.
STUDIO124="/opt/solarisstudio12.4/bin"
# STUDIO126="/opt/developerstudio12.6/bin"
JDK="/usr/jdk/instances/jdk1.8.0/bin/"


# OpenJDK 12 and newer have some issues:
# - https://bugs.openjdk.java.net/browse/JDK-8211081
# - shenandoahgc doesn't build on Solaris i386 (and is not supported on sparc)

CONFIG_OPTS_JDK12="--with-jvm-features=-shenandoahgc --disable-warnings-as-errors"
CONFIG_OPTS_JDK13="--with-jvm-features=-shenandoahgc --disable-warnings-as-errors --enable-unlimited-crypto --with-native-debug-symbols=none --enable-dtrace=no"
CONFIG_OPTS_JDK14="--with-jvm-features=-shenandoahgc --disable-warnings-as-errors --enable-deprecated-ports=yes --enable-unlimited-crypto --with-native-debug-symbols=none --enable-dtrace=no"


# EM_486 is no longer defined since Solaris 11.4
function fixsrc1 {
  FILE=os_solaris.cpp
  for f in hotspot/src/os/solaris/vm/$FILE src/hotspot/os/solaris/$FILE; do
    [ ! -f "$f" ] || gsed -i 's/EM_486/EM_IAMCU/' "$f"
  done
}


# caddr32_t is already defined in Solaris 11
function fixsrc2 {
  FILE=src/java.base/solaris/native/libnio/ch/DevPollArrayWrapper.c
  for f in "$FILE" "jdk/$FILE"; do
    [ ! -f "$f" ] || gsed -i '/typedef.*caddr32_t;/d' "$f"
  done
}


# xc99=%none is too strict for new libs (e.g. CUPS 2.x) on Solaris 11.4
function fixsrc3 {
  FILE=make/autoconf/generated-configure.sh
  for f in "$FILE" "jdk/$FILE"; do
    [ ! -f "$f" ] || gsed -i 's/-xc99=%none//g' "$f"
  done
  FILE=common/autoconf/flags.m4
  for f in "$FILE" "jdk/$FILE"; do
    [ ! -f "$f" ] || gsed -i 's/-xc99=%none//g' "$f"
  done
} 


# 
function fixsrc4 {
  patch -p1 <<EOF

--- a/src/java.desktop/share/native/libfontmanager/harfbuzz/hb-subset-cff-common.hh     Fri Mar 01 16:59:19 2019 -0800
+++ b/src/java.desktop/share/native/libfontmanager/harfbuzz/hb-subset-cff-common.hh     Mon Apr 29 16:26:41 2019 +0200
@@ -280,6 +280,10 @@
 {
   str_buff_t     &flatStr;
   bool  drop_hints;
+
+  // Solaris: OS12u4 complains about "A class with a reference member lacks a user-defined constructor"
+  // so provide the constructor
+  flatten_param_t(str_buff_t& sbt, bool dh) : flatStr(sbt), drop_hints(dh) {}
 };

 template <typename ACC, typename ENV, typename OPSET>
@@ -305,7 +309,9 @@
         return false;
       cs_interpreter_t<ENV, OPSET, flatten_param_t> interp;
       interp.env.init (str, acc, fd);
-      flatten_param_t  param = { flat_charstrings[i], drop_hints };
+      // Solaris: OS12u4 does not like the C++11 style init
+      // flatten_param_t  param = { flat_charstrings[i], drop_hints };
+      flatten_param_t  param(flat_charstrings[i], drop_hints);
       if (unlikely (!interp.interpret (param)))
         return false;
     } 
EOF

  gsed -i 's/refmemnoconstr_aggr//' make/lib/Awt2dLibraries.gmk
}



for VERSION in {9..14}; do

  # [[ ${VERSION} -le 15 ]] && STUDIO="${STUDIO126}" 
  # [[ ${VERSION} -le 12 ]] && STUDIO="${STUDIO124}" 

  STUDIO="${STUDIO124}"

  hg clone http://hg.openjdk.java.net/jdk-updates/jdk${VERSION}u openjdk${VERSION}
  cd openjdk${VERSION}/

  # OpenJDK 9 uses script to download nested repositories
  test -f get_source.sh && bash get_source.sh

  # There are needed some source changes to build OpenJDK on Solaris 11.4.
  fixsrc1 ; fixsrc2 ; fixsrc3 

  [[ ${VERSION} -ge 13 ]] && fixsrc4

  [[ ${VERSION} -ge 12 ]] && CONFIGURE_OPTIONS="${CONFIG_OPTS_JDK12}"
  [[ ${VERSION} -ge 13 ]] && CONFIGURE_OPTIONS="${CONFIG_OPTS_JDK13}"
  [[ ${VERSION} -ge 14 ]] && CONFIGURE_OPTIONS="${CONFIG_OPTS_JDK14}"

  # Oracle Solaris Studio 12.4 may fail while building hotspot-gtest (_stdio_file.h issue)

  echo "Let's start building: ${STUDIO} and ${CONFIGURE_OPTIONS}"
  PATH="$JDK:${STUDIO}:/usr/bin/" bash ./configure --disable-hotspot-gtest ${CONFIGURE_OPTIONS}

  gmake bundles 2>&1 | tee build.log

  RELEASE_DIR=`grep "^Finished building target" build.log | cut -d \' -f 4`

  JDK="`pwd`/build/${RELEASE_DIR}/images/jdk/bin/"

  cd ..

done
