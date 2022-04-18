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
