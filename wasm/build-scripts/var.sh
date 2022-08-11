#!/bin/bash
#
# Common variables for all scripts

set -euo pipefail

# Include llvm binaries
export PATH=$PATH:$EMSDK/upstream/bin

# if yes, we are building a single thread version of
# ffmpeg.wasm-core, which is slow but compatible with
# most browsers as there is no SharedArrayBuffer.
FFMPEG_ST=${FFMPEG_ST:-no}

# Root directory
ROOT_DIR=$PWD

# Directory to install headers and libraries
BUILD_DIR=$ROOT_DIR/build

# Directory to look for pkgconfig files
EM_PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig

# Toolchain file path for cmake
TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake

# Flags for code optimization, focus on speed instead
# of size
OPTIM_FLAGS="-O3"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Use closure complier only in linux environment
  OPTIM_FLAGS="$OPTIM_FLAGS --closure 1"
fi

# Unset OPTIM_FLAGS can speed up build
# OPTIM_FLAGS=""

CFLAGS_BASE="$OPTIM_FLAGS -I$BUILD_DIR/include"
CFLAGS="$CFLAGS_BASE -s USE_PTHREADS=1"

if [[ "$FFMPEG_ST" == "yes" ]]; then
  CFLAGS="$CFLAGS_BASE"
  EXTRA_FFMPEG_CONF_FLAGS="--disable-pthreads --disable-w32threads --disable-os2threads"
fi

export CFLAGS=$CFLAGS
export CXXFLAGS=$CFLAGS
export LDFLAGS="$CFLAGS -L$BUILD_DIR/lib"
export STRIP="llvm-strip"
export EM_PKG_CONFIG_PATH=$EM_PKG_CONFIG_PATH

FFMPEG_CONFIG_FLAGS_BASE=(
  --target-os=none        # use none to prevent any os specific configurations
  --arch=x86_32           # use x86_32 to achieve minimal architectural optimization
  --disable-encoders
  --enable-encoder=pcm_s16le
  --disable-decoders
  --enable-decoder=8svx_exp,8svx_fib,aac,aac_latm,ac3,acelp.kelvin,adpcm_4xm,adpcm_adx,adpcm_afc,adpcm_agm,adpcm_aica,adpcm_argo,adpcm_ct,adpcm_dtk,adpcm_ea,adpcm_ea_maxis_xa,adpcm_ea_r1,adpcm_ea_r2,adpcm_ea_r3,adpcm_ea_xas,adpcm_g722,adpcm_g726,adpcm_g726le,adpcm_ima_alp,adpcm_ima_amv,adpcm_ima_apc,adpcm_ima_apm,adpcm_ima_cunning,adpcm_ima_dat4,adpcm_ima_dk3,adpcm_ima_dk4,adpcm_ima_ea_eacs,adpcm_ima_ea_sead,adpcm_ima_iss,adpcm_ima_moflex,adpcm_ima_mtf,adpcm_ima_oki,adpcm_ima_qt,adpcm_ima_rad,adpcm_ima_smjpeg,adpcm_ima_ssi,adpcm_ima_wav,adpcm_ima_ws,adpcm_ms,adpcm_mtaf,adpcm_psx,adpcm_sbpro_2,adpcm_sbpro_3,adpcm_sbpro_4,adpcm_swf,adpcm_thp,adpcm_thp_le,adpcm_vima,adpcm_xa,adpcm_yamaha,adpcm_zork,alac,amr_nb,amr_wb,ape,aptx,aptx_hd,atrac1,atrac3,atrac3al,atrac3p,atrac3pal,atrac9,avc,binkaudio_dct,binkaudio_rdft,bmv_audio,comfortnoise,cook,derf_dpcm,dolby_e,dsd_lsbf,dsd_lsbf_planar,dsd_msbf,dsd_msbf_planar,dsicinaudio,dss_sp,dst,dts,dvaudio,eac3,evrc,fastaudio,flac,g723_1,g729,gremlin_dpcm,gsm,gsm_ms,hca,hcom,iac,ilbc,imc,interplay_dpcm,interplayacm,mace3,mace6,metasound,mlp,mp1,mp2,mp3,mp3adu,mp3on4,mp4als,musepack7,musepack8,nellymoser,opus,paf_audio,pcm_alaw,pcm_bluray,pcm_dvd,pcm_f16le,pcm_f24le,pcm_f32be,pcm_f32le,pcm_f64be,pcm_f64le,pcm_lxf,pcm_mulaw,pcm_s16be,pcm_s16be_planar,pcm_s16le,pcm_s16le_planar,pcm_s24be,pcm_s24daud,pcm_s24le,pcm_s24le_planar,pcm_s32be,pcm_s32le,pcm_s32le_planar,pcm_s64be,pcm_s64le,pcm_s8,pcm_s8_planar,pcm_sga,pcm_u16be,pcm_u16le,pcm_u24be,pcm_u24le,pcm_u32be,pcm_u32le,pcm_u8,pcm_vidc,qcelp,qdm2,qdmc,ra_144,ra_288,ralf,roq_dpcm,s302m,sbc,sdx2_dpcm,shorten,sipr,siren,smackaudio,sol_dpcm,sonic,speex,tak,truehd,truespeech,tta,twinvq,vmdaudio,vorbis,wavesynth,wavpack,westwood_snd1,wmalossless,wmapro,wmav1,wmav2,wmavoice,xan_dpcm,xma1,xma2
  --disable-muxers
  --enable-muxer=null
  --enable-lto
  --disable-protocols
  --enable-protocol=file
  --disable-filters
  --enable-filter=asetnsamples,astats,ametadata,aformat,aresample,volumedetect
  --enable-cross-compile  # enable cross compile
  --disable-x86asm        # disable x86 asm
  --disable-inline-asm    # disable inline asm
  --disable-stripping     # disable stripping
  --disable-programs      # disable programs build (incl. ffplay, ffprobe & ffmpeg)
  --disable-doc           # disable doc
  --disable-debug         # disable debug info, required by closure
  --disable-runtime-cpudetect   # disable runtime cpu detect
  --disable-autodetect    # disable external libraries auto detect
  --extra-cflags="$CFLAGS"
  --extra-cxxflags="$CFLAGS"
  --extra-ldflags="$LDFLAGS"
  --pkg-config-flags="--static"
  --nm="llvm-nm"
  --ar=emar
  --ranlib=emranlib
  --cc=emcc
  --cxx=em++
  --objcc=emcc
  --dep-cc=emcc
  ${EXTRA_FFMPEG_CONF_FLAGS-}
)

echo "EMSDK=$EMSDK"
echo "FFMPEG_ST=$FFMPEG_ST"
echo "CFLAGS(CXXFLAGS)=$CFLAGS"
echo "BUILD_DIR=$BUILD_DIR"
