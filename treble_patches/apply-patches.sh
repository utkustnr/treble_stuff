#!/bin/bash

set -e
patches="$(readlink -f -- $1)"
shopt -s nullglob
for project in $(cd $patches; echo *);do
	p="$(tr _ / <<<$project |sed -e 's;platform/;;g')"
	[ "$p" == build ] && p=build/make
	[ "$p" == vendor/hardware/overlay ] && p=vendor/hardware_overlay
	[ "$p" == vendor/partner/gms ] && p=vendor/partner_gms
	[ "$p" == external/harfbuzz/ng ] && p=external/harfbuzz_ng
	echo	
	pushd $p
	git clean -fdx; git reset --hard
	for patch in $patches/$project/*.patch;do
		#Check if patch is already applied
		if patch -f -p1 --dry-run -R < $patch > /dev/null;then
			continue
		fi
		if git apply --check $patch;then
			git am $patch
		elif patch -f -p1 --dry-run < $patch > /dev/null;then
			#This will fail
			git am $patch || true
			patch -f -p1 < $patch
			git add -u
			git am --continue
		else
			echo "Failed applying $patch"
		fi
	done
	popd
done

