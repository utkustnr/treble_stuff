#!/bin/bash

echo
echo "------------------------------"
echo "     Android Build Script     "
echo "                              "
echo "        If You're Stuck       "
echo "     Keep Calm And Ctrl+C     "
echo "------------------------------"
echo

set -e

RL=$(dirname "$(realpath "$0")")

initRepos() {
	if [ ! -f $RL/.repo/manifest.xml ]; then
		echo "--> Initializing Repo"
		cd $RL
		repo init -u https://android.googlesource.com/platform/manifest -b android-13.0.0_r8 --depth=1
		echo

		echo "--> Moving Local Manifest"
		mkdir -p $RL/.repo/local_manifests
		mv $RL/manifest.xml $RL/.repo/local_manifests
		echo
	fi
}

syncRepos() {
	echo "--> Syncing repos"
	cd $RL
	repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
	echo
}

applyPatches() {
	echo "--> Applying patches"
	bash $RL/treble_patches/apply-patches.sh $RL/treble_patches/patches
	echo
}

setupEnv() {
	echo "--> Setting up build environment"
	source build/envsetup.sh &>/dev/null
	mkdir -p $HOME/builds
	mkdir -p $HOME/out
	#export OUT_DIR=$HOME/out
	echo
}

makeMake() {
	echo "--> Generating makefiles for Phh targets"
	cd $RL/device/phh/treble
	bash ./generate.sh
	cd $RL
	echo
}

buildTrebleApp() {
	echo "--> Building treble_app"
	cd $RL/treble_app
	bash ./build.sh release
	cp ./TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
	cd $RL
	echo
}

buildVariant() {
	echo "--> Building treble_arm64_bvN"
	lunch treble_arm64_bvN-userdebug
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE installclean
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE -j$(nproc --all) systemimage
	mv $OUT/system.img $HOME/builds/system-treble_arm64_bvN.img
	echo
}

buildVndkliteVariant() {
	echo "--> Building treble_arm64_bvN-vndklite"
	cd $RL/sas-creator
	sudo bash ./lite-adapter.sh 64 $HOME/builds/system-treble_arm64_bvN.img
	cp s.img $HOME/builds/system-treble_arm64_bvN-vndklite.img
	sudo rm -rf s.img d tmp
	cd $RL
	echo
}

generatePackages() {
	echo "--> Generating packages"
	xz -cv $HOME/builds/system-treble_arm64_bvN.img -T0 > $HOME/builds/system-treble_arm64_bvN.img.xz
	rm -rf $HOME/builds/system-*.img
	echo
}

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

initRepos
syncRepos
applyPatches
setupEnv
makeMake
buildTrebleApp
buildVariant
#buildVndkliteVariant
#generatePackages

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo