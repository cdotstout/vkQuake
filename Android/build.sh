#!/bin/bash

set -e

if [ ! -d "$ANDROID_SDK" ]; then
    echo Must set ANDROID_SDK
    exit 1
fi

TOOLS="$ANDROID_SDK"/build-tools/35.0.0
APK=vkquake.apk
KEY=debug.keystore

rm -f $APK

echo Building...

# Build SDL2 static library
ndk-build -j50 NDK_PROJECT_PATH=../third_party/SDL APP_BUILD_SCRIPT=../third_party/SDL/Android.mk APP_PLATFORM=android-23 APP_ABI=arm64-v8a TARGET_OUT=staticlibs/arm64-v8a SDL2_static
ndk-build -j50 NDK_PROJECT_PATH=../third_party/SDL APP_BUILD_SCRIPT=../third_party/SDL/Android.mk APP_PLATFORM=android-23 APP_ABI=armeabi-v7a TARGET_OUT=staticlibs/armeabi-v7a SDL2_static

# Build the Quake shared library
ndk-build -j50 NDK_LIBS_OUT=out/lib -C jni

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
$TOOLS/aapt package -f -M AndroidManifest.xml -F vkquake-unaligned.apk -I $ANDROID_SDK/platforms/android-34/android.jar jni/out assets
$TOOLS/zipalign -f 4 vkquake-unaligned.apk $APK
$TOOLS/apksigner sign --verbose --ks $KEY --ks-pass pass:android $APK

rm vkquake-unaligned.apk
ls -l *.apk
