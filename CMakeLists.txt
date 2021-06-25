cmake_minimum_required (VERSION 3.13)
project (vkQuake)

set(CMAKE_CXX_STANDARD 14)

# For Fuchsia
#include(${FUCHSIA_SDK_DIR}/sdk.cmake)

if(NOT DEFINED SDL_SHARED)
        set(SDL_SHARED YES)
endif()

if(NOT SDL_SHARED)
        message(STATUS "SDL_SHARED is OFF")
        set(SDL_VULKAN_HEADER ${CMAKE_SOURCE_DIR}/third_party/Vulkan-Headers/include/vulkan/vulkan.h)
        add_subdirectory(third_party/SDL)
        add_definitions(
                -Wno-inline-new-delete
                -Wno-deprecated-declarations
                -Wno-expansion-to-defined
                -Wno-deprecated-register
                -Wno-shift-negative-value
                -Wno-implicit-function-declaration
        )
endif()

if (BUILD_STATIC_LOADER)
        #set(BUILD_STATIC_LOADER ON)
        set(BUILD_WSI_XCB_SUPPORT OFF)
        set(BUILD_WSI_XLIB_SUPPORT OFF)
        set(BUILD_WSI_WAYLAND_SUPPORT ON)
        set(BUILD_WSI_DIRECTFB_SUPPORT OFF)
        add_subdirectory(third_party/Vulkan-Headers)
        add_subdirectory(third_party/Vulkan-Loader)
endif()

get_target_property(SDL2_INCLUDE_DIR SDL2-static INTERFACE_INCLUDE_DIRECTORIES)
#set(SDL2_INCLUDE_DIR ${SDL2_INCLUDE_DIR}/SDL2)
message(STATUS "SDL2_INCLUDE_DIR: ${SDL2_INCLUDE_DIR}")

set(VK_SDK_PATH $ENV{VK_SDK_PATH})
message(STATUS "VK_SDK_PATH: ${VK_SDK_PATH}")

#set(VULKAN_LIB $ENV{VULKAN_LIB})
#message(STATUS "VULKAN_LIB: ${VULKAN_LIB}")

include_directories(${SDL2_INCLUDE_DIR} ${VK_SDK_PATH}/include)

set(SHADER_DIR "Shaders/Compiled")
set(QUAKE_DIR "Quake")

set(SHADER_FILES
	${SHADER_DIR}/alias_frag.c
	${SHADER_DIR}/alias_alphatest_frag.c
	${SHADER_DIR}/alias_vert.c
	${SHADER_DIR}/basic_alphatest_frag.c
	${SHADER_DIR}/cs_tex_warp_comp.c
	${SHADER_DIR}/screen_warp_comp.c
	${SHADER_DIR}/screen_warp_rgba8_comp.c
	${SHADER_DIR}/basic_frag.c
	${SHADER_DIR}/basic_notex_frag.c
	${SHADER_DIR}/basic_vert.c
	${SHADER_DIR}/showtris_frag.c
	${SHADER_DIR}/showtris_vert.c
	${SHADER_DIR}/sky_box_frag.c
	${SHADER_DIR}/sky_layer_frag.c
	${SHADER_DIR}/sky_layer_vert.c
	${SHADER_DIR}/postprocess_frag.c
	${SHADER_DIR}/postprocess_vert.c
	${SHADER_DIR}/world_frag.c
	${SHADER_DIR}/world_vert.c
)

set(SOURCE_FILES
	${SHADER_FILES}
	${QUAKE_DIR}/gl_refrag.c
	${QUAKE_DIR}/gl_rlight.c
	${QUAKE_DIR}/gl_rmain.c
	${QUAKE_DIR}/gl_fog.c
	${QUAKE_DIR}/gl_rmisc.c
	${QUAKE_DIR}/r_part.c
	${QUAKE_DIR}/r_world.c
	${QUAKE_DIR}/gl_screen.c
	${QUAKE_DIR}/gl_sky.c
	${QUAKE_DIR}/gl_warp.c
	${QUAKE_DIR}/gl_vidsdl.c
	${QUAKE_DIR}/gl_draw.c
	${QUAKE_DIR}/image.c
	${QUAKE_DIR}/mdfour.c
	${QUAKE_DIR}/gl_texmgr.c
	${QUAKE_DIR}/gl_mesh.c
	${QUAKE_DIR}/gl_heap.c
	${QUAKE_DIR}/r_sprite.c
	${QUAKE_DIR}/r_alias.c
	${QUAKE_DIR}/r_brush.c
	${QUAKE_DIR}/gl_model.c
	${QUAKE_DIR}/strlcat.c 
	${QUAKE_DIR}/strlcpy.c 
	${QUAKE_DIR}/net_dgrm.c
	${QUAKE_DIR}/net_loop.c
	${QUAKE_DIR}/net_main.c
	${QUAKE_DIR}/chase.c
	${QUAKE_DIR}/cl_demo.c
	${QUAKE_DIR}/cl_input.c
	${QUAKE_DIR}/cl_main.c
	${QUAKE_DIR}/cl_parse.c
	${QUAKE_DIR}/cl_tent.c
	${QUAKE_DIR}/console.c
	${QUAKE_DIR}/keys.c
	${QUAKE_DIR}/menu.c
	${QUAKE_DIR}/sbar.c
	${QUAKE_DIR}/view.c
	${QUAKE_DIR}/wad.c
	${QUAKE_DIR}/cmd.c
	${QUAKE_DIR}/common.c
	${QUAKE_DIR}/crc.c
	${QUAKE_DIR}/cvar.c
	${QUAKE_DIR}/cfgfile.c
	${QUAKE_DIR}/host.c
	${QUAKE_DIR}/host_cmd.c
	${QUAKE_DIR}/mathlib.c
	${QUAKE_DIR}/pr_cmds.c
	${QUAKE_DIR}/pr_edict.c
	${QUAKE_DIR}/pr_exec.c
	${QUAKE_DIR}/pr_ext.c
	${QUAKE_DIR}/sbar.c
	${QUAKE_DIR}/sv_main.c
	${QUAKE_DIR}/sv_move.c
	${QUAKE_DIR}/sv_phys.c
	${QUAKE_DIR}/sv_user.c
	${QUAKE_DIR}/world.c
	${QUAKE_DIR}/zone.c
	${QUAKE_DIR}/net_bsd.c 
	${QUAKE_DIR}/net_udp.c
	${QUAKE_DIR}/pl_linux.c
	${QUAKE_DIR}/sys_sdl_unix.c
	${QUAKE_DIR}/main_sdl.c
	${QUAKE_DIR}/snd_sdl.c
	${QUAKE_DIR}/cd_sdl.c
	${QUAKE_DIR}/in_sdl.c
	${QUAKE_DIR}/snd_dma.c
	${QUAKE_DIR}/snd_mix.c
	${QUAKE_DIR}/snd_mem.c
	${QUAKE_DIR}/snd_codec.c
	${QUAKE_DIR}/bgmusic.c
	)

add_executable(vkQuake ${SOURCE_FILES})

target_link_libraries(vkQuake SDL2-static vulkan)

# --export-dynamic needed for static loader dlsym(NULL, "vkFoo")
set_target_properties(vkQuake PROPERTIES LINK_FLAGS "-Wl,-z,stack-size=0x100000 -Wl,--export-dynamic")
