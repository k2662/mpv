#!/usr/bin/env bash

set -e

FFMPEG_SYSROOT="${HOME}/deps/sysroot"
MPV_INSTALL_PREFIX="${HOME}/out/mpv"
MPV_VARIANT="${TRAVIS_OS_NAME}"

if [[ -d "./build/${MPV_VARIANT}" ]] ; then
    rm -rf "./build/${MPV_VARIANT}"
fi

PKG_CONFIG_PATH="${FFMPEG_SYSROOT}/lib/pkgconfig/" CC="${CC}" CXX="${CXX}" \
meson setup build \
    --buildtype=release
    -Dprefix="${MPV_INSTALL_PREFIX}" \
    -Drubberband-enabled \
    -D{c_args,objc_args}="-Wno-error=deprecated -Wno-error=deprecated-declarations" \
    -Dlibmpv=true \
    -D{dvdnav,libbluray,cdda,gl,vapoursynth,openal,pdf-build,html-build,cplugins,javascript,uchardet,iconv,lcms2,lua,jpeg,plain-gl,libarchive,zlib}=enabled \
    -D{cocoa,coreaudio,gl-cocoa,videotoolbox-gl,videotoolbox-pl}=enabled \
    -D{swift-build,macos-cocoa-cb,macos-media-player,macos-touchbar,vulkan}=enabled

meson compile -C build -j4
meson install -C build
./build/mpv -v --no-config
