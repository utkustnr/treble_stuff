#!/bin/bash

RAM=$(free -g | grep Mem: | awk '{print $2}')
SWAP=$(free -g | grep Swap: | awk '{print $2}')

echo
echo "------------------------------"
echo "     Generic                  "
echo "          AOSP                "
echo "             Build            "
echo "                 Script       "
echo "------------------------------"
echo

if (( $RAM+$SWAP < 16 )); then
	echo 
	echo "WARNING"
	echo "Your system memory is not enough to build."
	echo "You can try increasing swap or lowering threads used."
	echo "WARNING"
	echo
	read -p 'Do you want to continue regardless? [Y/N]' RAMCHECK
	if [[ $RAMCHECK = [Yy] ]]; then
		echo
		echo "You've been warned..."
		echo
		sleep 1
	else
		echo
		echo "Exiting script..."
		echo
		sleep 1
		exit 1
	fi
fi

set -e

RL=$(dirname "$(realpath "$0")")


initRepos() {
	if [ ! -f $RL/.repo/manifest.xml ]; then
		echo
		echo "--> Initializing Repo"
		echo
		cd $RL
		echo
		echo "Choose manifest"
		echo "Options : AOSP | LOS"
		echo
		read -p '--> ' MANIFESTVAR
		echo
		echo "Choose android version"
		echo "Options : 11 | 13"
		echo
		read -p '--> ' ANDROIDVAR
		echo
		if [[ $MANIFESTVAR = [Aa][Oo][Ss][Pp] ]]; then
			sed -i '40i ANDROID_BASE=AOSP' $RL/build.sh
			ANDROID_BASE=AOSP
			if [[ $ANDROIDVAR = "13" ]]; then
				sed -i '41i ANDROID_VER=13' $RL/build.sh
				ANDROID_VER=13
				repo init -u https://android.googlesource.com/platform/manifest -b android-13.0.0_r24 --depth=1
			elif [[ $ANDROIDVAR = "11" ]]; then
				sed -i '41i ANDROID_VER=11' $RL/build.sh
				ANDROID_VER=11
				repo init -u https://android.googlesource.com/platform/manifest -b android-11.0.0_r48 --depth=1
			else
				echo "Invalid"
				exit 1
			fi
		elif [[ $MANIFESTVAR = [Ll][Oo][Ss] ]]; then
			sed -i '40i ANDROID_BASE=LineageOS' $RL/build.sh
			ANDROID_BASE=LineageOS
			if [[ $ANDROIDVAR = "13" ]]; then
				sed -i '41i ANDROID_VER=20' $RL/build.sh
				ANDROID_VER=20
				repo init -u https://github.com/LineageOS/android.git -b lineage-20 --depth=1
			elif [[ $ANDROIDVAR = "11" ]]; then
				sed -i '41i ANDROID_VER=18.1' $RL/build.sh
				ANDROID_VER=18.1
				repo init -u https://github.com/LineageOS/android.git -b lineage-18.1 --depth=1
			else
				echo "Invalid"
				exit 1
			fi
		else
			echo "Invalid"
			exit 1
		fi
	fi

	if [ ! -f $RL/.repo/local_manifests/manifest.xml ]; then
		echo
		echo "--> Creating Local Manifest"
		echo
		mkdir -p $RL/.repo/local_manifests
		if [[ $ANDROID_BASE = "AOSP" ]]; then
			if [[ $ANDROID_VER = "13" ]]; then
				cp $RL/manifest.xml $RL/.repo/local_manifests
			elif [[ $ANDROID_VER = "11" ]]; then
				cp $RL/manifest.xml $RL/.repo/local_manifests
				sed -i 's|TrebleDroid/device_phh_treble|phhusson/device_phh_treble|g' $RL/.repo/local_manifests/manifest.xml
				sed -i 's|path="device/phh/treble" remote="treble" revision="android-13.0"|path="device/phh/treble" remote="treble" revision="android-11.0"|g' $RL/.repo/local_manifests/manifest.xml
				sed -i 's|TrebleDroid/vendor_hardware_overlay|phhusson/vendor_hardware_overlay|g' $RL/.repo/local_manifests/manifest.xml
			fi
		
		elif [[ $ANDROID_BASE = "LineageOS" ]]; then
			if [[ $ANDROID_VER = "20" ]]; then
				wget https://raw.githubusercontent.com/AndyCGYan/lineage_build_unified/lineage-20-td/local_manifests_treble/manifest.xml -P $RL/.repo/local_manifests
				sed -i '10i \  <project name="utkustnr/sas-creator" path="sas-creator" remote="github" revision="master" />' $RL/.repo/local_manifests/manifest.xml
			elif [[ $ANDROID_VER = "18.1" ]]; then
				wget https://raw.githubusercontent.com/AndyCGYan/lineage_build_unified/lineage-18.1/local_manifests_treble/manifest.xml -P $RL/.repo/local_manifests
				sed -i '8i \  <project name="utkustnr/sas-creator" path="sas-creator" remote="github" revision="master" />' $RL/.repo/local_manifests/manifest.xml
			fi
		fi
	fi

	if [ ! -d $RL/treble_patches/patches ]; then
		echo
		echo "--> Fetching Patch List from Remote Location"
		echo
		if [[ $ANDROID_BASE = "AOSP" ]]; then
			if [[ $ANDROID_VER = "13" ]]; then
				wget https://github.com/TrebleDroid/treble_experimentations/releases/latest/download/patches-for-developers.zip -P $RL/treble_patches
				unzip $RL/treble_patches/patches-for-developers.zip -d treble_patches
			elif [[ $ANDROID_VER = "11" ]]; then
				wget https://github.com/phhusson/treble_experimentations/releases/download/v313/patches.zip -P $RL/treble_patches
				unzip $RL/treble_patches/patches.zip -d treble_patches
			fi
		
		elif [[ $ANDROID_BASE = "LineageOS" ]]; then
			if [[ $ANDROID_VER = "20" ]]; then
				git clone https://github.com/AndyCGYan/lineage_patches_unified.git -b lineage-20-td $RL/treble_patches/patches
			elif [[ $ANDROID_VER = "18.1" ]]; then
				git clone https://github.com/AndyCGYan/lineage_patches_unified.git -b lineage-18.1 $RL/treble_patches/patches
			fi
		fi
	fi
}

syncRepos() {
	echo
	echo "--> Syncing repos"
	echo
	sleep 1
	cd $RL
	repo sync -c --force-sync --no-clone-bundle --optimized-fetch --no-tags -j$(nproc --all)
	echo
}

applyPatches() {
	echo
	echo "--> Applying patches"
	echo
	sleep 1
	cd $RL
	if [[ $ANDROID_BASE = "LineageOS" ]] && [[ $ANDROID_VER = "20" ]]; then
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_treble_prerequisite"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_treble_td"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_treble"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_treble_personal"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_platform"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_platform_personal"
		echo "Andy's patches break my script..."
		echo "Apply manually with commands on top from another terminal at treble_stuff folder"
		read -p '--> Press enter when done...'
		cd $RL
	elif [[ $ANDROID_BASE = "LineageOS" ]] && [[ $ANDROID_VER = "18.1" ]]; then
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_treble_prerequisite"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_treble_phh"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_treble"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_treble_personal"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_platform"
		echo "bash ./treble_patches/apply-patches.sh ./treble_patches/patches/patches_platform_personal"
		echo "Andy's patches break my script..."
		echo "Apply manually with commands on top from another terminal at treble_stuff folder"
		read -p '--> Press enter when done...'
		cd $RL
	else
		bash $RL/treble_patches/apply-patches.sh $RL/treble_patches/patches
	fi
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
		TARGET_NAME="arm64-bfN"
	elif [[ $2 = 64[Bb][Ff][Ss] ]]; then
		lunch treble_arm64_bfS-userdebug
		TARGET_NAME="arm64-bfS"
	elif [[ $2 = 64[Bb][Gg][Nn] ]]; then
		lunch treble_arm64_bgN-userdebug
		TARGET_NAME="arm64-bgN"
	elif [[ $2 = 64[Bb][Gg][Ss] ]]; then
		lunch treble_arm64_bgS-userdebug
		TARGET_NAME="arm64-bgS"
	elif [[ $2 = 64[Bb][Vv][Nn] ]]; then
		lunch treble_arm64_bvN-userdebug
		TARGET_NAME="arm64-bvN"
	elif [[ $2 = 64[Bb][Vv][Ss] ]]; then
		lunch treble_arm64_bvS-userdebug
		TARGET_NAME="arm64-bvS"
	fi
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE installclean
	make RELAX_USES_LIBRARY_CHECK=true BUILD_NUMBER=$BUILD_DATE -j$(nproc --all) systemimage
	mv $(find $OUT_DIR/target/product -name "system.img") "$HOME/builds/$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE.img"
	BASE_NAME="$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE"
	BASE_IMAGE="$HOME/builds/$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE.img"
	echo
	echo "$BASE_IMAGE done"
	echo
}

fakeBuild() {
	echo
	echo "--> For debug purposes"
	echo
	sleep 1
	TARGET_NAME="arm64-bvN"
	echo "this is the part where I move built image to $OUT_DIR/target/product and rename it to system.img"
	read -p "Waiting for <ENTER>..."
	mv $(find $OUT_DIR/target/product -name "system.img") "$HOME/builds/$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE.img"
	BASE_NAME="$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE"
	BASE_IMAGE="$HOME/builds/$ANDROID_BASE-$ANDROID_VER-$TARGET_NAME-$BUILD_DATE.img"
	echo
	echo "$BASE_IMAGE done"
	echo
}

buildVndkliteVariant() {
	echo
	echo "--> Generating $BASE_NAME-vndklite"
	echo
	sleep 1
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

buildSecureVariant() {
	echo
	echo "--> Generating $BASE_NAME-secure"
	echo
	sleep 1
	cd $RL/sas-creator
	sudo bash ./securize.sh "$BASE_IMAGE"
	mv s-secure.img "$HOME/builds/$BASE_NAME-secure.img"
	sudo rm -rf d tmp
	cd $RL
	SEC_IMAGE="$HOME/builds/$BASE_NAME-secure.img"
	echo
	echo "$SEC_IMAGE done"
	echo
}

buildSecureVndkliteVariant() {
	echo
	echo "--> Generating $BASE_NAME-vndklite-secure"
	echo
	sleep 1
	cd $RL/sas-creator
	if [ ! -f $VNDK_IMAGE ]; then
		buildVndkliteVariant
	fi
	sleep 1
	sudo bash ./securize.sh "$VNDK_IMAGE"
	mv s-secure.img "$HOME/builds/$BASE_NAME-vndklite-secure.img"
	sudo rm -rf d tmp
	cd $RL
	LSEC_IMAGE="$HOME/builds/$BASE_NAME-vndklite-secure.img"
	echo
	echo "$LSEC_IMAGE done"
	echo
}

buildLightVariant() {
	echo
	echo "--> Generating $BASE_NAME-light"
	echo
	sleep 1
	echo
	echo "Choose and write your brand exactly as it's shown below as lowercase"
	echo "asus | blackview | bq | duoqin | essential | fairphone | htc | huawei | infinix | lenovo | lg"
	echo "lge | mbi | meizu | moto | nokia | nubia | oneplus | oppo | oukitel | razer | realme"
	echo "samsung | sharp | sony | teclast | tecno | teracube | umidigi | unihertz | vivo | vsmart | xiaomi"
	echo
	read -p '--> ' BRANDVAR
	echo
	echo "Choose your stock vendor version (eg. write 28 if it's stock is android 9)"
	echo "28 (Android 9) | 29 (Android 10) | 30 (Android 11) | 31 (Android 12) | 32 (Android 12.1) | 33 (Android 13)"
	echo
	read -p '--> ' VENDORVAR
	echo
	if [ -f $LSEC_IMAGE ]; then
		echo
		echo "--> Using vndklite-secure image"
		echo
		if [[ BRANDVAR = @(asus|blackview|bq|duoqin|essential|fairphone|htc|huawei|infinix|lenovo|lg|lge|mbi|meizu|moto|nokia|nubia|oneplus|oppo|oukitel|razer|realme|samsung|sharp|sony|teclast|tecno|teracube|umidigi|unihertz|vivo|vsmart|xiaomi) ]]; then
			cd $RL/sas-creator
			sudo bash ./featherize.sh "$LSEC_IMAGE" $BRANDVAR $VENDORVAR
		else
			echo "Invalid brand, skipping light image."
		fi
	elif [ ! -f $LSEC_IMAGE ] && [ -f $VNDK_IMAGE ]; then
		echo
		echo "--> vndklite-secure image wasn't found, using vndklite image"
		echo
		if [[ $BRANDVAR = @(asus|blackview|bq|duoqin|essential|fairphone|htc|huawei|infinix|lenovo|lg|lge|mbi|meizu|moto|nokia|nubia|oneplus|oppo|oukitel|razer|realme|samsung|sharp|sony|teclast|tecno|teracube|umidigi|unihertz|vivo|vsmart|xiaomi) ]]; then
			cd $RL/sas-creator
			sudo bash ./featherize.sh "$VNDK_IMAGE" $BRANDVAR $VENDORVAR
		else
			echo "Invalid brand, skipping light image."
		fi
	elif [ ! -f $LSEC_IMAGE ] && [ ! -f $VNDK_IMAGE ]; then
		echo
		echo "--> vndklite and vndklite-secure image wasn't found, using base image"
		echo
		if [[ $BRANDVAR = @(asus|blackview|bq|duoqin|essential|fairphone|htc|huawei|infinix|lenovo|lg|lge|mbi|meizu|moto|nokia|nubia|oneplus|oppo|oukitel|razer|realme|samsung|sharp|sony|teclast|tecno|teracube|umidigi|unihertz|vivo|vsmart|xiaomi) ]]; then
			cd $RL/sas-creator
			sudo bash ./featherize.sh "$BASE_IMAGE" $BRANDVAR $VENDORVAR
		else
			echo "Invalid brand, skipping light image."
		fi
	fi
	mv f.img "$HOME/builds/$BASE_NAME-$BRANDVAR-$VENDORVAR.img"
	sudo rm -rf d tmp
	cd $RL
	LITE_IMAGE="$HOME/builds/$BASE_NAME-$BRANDVAR-$VENDORVAR.img"
	echo
	echo "$LITE_IMAGE done"
	echo
}

generatePackages() {
	echo
	echo "--> Compressing Images"
	echo
	sleep 1
	xz -cv "$BASE_IMAGE" -T0 > "$BASE_IMAGE.xz"
	if [ -f "$VNDK_IMAGE" ]; then
		xz -cv "$VNDK_IMAGE" -T0 > "$VNDK_IMAGE.xz"
	fi
	if [ -f "$SEC_IMAGE" ]; then
		xz -cv "$SEC_IMAGE" -T0 > "$SEC_IMAGE.xz"
	fi
	if [ -f "$LSEC_IMAGE" ]; then
		xz -cv "$LSEC_IMAGE" -T0 > "$LSEC_IMAGE.xz"
	fi
	if [ -f "$LITE_IMAGE" ]; then
		xz -cv "$LITE_IMAGE" -T0 > "$LITE_IMAGE.xz"
	fi
	for f in 'find $HOME/builds -name "*.img"'; do rm $f; done
	echo
}

START=`date +%s`
BUILD_DATE="$(date +%d%m%Y)"
if [ $# -eq 0 ]; then
	echo
	echo "#############"
	echo "No arguments supplied"
	echo "Correct Usage Is :"
	echo "bash ./build.sh [dry / sync] [64B{FGV}{NS}] [vndklite / secure / lsec / light / pack]"
	echo "#############"
	echo
	exit 1

elif [ $1 = "sync" ] && [[ $2 = 64[Bb][FfGgVv][NnSs] ]]; then
	initRepos
	syncRepos
	applyPatches
	setupEnv
	makeMake
	buildVariant
	if [[ "vndklite" == +(["$3$4$5$6$7"]) ]]; then buildVndkliteVariant; fi
	if [[ "secure" == +(["$3$4$5$6$7"]) ]]; then buildSecureVariant; fi
	if [[ "lsec" == +(["$3$4$5$6$7"]) ]]; then buildSecureVndkliteVariant; fi
	if [[ "light" == +(["$3$4$5$6$7"]) ]]; then buildLightVariant; fi
	if [[ "pack" == +(["$3$4$5$6$7"]) ]]; then generatePackages; fi

elif [ $1 = "dry" ] && [[ $2 = 64[Bb][FfGgVv][NnSs] ]]; then
	applyPatches
	setupEnv
	makeMake
	buildVariant
	if [[ "vndklite" == +(["$3$4$5$6$7"]) ]]; then buildVndkliteVariant; fi
	if [[ "secure" == +(["$3$4$5$6$7"]) ]]; then buildSecureVariant; fi
	if [[ "lsec" == +(["$3$4$5$6$7"]) ]]; then buildSecureVndkliteVariant; fi
	if [[ "light" == +(["$3$4$5$6$7"]) ]]; then buildLightVariant; fi
	if [[ "pack" == +(["$3$4$5$6$7"]) ]]; then generatePackages; fi
	
elif [[ $2 = "debug" ]]; then
	initRepos
	#syncRepos
	applyPatches
	setupEnv
	makeMake
	fakeBuild
	if [[ "vndklite" == +(["$3$4$5$6$7"]) ]]; then buildVndkliteVariant; fi
	if [[ "secure" == +(["$3$4$5$6$7"]) ]]; then buildSecureVariant; fi
	if [[ "lsec" == +(["$3$4$5$6$7"]) ]]; then buildSecureVndkliteVariant; fi
	if [[ "light" == +(["$3$4$5$6$7"]) ]]; then buildLightVariant; fi
	if [[ "pack" == +(["$3$4$5$6$7"]) ]]; then generatePackages; fi

elif [ $1 = "sync" ] && [ -z "$2$3$4$5" ]; then
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
	echo "bash ./build.sh [dry / sync] [64B{FGV}{NS}] [vndklite / secure / lsec / light / pack]"
	echo "#############"
	echo
	exit 1
fi

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo
echo "--> Jobs completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
