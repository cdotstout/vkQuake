#!/bin/bash

if [ ! -d "$ANDROID_SDK" ]; then
    echo Must set ANDROID_SDK
    exit 1
fi

TOOLS="$ANDROID_SDK"/build-tools/30.0.3
APK=vkquake.apk
KEY=debug.keystore

rm -f $APK

echo Building...

# Build SDL2 static library
cd jni/SDL2 && python buildstatic.py && cd -

# Build the Quake shared library
ndk-build NDK_LIBS_OUT=out/lib -C jni

if [ ! -f "$KEY" ]; then
    echo Create signing key
    keytool -genkey -v -keystore $KEY \
        -alias androiddebugkey \
        -storepass android \
        -keypass android \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname CN=Android-Debug,O=Android,C=US
fi

echo Packaging...

# Create APK
$TOOLS/aapt package -f -M AndroidManifest.xml -F vkquake-unaligned.apk -I $ANDROID_SDK/platforms/android-23/android.jar jni/out assets
$TOOLS/zipalign -f 4 vkquake-unaligned.apk $APK
$TOOLS/apksigner sign --verbose --ks $KEY --ks-pass pass:android $APK

rm vkquake-unaligned.apk
ls -l *.apk
