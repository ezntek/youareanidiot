# you are an idiot!

Just kidding. this is just a reimplementation of the youareanidiot.org virus from back in the day in Odin and SDL2. be sure to troll your friends with it!!!

## tuning
you can swap out your image and sound for arbitrary ones in the compilation step, see below. The image must be a PNG file with size 200x200, though.

## compilation

Because distributing this executable with a suspicious image named `image.png` and a sound file named `sound.mp3` is too _suspicious_, I devised a genius way to hide the sound and image data straight in the source file. To compile, you must:

 * run `mkdir assets` (odin stuff)
 * run `./build_assets.py IMAGE image.png SOUND sound.mp3` (the image and sound can be at different paths), this creates `assets/assets.odin` which will contain byte arrays of the file's contents
 * run `odin build idiot.odin -file`, which creates an executable.

you may run this one-liner if you like copying and pasting: `mkdir assets;./build_assets.py IMAGE image.png SOUND sound.mp3;odin build idiot.odin -file`

The executable, when run, will open the files `youareanidiot_img.png` and `youareanidiot_snd.mp3` and write the contents of the embedded assets to them, which will then be loaded by SDL2. almost a self-extracting archive, except that the compression is done by the algorithm itself.
