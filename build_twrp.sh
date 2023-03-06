#!/bin/bash

echo
echo "------------------------------"
echo "         A73                  "
echo "           TWRP               "
echo "             Build            "
echo "                Script        "
echo "------------------------------"
echo

syncRepos() {
	echo
	echo "--> Initializing Repos"
	echo
	cd $TWRP_DIR
	repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
	repo sync -c --force-sync --no-clone-bundle --optimized-fetch --no-tags -j$(nproc --all)
	git clone --depth=1 https://github.com/utkustnr/android_kernel_samsung_a73xq.git -b twrp-12.1 kernel/samsung/a73xq
	git clone --depth=1 https://github.com/utkustnr/android_device_samsung_a73xq.git -b twrp-12.1 device/samsung/a73xq
}

buildKernel() {
	echo
	echo "--> Building Kernel for TWRP"
	echo
	cd $KERNEL_DIR
	export ARCH=arm64
	export LLVM=1
	export CLANG_PREBUILT_BIN=$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin
	export PATH=$CLANG_PREBUILT_BIN:$PATH
	BUILD_CROSS_COMPILE=$TWRP_DIR/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
	KERNEL_LLVM_BIN=$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin/clang
	CLANG_TRIPLE=aarch64-linux-gnu-
	KERNEL_MAKE_ENV="CONFIG_BUILD_ARM64_DT_OVERLAY=y"
	
	mkdir out
	make -j$(nproc --all) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CONFIG_SECTION_MISMATCH_WARN_ONLY=y vendor/a73xq_twrp_defconfig
	make -j$(nproc --all) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CONFIG_SECTION_MISMATCH_WARN_ONLY=y
	cd $KERNEL_DIR/..
	mv a73xq placeholder
	KERNEL_DIR=$TWRP_DIR/kernel/samsung/placeholder
}

buildTwrp() {
	echo
	echo "--> Building TWRP"
	echo
	cd $TWRP_DIR
	cp $KERNEL_DIR/out/arch/arm64/boot/Image $TWRP_DIR/device/samsung/a73xq/prebuilt/kernel.gz
	cp $KERNEL_DIR/out/arch/arm64/boot/dtbo.img $TWRP_DIR/device/samsung/a73xq/prebuilt/dtbo.img
	cp $KERNEL_DIR/out/arch/arm64/boot/dts/vendor/qcom/yupik.dtb $TWRP_DIR/device/samsung/a73xq/prebuilt/dtb.img
	$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin/llvm-strip --strip-unneeded $KERNEL_DIR/out/drivers/input/sec_input/sec_cmd.ko -o $TWRP_DIR/device/samsung/a73xq/recovery/root/vendor/lib/modules/1.1/sec_cmd.ko
	$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin/llvm-strip --strip-unneeded $KERNEL_DIR/out/drivers/input/sec_input/sec_common_fn.ko -o $TWRP_DIR/device/samsung/a73xq/recovery/root/vendor/lib/modules/1.1/sec_common_fn.ko
	$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin/llvm-strip --strip-unneeded $KERNEL_DIR/out/drivers/input/sec_input/sec_secure_touch.ko -o $TWRP_DIR/device/samsung/a73xq/recovery/root/vendor/lib/modules/1.1/sec_secure_touch.ko
	$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin/llvm-strip --strip-unneeded $KERNEL_DIR/out/drivers/input/sec_input/sec_tclm_v2.ko -o $TWRP_DIR/device/samsung/a73xq/recovery/root/vendor/lib/modules/1.1/sec_tclm_v2.ko
	$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin/llvm-strip --strip-unneeded $KERNEL_DIR/out/drivers/input/sec_input/sec_tsp_dumpkey.ko -o $TWRP_DIR/device/samsung/a73xq/recovery/root/vendor/lib/modules/1.1/sec_tsp_dumpkey.ko
	$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin/llvm-strip --strip-unneeded $KERNEL_DIR/out/drivers/input/sec_input/sec_tsp_log.ko -o $TWRP_DIR/device/samsung/a73xq/recovery/root/vendor/lib/modules/1.1/sec_tsp_log.ko
	$TWRP_DIR/prebuilts/clang/host/linux-x86/clang-r383902/bin/llvm-strip --strip-unneeded $KERNEL_DIR/out/drivers/input/sec_input/stm/stm_ts.ko -o $TWRP_DIR/device/samsung/a73xq/recovery/root/vendor/lib/modules/1.1/stm_ts.ko
	export ALLOW_MISSING_DEPENDENCIES=true
	. build/envsetup.sh
	lunch twrp_a73xq-eng
	mka recoveryimage
}

endBuild() {
	echo
	echo "--> Packaging twrp and vbmeta"
	echo
	cd $KERNEL_DIR/..
	mv placeholder a73xq 
	KERNEL_DIR=$TWRP_DIR/kernel/samsung/a73xq
	cd $TWRP_DIR/out/target/product/a73xq
	tar -cvf twrp.tar recovery.img
	mv twrp.tar $TWRP_DIR/../
	cd $TWRP_DIR/..

	curl https://raw.githubusercontent.com/WessellUrdata/vbmeta-disable-verification/4c63f728aac1d0ff99fa6313114c21f1f4dc3f3c/patch-vbmeta.py > patch-vbmeta.py
	curl https://gist.githubusercontent.com/utkustnr/026441c5cf307be073f0ae8f4b9121ef/raw/9cc30f41521bc1145b8e217f9985e7c290d0bf94/vbmeta.img.txt | base64 -d > vbmeta.img

	if [[ $(sha256sum vbmeta.img) == "fc6d077c99cee9897d1f37b647976e8bbcd834b77c72c6f52855c73771c18c0c  vbmeta.img" ]]; then python3 ./patch-vbmeta.py vbmeta.img; fi
	if [[ $(sha256sum vbmeta.img) == "3346f64e8f7e75bbcc84e0b412d11283c16b0aa9535f9b9cda9229b247782972  vbmeta.img" ]]; then tar -cvf patched-vbmeta.tar vbmeta.img; fi
	rm patch-vbmeta.py vbmeta.img
}

START=`date +%s`
BUILD_DATE="$(date +%d%m%Y)"

mkdir twrp
TWRP_DIR=$(pwd)/twrp
KERNEL_DIR=$TWRP_DIR/kernel/samsung/a73xq
sleep 5
syncRepos
sleep 5
buildKernel
sleep 5
buildTwrp
sleep 5
endBuild

cd $TWRP_DIR/kernel/samsung/a73xq
git clean -fdx
cd $TWRP_DIR/device/samsung/a73xq
git clean -fdx
cd $TWRP_DIR
make clean

END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo
echo "--> Jobs completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
