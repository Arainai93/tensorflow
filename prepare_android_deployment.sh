#!/bin/bash

if [ -z "$ANDROID_HOME" -o ! -d "$ANDROID_HOME" ]; then
	echo "Please set your \$ANDROID_HOME env var to point to the android SDK"
	exit 1
fi

NDK_HOME=$HOME/Downloads/android-ndk-r12b

if [ ! -d "$NDK_HOME" ]; then
	echo "Expecting ndk r12b to be downloaded at $NDK_HOME. Download it from https://developer.android.com/ndk/downloads/older_releases.html#ndk-12b-downloads or fix the script."
	exit 2
fi

SDK_SYMLINK=$(dirname $0)/android_sdk
NDK_SYMLINK=$(dirname $0)/android_ndk

if [ ! -L $SDK_SYMLINK ]; then
	ln -s $ANDROID_HOME $SDK_SYMLINK
fi

if [ ! -L $NDK_SYMLINK ]; then
	ln -s $NDK_HOME $NDK_SYMLINK
fi

DEPLOY_DIR=$(dirname $0)/deploy_android/tensorflow

for cpu in x86 x86_64 armeabi-v7a arm64-v8a
do
	bazel build -c opt //tensorflow/contrib/android:libtensorflow_inference.so --crosstool_top=//external:android/crosstool --host_crosstool_top=@bazel_tools//tools/cpp:toolchain --cpu=$cpu --cxxopt="-DSELECTIVE_REGISTRATION" --cxxopt="-Os"
	retval=$?
	if [ $retval -ne 0 ]; then
		exit $retval
	fi

	lib_dir=$DEPLOY_DIR/prebuiltLibs/$cpu
	mkdir -p $lib_dir
	chmod -R u+w $lib_dir # to make sure we can override existing files
	cp bazel-bin/tensorflow/contrib/android/libtensorflow_inference.so $lib_dir
done


bazel build //tensorflow/contrib/android:android_tensorflow_inference_java
retval=$?
if [ $retval -ne 0 ]; then
	exit $retval
fi
chmod -R u+w $DEPLOY_DIR # to make sure we can override previous jar
cp bazel-bin/tensorflow/contrib/android/libandroid_tensorflow_inference_java.jar $DEPLOY_DIR
