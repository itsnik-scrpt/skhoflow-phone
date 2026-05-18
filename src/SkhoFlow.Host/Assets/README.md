# Assets

- `logo.svg` — square brand mark (256x256). Source for the in-app brand chip and installer banner.
- `wordmark.svg` — horizontal wordmark "SkhoFlow" (520x96).

## Generating `skhoflow.ico`

The csproj references `Assets/skhoflow.ico` for the executable icon and the
installer. Generate it from `logo.svg` with **either** ImageMagick or `inkscape + png2ico`:

```powershell
# Using ImageMagick (https://imagemagick.org)
magick -background none Assets\logo.svg `
       -define icon:auto-resize=256,128,96,64,48,32,16 `
       Assets\skhoflow.ico
```

Until that file exists, the build will warn but still run; Windows will
fall back to the default icon.
