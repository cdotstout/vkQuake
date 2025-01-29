#!/bin/bash

# Copyright 2017 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

usage="Usage: $0 x64|arm64 <path-to-fuchsia-sdk> <path-to-fuchsia-toolchain> [IMAGEPIPE|IMAGEPIPE_FB|WAYLAND]"

cpu=$1
if [[ $cpu == *"arm64" ]]; then
	cpu=arm64
	system_processor=aarch64
elif [[ $cpu == *"x64" ]]; then
	cpu=x64
	system_processor=x86_64
else
	echo $usage
	exit 1
fi

if [[ $2 == "" ]] || [[ $3 == "" ]]; then
	echo $usage
	exit 1
fi

sdk_dir=$2
toolchain_dir=$3
display_protocol=$4
platform=fuchsia

if [[ $display_protocol == "IMAGEPIPE_FB" ]]; then
	PLATFORM_OPTIONS="-DUSE_IMAGEPIPE_FB=1"
elif [[ $display_protocol == "IMAGEPIPE" ]]; then
	PLATFORM_OPTIONS="-DUSE_IMAGEPIPE_FB=0"
elif [[ $display_protocol == "WAYLAND" ]]; then
  platform=linux
else
	echo $usage
	exit 1
fi

source_dir=$PWD/..
build_dir=$PWD/build-$platform-$cpu
sysroot=$sdk_dir/arch/$cpu/sysroot

export VK_SDK_PATH=$source_dir/third_party/Vulkan-Headers

make -f custom-deps.make TOOLCHAIN_DIR=${toolchain_dir} ../third_party/Vulkan-Headers
make -f custom-deps.make TOOLCHAIN_DIR=${toolchain_dir} ../third_party/SDL

if [[ $platform == "linux" ]]; then
        echo "Building deps for linux platform"
        make -f custom-deps.make TOOLCHAIN_DIR=${toolchain_dir} deps
fi

if [[ $platform == "fuchsia" ]]; then
	PLATFORM_OPTIONS="$PLATFORM_OPTIONS \
		-DFFMPEG=NO
		-DUSE_VULKAN=1
		-DBUILD_STATIC_LOADER=0
		-DSDL_SHARED=NO
		-DUSE_PRECOMPILED_HEADERS=0
		-DCMAKE_TOOLCHAIN_FILE=$source_dir/fuchsia/Fuchsia.cmake
		-DFUCHSIA_TOOLCHAIN=$toolchain_dir
		-DFUCHSIA_SYSTEM_PROCESSOR=$system_processor
		-DFUCHSIA_SYSROOT=$sysroot
		-DFUCHSIA_SDK_DIR=$sdk_dir"
elif [[ $platform == "linux" ]]; then
	PLATFORM_OPTIONS="$PLATFORM_OPTIONS
	  -DSDL_SHARED=NO
		-DFFMPEG=NO
		-DJACK=NO
		-DESD=NO
		-DGLSLANG_DIR=$source_dir/neo/libs/glslang
		-DUSE_VULKAN=1
		-DUSE_PRECOMPILED_HEADERS=0
		-DBUILD_STATIC_LOADER=1
		-DCMAKE_TOOLCHAIN_FILE=$source_dir/fuchsia/CustomToolchain.cmake
		-DTOOLCHAIN_DIR=${toolchain_dir}
		-DTOOLCHAIN_SYSROOT=${source_dir}/third_party/sysroot/linux
		-DCUSTOM_COMPILER_TARGET=$system_processor-linux-gnu
		-DPULSEAUDIO=0
		-DOPENAL=0
		-DSDL_SHARED=0
		-DVIDEO_X11=0
		-DVIDEO_MIR=0
		-DVIDEO_KMSDRM=0
		-DVIDEO_OPENGLES=0
		-DVIDEO_WAYLAND=1
		-DSDL_CROSS_COMPILE=1
		-DXKBCOMMON_INCLUDE_DIR=${source_dir}/third_party/xkbcommon
		-DXKBCOMMON_LIB=${source_dir}/third_party/xkbcommon/build/libxkbcommon.a
		-DWAYLAND_SHARED=0
		-DWAYLAND_FOUND=1
		-DWAYLAND_USE_XDG_SHELL=1
		-DWAYLAND_SCANNER=${source_dir}/third_party/wayland/build/out/bin/wayland-scanner
		-DWAYLAND_CORE_PROTOCOL_DIR=${source_dir}/third_party/wayland/protocol
		-DWAYLAND_PROTOCOLS_DIR=${source_dir}/third_party/wayland-protocols
		-DWAYLAND_INCLUDE_DIRS=${source_dir}/third_party/wayland/build/out/include
		-DWAYLAND_CLIENT_LIB=${source_dir}/third_party/wayland/build/out/lib/libwayland-client.a
		-DWAYLAND_CURSOR_LIB=${source_dir}/third_party/wayland/build/out/lib/libwayland-cursor.a
		-DWAYLAND_CLIENT_INCLUDE_DIR=${source_dir}/third_party/wayland/build/out/include
		-DLIBFFI_CLIENT_LIB=${source_dir}/third_party/libffi/build/out/lib/libffi.a"
fi

echo $PLATFORM_OPTIONS

unset EDITOR

mkdir -p $build_dir
pushd $build_dir

cmake --no-warn-unused-cli -GNinja -DCMAKE_BUILD_TYPE=Release $PLATFORM_OPTIONS $source_dir
ninja

if [[ $platform == "linux" ]]; then
	${toolchain_dir}/bin/llvm-readelf --needed-libs $build_dir/vkQuake
	echo Building Linux tarball
#	tar -C $source_dir -cf $build_dir/base.tar base/default.cfg base/strings base/renderprogs base/demos \#
#		base/_common.crc base/_common.resources \
#		base/_ordered.crc base/_ordered.resources \
#		base/maps/mars_city1.crc base/maps/mars_city1.resources \
#		base/maps/mars_city2.crc base/maps/mars_city2.resources

elif [[ $platform == "fuchsia" ]]; then
	echo Building Fuchsia package

	pkg=rbdoomthreebfg-$cpu
	pkg_dir=$pkg
	manifest=$build_dir/$pkg.manifest

	echo "bin/app=RBDoom3BFG" > $manifest
	echo "meta/doom3.cmx=../meta/doom3.cmx" >> $manifest
	echo "meta/package=$pkg_dir/meta/package" >> $manifest

	echo "lib/libasync-default.so=${sdk_dir}/arch/$cpu/lib/libasync-default.so" >> $manifest
	echo "lib/libfdio.so=${sdk_dir}/arch/$cpu/lib/libfdio.so" >> $manifest
	echo "lib/libtrace-engine.so=${sdk_dir}/arch/$cpu/lib/libtrace-engine.so" >> $manifest
	echo "lib/libsyslog.so=${sdk_dir}/arch/$cpu/lib/libsyslog.so" >> $manifest
	echo "lib/libvulkan.so=${sdk_dir}/arch/$cpu/lib/libvulkan.so" >> $manifest
	echo "lib/VkLayer_image_pipe_swapchain.so=${sdk_dir}/arch/$cpu/dist/VkLayer_image_pipe_swapchain.so" >> $manifest
	echo "data/vulkan/explicit_layer.d/VkLayer_image_pipe_swapchain.json=${sdk_dir}/pkg/vulkan_layers/data/vulkan/explicit_layer.d/VkLayer_image_pipe_swapchain.json" >> $manifest

	# This layer is for testing and is not provided by the SDK
	echo "lib/VkLayer_image_pipe_swapchain_fb.so=../prebuilt/$cpu/VkLayer_image_pipe_swapchain_fb.so" >> $manifest
	echo "data/vulkan/explicit_layer.d/VkLayer_image_pipe_swapchain_fb.json=../prebuilt/$cpu/VkLayer_image_pipe_swapchain_fb.json" >> $manifest
	echo "lib/VkLayer_image_pipe_swapchain_copy.so=../prebuilt/$cpu/VkLayer_image_pipe_swapchain_copy.so" >> $manifest
	echo "data/vulkan/explicit_layer.d/VkLayer_image_pipe_swapchain_copy.json=../prebuilt/$cpu/VkLayer_image_pipe_swapchain_copy.json" >> $manifest

	# Validation layers
	echo "lib/VkLayer_khronos_validation.so=${sdk_dir}/arch/$cpu/dist/VkLayer_khronos_validation.so" >> $manifest
	echo "data/vulkan/explicit_layer.d/VkLayer_khronos_validation.json=${sdk_dir}/pkg/vulkan_layers/data/vulkan/explicit_layer.d/VkLayer_khronos_validation.json" >> $manifest

	echo "lib/ld.so.1=$sdk_dir/arch/$cpu/sysroot/dist/lib/ld.so.1" >> $manifest
	echo "lib/libc++.so.2=$toolchain_dir/lib/$system_processor-unknown-fuchsia/c++/libc++.so.2" >> $manifest
	echo "lib/libc++abi.so.1=$toolchain_dir/lib/$system_processor-unknown-fuchsia/c++/libc++abi.so.1" >> $manifest
	echo "lib/libunwind.so.1=$toolchain_dir/lib/$system_processor-unknown-fuchsia/c++/libunwind.so.1" >> $manifest

	# Generate doom3.manifest
	python ../gen.py
	cat doom3.manifest >> $manifest

	rm -rf $pkg_dir
	mkdir $pkg_dir

	$sdk_dir/tools/pm -o $pkg_dir -version 0 init
	$sdk_dir/tools/pm -o $pkg_dir -m $manifest build
	$sdk_dir/tools/pm -o $pkg_dir -m $manifest archive

	popd

	echo "Publish package:"
	echo "$sdk_dir/tools/pm publish -a -r out/x64-release/amber-files -f $pkg-0.far"

fi
