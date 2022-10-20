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
fi

sleep 5

set -e

RL=$(dirname "$(realpath "$0")")

initRepos() {
	if [ ! -f $RL/.repo/manifest.xml ]; then
		echo "--> Initializing Repo"
		cd $RL
		repo init -u https://android.googlesource.com/platform/manifest -b android-13.0.0_r11 --depth=1
		echo
	fi
	if [ ! -f $RL/.repo/local_manifests/manifest.xml ]; then
		echo "--> Moving Local Manifest"
		mkdir -p $RL/.repo/local_manifests
		mv $RL/manifest.xml $RL/.repo/local_manifests
		echo
	fi
	#Placeholder as I sort my patches
	#if [ ! -f $RL/treble_patches ]; then
	#	echo "--> Fetching Patch List from Remote Location"
	#	rm -rf ./treble_patches
	#	git clone https://github.com/ChonDoit/treble_superior_patches.git -b 13 ./treble_patches
	#	echo
	#fi
	
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
	export OUT_DIR=$HOME/out
	echo
}

makeMake() {
	if [ ! -f $RL/device/phh/treble/treble_arm64_*.mk ]; then
		echo "--> Generating makefiles for Phh targets"
		cd $RL/device/phh/treble
		bash ./generate.sh
		cd $RL
		echo
	fi
}

buildVariant() {
	echo "--> Starting Build Process"
	if [[ $2 = 64[Bb][Ff][Nn] ]]; then
		target="treble_arm64_bfN"
	elif [[ $2 = 64[Bb][Ff][Ss ]]; then
		target="treble_arm64_bfS"
	elif [[ $2 = 64[Bb][Ff][Zz] ]]; then
		target="treble_arm64_bfZ"
	elif [[ $2 = 64[Bb][Gg][Nn] ]]; then
		target="treble_arm64_bgN"
	elif [[ $2 = 64[Bb][Gg][Ss] ]]; then
		target="treble_arm64_bgS"
	elif [[ $2 = 64[Bb][Gg][Zz] ]]; then
		target="treble_arm64_bgZ"
	elif [[ $2 = 64[Bb][Oo][Nn] ]]; then
		target="treble_arm64_boN"
	elif [[ $2 = 64[Bb][Oo][Ss] ]]; then
		target="treble_arm64_boS"
	elif [[ $2 = 64[Bb][Oo][Zz] ]]; then
		target="treble_arm64_boZ"
	elif [[ $2 = 64[Bb][Vv][Nn] ]]; then
		target="treble_arm64_bvN"
	elif [[ $2 = 64[Bb][Vv][Ss] ]]; then
		target="treble_arm64_bvS"
	elif [[ $2 = 64[Bb][Vv][Zz] ]]; then
		target="treble_arm64_bvZ"
	fi
	lunch $target-userdebug
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE installclean
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE -j$(nproc --all) systemimage
	mv $OUT/system.img $HOME/builds/system-$target.img
	echo
}

buildVndkliteVariant() {
	echo "--> Generating $target-vndklite"
	cd $RL/sas-creator
	sudo bash ./lite-adapter.sh 64 $HOME/builds/system-$target.img
	cp s.img $HOME/builds/system-$target-vndklite.img
	sudo rm -rf s.img d tmp
	cd $RL
	echo
}

generatePackages() {
	echo "--> Generating packages"
	xz -cv $HOME/builds/system-$target.img -T0 > $HOME/builds/system-$target.img.xz
	if [[ $3 = "vndklite" ]]; then
		xz -cv $HOME/builds/system-$target-vndklite.img -T0 > $HOME/builds/system-$target-vndklite.img.xz
	fi
	rm -rf $HOME/builds/system-*.img
	echo
}

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

if [[ $1 = "sync" && $2 = 64[Bb][FfGgOoVv][NnSsZz] ]]; then
	if [[ $3 = "vndklite" ]]; then
		if [[ $4 = "compress" ]]; then
			echo "--> Syncing, building $2, generating vndklite and compressing"
			sleep 2
			initRepos
			syncRepos
			applyPatches
			setupEnv
			makeMake
			buildVariant
			buildVndkliteVariant
			generatePackages
		else
			echo "--> Syncing, building $2 and generating vndklite"
			sleep 2
			initRepos
			syncRepos
			applyPatches
			setupEnv
			makeMake
			buildVariant
			buildVndkliteVariant
		fi
	elif [[ $3 = "compress" ]]; then
		echo "--> Syncing, building $2 and compressing"
		sleep 2
		initRepos
		syncRepos
		applyPatches
		setupEnv
		makeMake
		buildVariant
		generatePackages
	else
		echo "--> Syncing and building $2"
		sleep 2
		initRepos
		syncRepos
		applyPatches
		setupEnv
		makeMake
		buildVariant
	fi
elif [[ $1 = "dry" && $2 = 64[Bb][FfGgOoVv][NnSsZz] ]]; then
	if [[ $3 = "vndklite" ]]; then
		if [[ $4 = "compress" ]]; then
			echo "--> Building $2 dry, generating vndklite and compressing"
			sleep 2
			setupEnv
			makeMake
			buildVariant
			buildVndkliteVariant
			generatePackages
		else
			echo "--> Building $2 dry and generating vndklite"
			sleep 2
			setupEnv
			makeMake
			buildVariant
			buildVndkliteVariant
		fi
	elif [[ $3 = "compress" ]]; then
		echo "--> Building $2 dry and compressing"
		sleep 2
		setupEnv
		makeMake
		buildVariant
		generatePackages
	else
		echo "--> Building $2 dry"
		sleep 2
		setupEnv
		makeMake
		buildVariant
	fi
elif [[ $1 = "sync" && -z "$2$3$4" ]]; then
	echo "--> OnlySync™"
	sleep 2
	initRepos
	syncRepos
else
	echo "Invalid Args"
	echo "Correct Usage Is :"
	echo "bash ./build.sh [dry or sync] [ 64{B}{FGOV}{NSZ} ] [vndklite] [compress]"
fi

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Script completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo