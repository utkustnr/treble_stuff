#!/bin/bash

echo
echo "--------------------------"
echo "    AOSP 13.0 Buildbot    "
echo "           by             "
echo "         frax3r           "
echo "--------------------------"
echo

set -e

initRepos() {
	if [ ! -d .repo ]; then
		echo "--> Initializing Repo"
		repo init -u https://android.googlesource.com/platform/manifest -b android-13.0.0_r4 --depth=1
		echo

		echo "--> Moving local manifest"
		#mv ./local_manifests ./.repo
		echo

		echo "--> Fetching patches"
		#git clone https://github.com/utkustnr/treble_patches
		echo
		
		echo "--> Fetching phh makefiles"
		#git clone https://github.com/phhusson/device_phh_treble -b android-12.0
		#mkdir -p device/phh/treble
		#mv ./device_phh_treble/* ./device/phh/treble/
		echo
	fi
}

syncRepos() {
	echo "--> Syncing repos"
	repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
	echo
}

applyPatches() {
	echo "--> Applying patches"
	bash ./treble_patches/apply-patches.sh ./treble_patches/patches
	echo
}

setupEnv() {
	echo "--> Setting up build environment"
	source build/envsetup.sh &>/dev/null
	mkdir -p $HOME/builds
	cd ./device/phh/treble
	bash ./generate.sh
	cd $HOME/treble_stuff
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

generatePackages() {
	echo "--> Generating packages"
	#xz -cv $HOME/builds/system-treble_arm64_bvN.img -T0 > $HOME/builds/Android_arm64-ab-13.0-$BUILD_DATE.img.xz
	#rm -rf $HOME/builds/system-*.img
	echo
}

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

initRepos
syncRepos
applyPatches
setupEnv
buildVariant
generatePackages

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo

