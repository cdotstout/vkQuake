ifeq ($(TOOLCHAIN_DIR),)
$(error Must set TOOLCHAIN_DIR)
endif

# Ensure subprocesses see this
export PKG_CONFIG_LIBDIR

THIRD_PARTY=../third_party
PREFIX=$(PWD)/$(THIRD_PARTY)/install
SDL=$(THIRD_PARTY)/SDL
EXPAT=$(THIRD_PARTY)/expat
LIBFFI=$(THIRD_PARTY)/libffi
SYSROOT=$(THIRD_PARTY)/sysroot/linux
VULKAN_HEADERS=$(THIRD_PARTY)/Vulkan-Headers
VULKAN_LOADER=$(THIRD_PARTY)/Vulkan-Loader
WAYLAND=$(THIRD_PARTY)/wayland
WAYLAND_PROTOCOLS=$(THIRD_PARTY)/wayland-protocols
XKBCOMMON=$(THIRD_PARTY)/xkbcommon
ALSA=$(THIRD_PARTY)/alsa

PARALLEL=-j8

# Building with sysroot should ensure we don't pick up host dependencies.
#
# CURDIR is a make builtin variable: "Set to the absolute pathname of the
# current working directory (after all -C options are processed, if any)."
#
# We want static libraries for all deps.  Those that support CMake
# (Vulkan-Loader) are included from the top level, others are prebuilt here.
#
CC="$(TOOLCHAIN_DIR)/bin/clang --sysroot=${CURDIR}/$(SYSROOT)"
CXX="$(TOOLCHAIN_DIR)/bin/clang++ --sysroot=${CURDIR}/$(SYSROOT)"

deps: $(SYSROOT) $(EXPAT) $(LIBFFI) $(WAYLAND) $(WAYLAND_PROTOCOLS) $(XKBCOMMON) $(VULKAN_HEADERS) $(VULKAN_LOADER) $(ALSA) $(SDL)

$(SYSROOT):
	mkdir -p $(SYSROOT)
	cd $(SYSROOT) && cipd init && cipd install fuchsia/third_party/sysroot/linux git_revision:47910c0625ad625def7d9e21c9213c91eb9cfa51

$(EXPAT): $(SYSROOT)
	mkdir -p $(THIRD_PARTY)
	git clone https://fuchsia.googlesource.com/third_party/expat $(EXPAT)
	cd $(EXPAT)/expat && ./buildconf.sh
	cd $(EXPAT)/expat && \
		./configure  --prefix=$(PREFIX) --enable-static CC=$(CC) CXX=$(CXX) && \
		make buildlib installlib

$(LIBFFI): $(SYSROOT)
	mkdir -p $(THIRD_PARTY)
	git clone https://fuchsia.googlesource.com/third_party/libffi $(LIBFFI)
	cd $(LIBFFI) && ./autogen.sh
	mkdir -p $(LIBFFI)/build
	cd $(LIBFFI)/build && \
		../configure  --prefix=$(PREFIX) --enable-static --disable-shared --disable-docs --with-pic CC=$(CC) CXX=$(CXX) && \
		make install

$(WAYLAND): $(SYSROOT) $(EXPAT) $(LIBFFI)
	mkdir -p $(THIRD_PARTY)
	git clone https://github.com/wayland-project/wayland $(WAYLAND)
	# Remove fuchsia generated file which causes a build problem
	#rm $(WAYLAND)/protocol/wayland.dtd.c
	mkdir -p $(WAYLAND)/build
	cd $(WAYLAND) && \
		CC=$(CC) CXX=$(CXX) meson setup build --prefix=$(PREFIX) --default-library=static -Ddtd_validation=false -Ddocumentation=false && \
		ninja -C build install

$(WAYLAND_PROTOCOLS):
	mkdir -p $(THIRD_PARTY)
	git clone https://github.com/wayland-project/wayland-protocols $(WAYLAND_PROTOCOLS)
	mkdir -p $(WAYLAND_PROTOCOLS)/build
	cd $(WAYLAND_PROTOCOLS) && \
		CC=$(CC) CXX=$(CXX) meson setup build --prefix=$(PREFIX) && \
		ninja -C build install

$(XKBCOMMON): $(SYSROOT)
	echo 'PKG_CONFIG_LIBDIR: $(PKG_CONFIG_LIBDIR)'
	pkg-config --modversion wayland-client
	mkdir -p $(THIRD_PARTY)
	git clone https://github.com/xkbcommon/libxkbcommon.git $(XKBCOMMON)
	cd $(XKBCOMMON) && \
		CC=$(CC) CXX=$(CXX) meson setup build --prefix=$(PREFIX) --default-library=static -Denable-x11=false -Denable-docs=false -Denable-xkbregistry=false -Dxkb-config-root=/usr/share/X11/xkb && \
		ninja -C build install

$(VULKAN_HEADERS):
	mkdir -p $(THIRD_PARTY)
	git clone https://fuchsia.googlesource.com/third_party/Vulkan-Headers $(VULKAN_HEADERS)

$(VULKAN_LOADER):
	mkdir -p $(THIRD_PARTY)
	git clone https://fuchsia.googlesource.com/third_party/Vulkan-Loader $(VULKAN_LOADER)

$(ALSA): $(SYSROOT)
	mkdir -p $(THIRD_PARTY)
	git clone https://github.com/alsa-project/alsa-lib $(ALSA)
	cd $(ALSA) && \
		libtoolize --force --copy --automake && \
		aclocal && \
		autoheader && \
		automake --foreign --copy --add-missing && \
		autoconf && \
		./configure --prefix=$(PREFIX) --enable-shared=yes --enable-static=no && \
		make $(PARALLEL) install

$(SDL):
	mkdir -p $(THIRD_PARTY)
	git clone https://github.com/libsdl-org/SDL $(SDL)
	cd $(SDL) && patch -p1 < $(CURDIR)/patches/SDL.patch

clean:
	rm -rf $(THIRD_PARTY)
