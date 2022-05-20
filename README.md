# how to build image: #

```bash
$:~ git clone https://github.com/mohousch/buildsystem.git

cd buildsystem
```

**for first use:**
```bash
$:~ sudo ./prepare-for-bs.sh
```
**machine configuration:**
```bash
$:~ make init
or
$:~ make
```
**build image:**
```bash
$:~ make flashimage
```

**for more details:**
```bash
$:~ make help
```

**supported boards:**
```bash
$:~ make print-boards
```

* tested with:
 debian 8 Jessie, 9 Stretch and 11 Bullseye
 linuxmint 20.1 Ulyssa, 20.2 Uma, 20.3 Una and LMDE 5 Elsie
 Ubuntu 20.04 Focal Fossa and 22.04 Jammy Jellyfish
 
 
