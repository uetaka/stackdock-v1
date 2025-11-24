#!/bin/bash
export ANDROID_HOME=$(pwd)/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
echo "Android SDK environment variables set."
