ifeq ($(TOOLCHAIN_DIR),)
$(error Must set TOOLCHAIN_DIR)
endif

INSTALL_ROOT=../third_party
SDL=$(INSTALL_ROOT)/SDL
EXPAT=$(INSTALL_ROOT)/expat
LIBFFI=$(INSTALL_ROOT)/libffi
SYSROOT=$(INSTALL_ROOT)/sysroot/linux
VULKAN_HEADERS=$(INSTALL_ROOT)/Vulkan-Headers
VULKAN_LOADER=$(INSTALL_ROOT)/Vulkan-Loader
WAYLAND=$(INSTALL_ROOT)/wayland
WAYLAND_PROTOCOLS=$(INSTALL_ROOT)/wayland-protocols
XKBCOMMON=$(INSTALL_ROOT)/xkbcommon

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

deps: $(SYSROOT) $(EXPAT) $(LIBFFI) $(WAYLAND) $(WAYLAND_PROTOCOLS) $(XKBCOMMON) $(VULKAN_HEADERS) $(VULKAN_LOADER) $(SDL)

$(SYSROOT):
	mkdir -p $(SYSROOT)
	cd $(SYSROOT) && cipd init && cipd install fuchsia/third_party/sysroot/linux git_revision:47910c0625ad625def7d9e21c9213c91eb9cfa51

$(EXPAT): $(SYSROOT)
	mkdir -p $(INSTALL_ROOT)
	git clone https://fuchsia.googlesource.com/third_party/expat $(EXPAT)
	cd $(EXPAT)/expat && ./buildconf.sh
	cd $(EXPAT)/expat && \
		./configure  --prefix=`pwd`/out --enable-static CC=$(CC) CXX=$(CXX) && \
		make buildlib installlib

$(LIBFFI): $(SYSROOT)
	mkdir -p $(INSTALL_ROOT)
	git clone https://fuchsia.googlesource.com/third_party/libffi $(LIBFFI)
	cd $(LIBFFI) && ./autogen.sh
	mkdir -p $(LIBFFI)/build
	cd $(LIBFFI)/build && \
		../configure  --prefix=`pwd`/out --enable-static --disable-shared --disable-docs --with-pic CC=$(CC) CXX=$(CXX) && \
		make install

$(WAYLAND): $(SYSROOT) $(EXPAT) $(LIBFFI)
	mkdir -p $(INSTALL_ROOT)
	git clone https://fuchsia.googlesource.com/third_party/wayland $(WAYLAND)
	mkdir -p $(WAYLAND)/build
	cd $(WAYLAND)/build && \
		../autogen.sh  --prefix=`pwd`/out --enable-static --with-host-scanner --disable-documentation --disable-dtd-validation \
			CC=$(CC) CXX=$(CXX) \
			EXPAT_CFLAGS=-I${CURDIR}/$(EXPAT)/expat/out/include EXPAT_LIBS=${CURDIR}/$(EXPAT)/expat/out/lib/libexpat.a \
			FFI_CFLAGS=-I${CURDIR}/$(LIBFFI)/build/out/include FFI_LIBS=${CURDIR}/$(LIBFFI)/build/out/lib/libffi.a && \
		make install

$(WAYLAND_PROTOCOLS):
	mkdir -p $(INSTALL_ROOT)
	git clone https://github.com/wayland-project/wayland-protocols $(WAYLAND_PROTOCOLS)

$(XKBCOMMON): $(SYSROOT)
	mkdir -p $(INSTALL_ROOT)
	git clone https://github.com/xkbcommon/libxkbcommon.git $(XKBCOMMON)
	cd $(XKBCOMMON) && meson setup build --default-library static -Denable-x11=false -Denable-docs=false && ninja -C build

$(VULKAN_HEADERS):
	mkdir -p $(INSTALL_ROOT)
	git clone https://fuchsia.googlesource.com/third_party/Vulkan-Headers $(VULKAN_HEADERS)

$(VULKAN_LOADER):
	mkdir -p $(INSTALL_ROOT)
	git clone https://fuchsia.googlesource.com/third_party/Vulkan-Loader $(VULKAN_LOADER)
	cd $(VULKAN_LOADER) && git apply ${CURDIR}/Vulkan-Loader.patch

$(SDL):
	mkdir -p $(INSTALL_ROOT)
	git clone sso://tqgfx-internal/SDL $(SDL)

clean:
	rm -rf $(INSTALL_ROOT)
