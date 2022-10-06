# Building PHH-based GSIs #

![treble_stuff](https://raw.githubusercontent.com/utkustnr/dotfiles/main/meme.png)

To get started with building AOSP GSI, you'll need to get familiar with [Git and Repo](https://source.android.com/source/using-repo.html), and set up your environment by referring to [LineageOS Wiki](https://wiki.lineageos.org/devices/redfin/build) (mainly "Install the build packages") and [How to build a GSI](https://github.com/phhusson/treble_experimentations/wiki/How-to-build-a-GSI%3F).

---

- First, open a new Terminal window and clone this repo with the following command:

	```
	git clone https://github.com/utkustnr/treble_stuff -b 13
	```

- Then, start the build script:

	```
	bash ./treble_stuff/build.sh
	```

- This is a network, storage, cpu and ram intensive process that can go on for hours and occupy about 100 gb for repo and another 100-150 gb for build. At the time of writing download size for android 13 r8 repo is 30~ gb.

---

This script is made by someone who is pretty new to these stuff. 

If you want flexible, reliable and customizable build scripts feel free to edit my stuff or use the sources I used.

Big shoutout to 
- [phhusson](https://github.com/phhusson)
- [AndyYan](https://github.com/AndyCGYan)
- [Ponces](https://github.com/ponces)
- [iceows](https://github.com/Iceows)
- [harvey186](https://github.com/LeOS-GSI)
- [sooti](https://github.com/sooti)
- and everyone I yoinked code from.
