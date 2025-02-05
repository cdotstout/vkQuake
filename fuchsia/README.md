# vkQuake

Install this repo in `${FUCHSIA_DIR}/local/`.

To build, make sure you're in this directory and run:

```
./build.sh arm64 ../third_party/apisample/sdk/ ../third_party/apisample/clang/ IMAGEPIPE
```

To add the package to the fuchsia tree run:

```
fx add-test //local/vkQuake/fuchsia/gn:vkquake_pkg
```

To run the component do the following:

```
fx build; ffx session add fuchsia-pkg://fuchsia.com/vkquake#meta/vkquake.cm
```
