# Building PHH-based GSIs #

To get started with building AOSP GSI, you'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html), and set up your environment by referring to [LineageOS Wiki](https://wiki.lineageos.org/devices/redfin/build) (mainly "Install the build packages") and [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

---

- First, open a new Terminal window and clone this repo with the following command:

	```
	git clone https://github.com/utkustnr/treble_stuff -b 13
	```

- Then, start the build script:

	```
	sudo bash ./treble_stuff/build.sh sync 64bvs vndklite pack
	```

Accepted arguments : ` [dry / sync] [64B{FGV}{NS}] [vndklite / secure / lsec / light / pack]`

---

- [dry / sync]
	- Sync will initialize aosp repo and sync.
	- Dry will skip sync part and start building right away. Needs you to sync at least once before.

- [64B{FGV}{NS}]
	- 64 means arm64 
		- B means system-as-root (A-only is deprecated since android 12)
			- F for floss 
			- G for gapps 
			- V for vanilla
				- N for without root 
				- S for with root

- [vndklite / secure / lsec / light / pack] All of these can be combined and written in any order.
	- Vndklite will create a system image with read and write permissions.
	- Secure will create a system image without root permissions.
	- Lsec will create secure variant FROM vndklite, which means image will be rw and without root.
	- Light will create a system image without any overlays (except huawei) and apex folders (except vndk 28). I'll expand the selection later on.
	- Pack will compress images for easier uploading.

Output directory will be in your home folder. Edit setupEnv() function to switch it's location.

This is a network, storage, cpu and ram intensive process that can go on for hours and occupy about 100 gb for repo and another 100-150 gb for build. At the time of writing download size for android 13 r8 repo is 30~ gb. After build is done, total storage usage is 230~ gb.

---

If you want flexible, reliable and customizable build scripts feel free to edit this script or use the sources I used.

Big shoutout to 
- [phhusson](https://github.com/phhusson)
- [AndyYan](https://github.com/AndyCGYan)
- [Ponces](https://github.com/ponces)
- [iceows](https://github.com/Iceows)
- [harvey186](https://github.com/LeOS-GSI)
- [sooti](https://github.com/sooti)
- and everyone I yoinked code from.

![treble_stuff](https://raw.githubusercontent.com/utkustnr/dotfiles/main/reference/meme.png)
