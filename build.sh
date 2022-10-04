#!/bin/bash

echo
echo "______________________________"
echo "    AOSP 13.0 BuildScript     "
echo "             by               "
echo "           frax3r             "
echo "    and totally none else     "
echo "______________________________"
echo

set -e

initRepos() {
	if [ ! -f ./.repo/manifest.xml ]; then
		echo "--> Initializing Repo"
		repo init -u https://android.googlesource.com/platform/manifest -b android-13.0.0_r4 --depth=1
		echo

		#I was dumb and used to do makefiles like this, leaving it just in case
		#echo "--> Fetching phh makefiles"
		#git clone https://github.com/phhusson/device_phh_treble -b android-12.0
		#mkdir -p device/phh/treble
		#mv ./device_phh_treble/* ./device/phh/treble/
		#rm -rf /device_phh_treble/
		#echo
	fi
}

syncRepos() {
	echo "--> Syncing repos"
	repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
	echo
}

applyPatches() {
	echo "--> Applying patches"
	# I don't know how this script works, I literally yoinked it from multiple people and merged different parts
	# messed with it for a while and made it work, somehow, don't touch it if it's not broken
	bash ./treble_patches/apply-patches.sh ./treble_patches/patches
	echo
}

setupEnv() {
	echo "--> Setting up build environment"
	source build/envsetup.sh &>/dev/null
	mkdir -p $HOME/builds
	echo
}

makeMake() {
	echo "--> Generating makefiles for Phh targets"
	cd ./device/phh/treble
	bash ./generate.sh
	cd $HOME/treble_stuff
	echo
}

buildVariant() {
	echo "--> Building treble_arm64_bvN"
	#note to self, ask for user input here
	lunch treble_arm64_bvN-userdebug
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE installclean
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE -j$(nproc --all) systemimage
	mv $OUT/system.img $HOME/builds/Android_arm64-ab-vanilla-13.0-$BUILD_DATE.img
	echo
}

generatePackages() {
	echo "--> Generating packages"
	#not necessary if you ask me
	xz -cv $HOME/builds/Android_arm64-ab-vanilla-13.0-$BUILD_DATE.img -T0 > $HOME/builds/Android_arm64-ab-13.0-$BUILD_DATE.img.xz
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
buildVariant
#generatePackages

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo

