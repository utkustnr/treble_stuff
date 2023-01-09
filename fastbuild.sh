#!/bin/bash

echo
echo "------------------------------"
echo "     Generic                  "
echo "          AOSP                "
echo "             Build            "
echo "                 Script       "
echo "------------------------------"
echo


set -e

RL=$(dirname "$(realpath "$0")")
ANDROID_BASE=AOSP
ANDROID_VER=13

initRepos() {
	if [ ! -f $RL/.repo/manifest.xml ]; then
		echo
		echo "--> Initializing Repo"
		echo
		repo init -u https://android.googlesource.com/platform/manifest -b android-13.0.0_r24 --depth=1
	fi
	if [ ! -f $RL/.repo/local_manifests/manifest.xml ]; then
		echo
		echo "--> Moving Local Manifest"
		echo
		mkdir -p $RL/.repo/local_manifests
		mv $RL/manifest.xml $RL/.repo/local_manifests
		echo
	fi
	if [ ! -d $RL/treble_patches/patches ]; then
		echo
		echo "--> Fetching Patch List from Remote Location"
		echo
		wget https://github.com/TrebleDroid/treble_experimentations/releases/latest/download/patches-for-developers.zip -P $RL/treble_patches
		unzip $RL/treble_patches/patches-for-developers.zip -d treble_patches
	fi
}

syncRepos() {
	echo
	echo "--> Syncing repos"
	echo
	sleep
	cd $RL
	repo sync -c --force-sync --no-clone-bundle --optimized-fetch --no-tags -j$(nproc --all)
	echo
}

applyPatches() {
	echo
	echo "--> Applying patches"
	echo
	bash $RL/treble_patches/apply-patches.sh $RL/treble_patches/patches
	echo
}

setupEnv() {
	echo
	echo "--> Setting up build environment"
	echo
	source build/envsetup.sh &>/dev/null
	mkdir -p $HOME/builds
	mkdir -p $HOME/out
	export OUT_DIR=$HOME/out
	echo
}

makeMake() {
	echo
	echo "--> Generating makefiles for Phh targets"
	echo
	cd $RL/device/phh/treble
	bash ./generate.sh
	cd $RL
	echo
}

buildVariant() {
	echo
	echo "--> Starting build process"
	echo
	lunch treble_arm64_bvS-userdebug
	TARGET_NAME="arm64-bvS"
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE installclean
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE -j$(nproc --all) systemimage
	mv $(find $OUT_DIR/target/product -name "system.img") "$HOME/builds/$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE.img"
	BASE_NAME="$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE"
	BASE_IMAGE="$HOME/builds/$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE.img"
}

buildVndkliteVariant() {
	echo
	echo "--> Generating $BASE_NAME-vndklite"
	echo
	cd $RL/sas-creator
	sudo bash ./lite-adapter.sh 64 "$BASE_IMAGE"
	mv s.img "$HOME/builds/$BASE_NAME-vndklite.img"
	sudo rm -rf d tmp
	cd $RL
	VNDK_IMAGE="$HOME/builds/$BASE_NAME-vndklite.img"
	echo
	echo "$VNDK_IMAGE done"
	echo
}

generatePackages() {
	echo
	echo "--> Compressing Images"
	echo
	xz -cv "$BASE_IMAGE" -T0 > "$BASE_IMAGE.xz"
	if [ -f "$VNDK_IMAGE" ]; then
		xz -cv "$VNDK_IMAGE" -T0 > "$VNDK_IMAGE.xz"
	fi
	for f in 'find $HOME/builds -name "*.img"'; do rm $f; done
	echo
}

START=`date +%s`
BUILD_DATE="$(date +%d%m%Y)"

initRepos
syncRepos
applyPatches
setupEnv
makeMake
buildVariant
if [ $2 = "vndklite" ]; then buildVndkliteVariant; fi
generatePackages

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo
echo "--> Jobs completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
