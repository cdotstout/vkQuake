import os
import subprocess

subprocess.call("ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk APP_PLATFORM=android-23 APP_ABI=arm64-v8a TARGET_OUT=../../staticlibs/arm64-v8a", shell=True)