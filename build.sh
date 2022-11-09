#!/bin/bash

ram=$(free -g | grep Mem: | awk '{print $2}')
swap=$(free -g | grep Swap: | awk '{print $2}')

echo
echo "------------------------------"
echo "   Generic AOSP Build Script  "
echo "                              "
echo "        If You're Stuck       "
echo "     Keep Calm And Ctrl+C     "
echo "------------------------------"
echo

if (( $ram+$swap < 16 )); then
	echo "WARNING"
	echo "Your system memory is not enough to build."
	echo "You can try increasing swap or lowering threads used."
	echo "WARNING"
	echo 
fi

sleep 5

set -e

RL=$(dirname "$(realpath "$0")")

initRepos() {
	if [ ! -f $RL/.repo/manifest.xml ]; then
		echo
		echo "--> Initializing Repo"
		echo
		cd $RL
		repo init -u https://android.googlesource.com/platform/manifest -b android-13.0.0_r14 --depth=1
		echo
	fi
	if [ ! -f $RL/.repo/local_manifests/manifest.xml ]; then
		echo
		echo "--> Moving Local Manifest"
		echo
		mkdir -p $RL/.repo/local_manifests
		mv $RL/manifest.xml $RL/.repo/local_manifests
		echo
	fi
	#Placeholder for 
	#if [ ! -f $RL/treble_patches ]; then
	#	echo "--> Fetching Patch List from Remote Location"
	#	rm -rf $RL/treble_patches
	#	git clone https://github.com/ChonDoit/treble_superior_patches.git -b 13 $RL/treble_patches
	#	echo
	#fi
}

syncRepos() {
	echo
	echo "--> Syncing repos"
	echo
	sleep 1
	cd $RL
	repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
	echo
}

applyPatches() {
	echo
	echo "--> Applying patches"
	echo
	sleep 1
	cd $RL
	bash $RL/treble_patches/apply-patches.sh $RL/treble_patches/patches
	echo
}

setupEnv() {
	echo
	echo "--> Setting up build environment"
	echo
	sleep 1
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
	sleep 1
	cd $RL/device/phh/treble
	bash ./generate.sh
	cd $RL
	echo
}

buildVariant() {
	echo
	echo "--> Starting build process"
	echo
	sleep 1
	if [[ $2 = 64[Bb][Ff][Nn] ]]; then
		lunch treble_arm64_bfN-userdebug
		target_name="arm64_bfN"
	elif [[ $2 = 64[Bb][Ff][Ss ]]; then
		lunch treble_arm64_bfS-userdebug
		target_name="arm64_bfS"
	elif [[ $2 = 64[Bb][Gg][Nn] ]]; then
		lunch treble_arm64_bgN-userdebug
		target_name="arm64_bgN"
	elif [[ $2 = 64[Bb][Gg][Ss] ]]; then
		lunch treble_arm64_bgS-userdebug
		target_name="arm64_bgS"
	elif [[ $2 = 64[Bb][Vv][Nn] ]]; then
		lunch treble_arm64_bvN-userdebug
		target_name="arm64_bvN"
	elif [[ $2 = 64[Bb][Vv][Ss] ]]; then
		lunch treble_arm64_bvS-userdebug
		target_name="arm64_bvS"
	fi
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE installclean
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE -j$(nproc --all) systemimage
	mv $OUT/target/product/*/system.img $HOME/builds/TrebleDroid-13-${target_name}.img
	echo
}

buildVndkliteVariant() {
	echo
	echo "--> Generating $target-vndklite"
	echo
	sleep 1
	cd $RL/sas-creator
	sudo bash ./lite-adapter.sh 64 $HOME/builds/TrebleDroid-13-${target_name}.img
	mv s.img $HOME/builds/TrebleDroid-13-${target_name}-vndklite.img
	sudo rm -rf d tmp
	cd $RL
	echo
}

buildSecureVariant() {
	echo
	echo "--> Generating $target-secure"
	echo
	sleep 1
	cd $RL/sas-creator
	sudo bash ./securize.sh $HOME/builds/TrebleDroid-13-${target_name}.img
	mv s-secure.img $HOME/builds/TrebleDroid-13-${target_name}-secure.img
	sudo rm -rf d tmp
	cd $RL
	echo
}

buildSecureVndkliteVariant() {
	echo
	echo "--> Generating $target-vndklite-secure"
	echo
	sleep 1
	cd $RL/sas-creator
	sudo bash ./lite-adapter.sh 64 $HOME/builds/TrebleDroid-13-${target_name}.img
	mv s.img $HOME/builds/TrebleDroid-13-${target_name}-vndklite.img
	sudo rm -rf d tmp
	sudo bash ./securize.sh $HOME/builds/TrebleDroid-13-${target_name}-vndklite.img
	mv s-secure.img $HOME/builds/TrebleDroid-13-${target_name}-vndklite-secure.img
	sudo rm -rf d tmp
	cd $RL
	echo
}

generatePackages() {
	echo
	echo "--> Generating packages"
	echo
	sleep 1
	xz -cv $HOME/builds/TrebleDroid-13-${target_name}.img -T0 > $HOME/builds/TrebleDroid-13-${target_name}.img.xz
	if [ -f $HOME/builds/TrebleDroid-13-${target_name}-vndklite.img ]; then
		xz -cv $HOME/builds/TrebleDroid-13-${target_name}-vndklite.img -T0 > $HOME/builds/TrebleDroid-13-${target_name}-vndklite.img.xz
	fi
	if [ -f $HOME/builds/TrebleDroid-13-${target_name}-secure.img ]; then
		xz -cv $HOME/builds/TrebleDroid-13-${target_name}-secure.img -T0 > $HOME/builds/TrebleDroid-13-${target_name}-secure.img.xz
	fi
	if [ -f $HOME/builds/TrebleDroid-13-${target_name}-vndklite-secure.img ]; then
		xz -cv $HOME/builds/TrebleDroid-13-${target_name}-vndklite-secure.img -T0 > $HOME/builds/TrebleDroid-13-${target_name}-vndklite-secure.img.xz
	fi
	rm -rf $HOME/builds/TrebleDroid-13*.img
	echo
}

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

if [[ $1 = "sync" && $2 = 64[Bb][FfGgVv][NnSs] ]]; then
	initRepos
	syncRepos
	applyPatches
	setupEnv
	makeMake
	buildVariant
	if [[ "vndklite" == +(["$3$4$5$6"]) ]]; then buildVndkliteVariant; fi
	if [[ "secure" == +(["$3$4$5$6"]) ]]; then buildSecureVariant; fi
	if [[ "litesec" == +(["$3$4$5$6"]) ]]; then buildSecureVndkliteVariant; fi
	if [[ "pack" == +(["$3$4$5$6"]) ]]; then generatePackages; fi

elif [[ $1 = "dry" && $2 = 64[Bb][FfGgVv][NnSs] ]]; then
	applyPatches
	setupEnv
	makeMake
	buildVariant
	if [[ "vndklite" == +(["$3$4$5$6"]) ]]; then buildVndkliteVariant; fi
	if [[ "secure" == +(["$3$4$5$6"]) ]]; then buildSecureVariant; fi
	if [[ "litesec" == +(["$3$4$5$6"]) ]]; then buildSecureVndkliteVariant; fi
	if [[ "pack" == +(["$3$4$5$6"]) ]]; then generatePackages; fi

elif [[ $1 = "sync" && -z "$2$3$4$5" ]]; then
	echo
	echo "--> OnlySync™"
	echo
	sleep 2
	initRepos
	syncRepos
else
	echo
	echo "#############"
	echo "Invalid Args"
	echo "Correct Usage Is :"
	echo "bash ./build.sh [dry / sync] [64B{FGV}{NS}] [vndklite / secure / litesec / pack]"
	echo
fi

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo
echo "--> Jobs completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
