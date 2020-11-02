# Please install the following prerequisites (instructions for each follows):
# 	Android OS SDK: http://source.android.com/download
#
# Install and prepare the Android OS SDK ( http://source.android.com/download )
# on Debian or Ubuntu

### these modify the calling shell
# workaround for cross-compiling bug in autoconf
export ac_cv_func_malloc_0_nonnull=yes
export ac_cv_func_setpgrp_void=yes

EXTERNAL_ROOT := $(shell pwd)

DEBUG ?= 0

# No-op command.
NOOP = true

# Android now has 64-bit and 32-bit versions of the NDK for GNU/Linux.  We
# assume that the build platform uses the appropriate version, otherwise the
# user building this will have to manually set NDK_PROCESSOR or NDK_TOOLCHAIN.
CPU := $(shell uname -m)
ifeq ($(CPU),x86_64)
 NDK_PROCESSOR=x86_64
else
 NDK_PROCESSOR=x86
endif

# Android NDK setup
ANDROID_NDK_HOME ?= /opt/android-ndk
ANDROID_NDK ?= $(ANDROID_NDK_HOME)
NDK_PLATFORM_LEVEL ?= 16
NDK_TOOLCHAIN_VERSION=4.9
NDK_BIT ?= 32
APP_ABI ?= armeabi
NDK_ABI ?= $(APP_ABI)

# PIEFLAGS for SDK 16/Android L must be set to -fPIE -pie, but can override for earlier targets
//PIEFLAGS ?= -fPIE -pie
PIEFLAGS ?= -fPIE

ifneq ($(filter arm%, $(APP_ABI)),)
  NDK_ABI := arm
  REMOVE_BOOST_LIBS_SUFFIX := -clang-mt-a32-1_74
endif
ifneq ($(filter arm64%, $(APP_ABI)),)
 NDK_ABI := arm64
 REMOVE_BOOST_LIBS_SUFFIX := -clang-mt-a64-1_74
endif

NDK_SYSROOT=$(ANDROID_NDK_HOME)/platforms/android-$(NDK_PLATFORM_LEVEL)/arch-$(NDK_ABI)
NDK_UNAME := $(shell uname -s | tr '[A-Z]' '[a-z]')
ifneq ($(filter mips%, $(NDK_ABI)),)
 HOST := $(NDK_ABI)el-linux-android
 ALTHOST := $(HOST)
endif
ifneq ($(filter arm64, $(NDK_ABI)),)
 HOST := aarch64-linux-android
 ALTHOST := $(HOST)
endif
ifneq ($(filter arm, $(NDK_ABI)),)
 HOST := armv7a-linux-androideabi
 ALTHOST := arm-linux-androideabi
endif
ifneq ($(filter x86, $(NDK_ABI)),)
 HOST := i686-linux-android
 ALTHOST := $(HOST)
endif
ifneq ($(filter x86_64, $(NDK_ABI)),)
 HOST := x86_64-linux-android
 ALTHOST := $(HOST)
endif

NDK_TOOLCHAIN := $(HOST)-$(NDK_TOOLCHAIN_VERSION)
ifneq ($(filter x86%, $(NDK_ABI)),)
 NDK_TOOLCHAIN := $(NDK_ABI)-$(NDK_TOOLCHAIN_VERSION)
endif

//NDK_TOOLCHAIN_BASE=$(ANDROID_NDK_HOME)/toolchains/$(NDK_TOOLCHAIN)/prebuilt/$(NDK_UNAME)-$(NDK_PROCESSOR)
//NDK_TOOLCHAIN_BASE=/tmp/my-android-toolchain
NDK_TOOLCHAIN_BASE=$(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(NDK_UNAME)-$(NDK_PROCESSOR)

# include Android's build flags
TARGET_ARCH_ABI = $(APP_ABI)
#include $(ANDROID_NDK_HOME)/toolchains/$(NDK_TOOLCHAIN)/setup.mk

CC := $(NDK_TOOLCHAIN_BASE)/bin/$(HOST)$(NDK_PLATFORM_LEVEL)-clang
CXX := $(NDK_TOOLCHAIN_BASE)/bin/$(HOST)$(NDK_PLATFORM_LEVEL)-clang++ --sysroot=$(NDK_SYSROOT)
CPP := $(NDK_TOOLCHAIN_BASE)/bin/$(HOST)$(NDK_PLATFORM_LEVEL)-clang++ --sysroot=$(NDK_SYSROOT)
LD := $(NDK_TOOLCHAIN_BASE)/bin/$(ALTHOST)-ld
AR := $(NDK_TOOLCHAIN_BASE)/bin/$(ALTHOST)-ar
RANLIB := $(NDK_TOOLCHAIN_BASE)/bin/$(ALTHOST)-ranlib

ifeq ($(DEBUG), 1)
	STRIP := $(NOOP)
else
	STRIP := $(NDK_TOOLCHAIN_BASE)/bin/$(ALTHOST)-strip --strip-unneeded -R .note -R .comment --strip-debug
endif


CFLAGS = -DANDROID $(TARGET_CFLAGS) $(PIEFLAGS)
LDFLAGS = -llog $(TARGET_LDFLAGS) $(PIEFLAGS)

# change 'release' to 'debug' for unoptimized debug builds
ifeq ($(APP_ABI),armeabi-v7a)
	CFLAGS += $(TARGET_arm_release_CFLAGS)
endif
ifeq ($(APP_ABI),armeabi)
	CFLAGS += $(TARGET_thumb_release_CFLAGS)
endif



.PHONY = clean showsetup \
	assets assets-clean \
	boost boost-clean \
	openssl-static openssl-static-clean \
	miniupnpc miniupnpc-clean \
	i2pd i2pd-clean

all: assets

#------------------------------------------------------------------------------#
# openssl

# Disable rc4 cipher for 64-bit archs, to avoid this link error for tor:
# external/lib/libcrypto.a(e_rc4_hmac_md5.o):e_rc4_hmac_md5.c:function rc4_hmac_md5_cipher: error: undefined reference to 'rc4_md5_enc'
OPENSSL_CONF_FLAG=
ifneq ($(findstring 64, $(NDK_ABI)),)
 OPENSSL_CONF_FLAG+=no-rc4
endif

# OpenSSL's 'make depend' fails if _MIPS_SZLONG is not set:
ifneq ($(filter mips%, $(NDK_ABI)),)
 ifneq ($(findstring 64, $(NDK_ABI)),)
  OPENSSL_CONF_FLAG+=-D_MIPS_SZLONG=64
 else
  OPENSSL_CONF_FLAG+=-D_MIPS_SZLONG=32 -D__MIPSEL__
 endif
endif
libs/lib/libcrypto.a:
	cd libs/openssl && \
		./Configure linux-generic$(NDK_BIT) -D__ANDROID_API__=$(NDK_PLATFORM_LEVEL) -DL_ENDIAN $(OPENSSL_CONF_FLAG) && \
		make -j`nproc` CC="$(CC)" ANDROID_DEV=$(NDK_SYSROOT)/usr depend && \
		make -j`nproc` CC="$(CC)" ANDROID_DEV=$(NDK_SYSROOT)/usr build_libs

libs/lib/libssl.a:
	cp config.sub libs/openssl
	cp config.guess libs/openssl
	cd libs/openssl && \
		./Configure linux-generic$(NDK_BIT) -D__ANDROID_API__=$(NDK_PLATFORM_LEVEL) -DL_ENDIAN $(OPENSSL_CONF_FLAG) && \
		make -j`nproc` CC="$(CC)" ANDROID_DEV=$(NDK_SYSROOT)/usr depend && \
		make -j`nproc` CC="$(CC)" ANDROID_DEV=$(NDK_SYSROOT)/usr build_libs

libs/openssl-build-stamp: libs/lib/libcrypto.a libs/lib/libssl.a
	touch libs/openssl-build-stamp

openssl: libs/openssl-build-stamp

	test -d libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/$(TARGET_I2P_ABI)/lib || \
		mkdir -p libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/$(TARGET_I2P_ABI)/lib
	cp libs/openssl/libcrypto.a libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/$(TARGET_I2P_ABI)/lib/libcrypto.a
	cp libs/openssl/libssl.a libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/$(TARGET_I2P_ABI)/lib/libssl.a
	test -d libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/include/openssl || \
		mkdir -p libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/include/openssl
	cp libs/openssl/include/openssl/* libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/include/openssl

openssl-clean:
	-rm libs/openssl-build-stamp
	-rm libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/$(TARGET_I2P_ABI)/lib/libcrypto.a
	-rm libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1g-clang/$(TARGET_I2P_ABI)/lib/libssl.a
	-cd libs/openssl && \
		git clean -fdx

#------------------------------------------------------------------------------#
# boost

boost: boost-build-stamp
	-cd libs/Boost-for-Android && \
	CXXFLAGS="-std=c++14" NCPU=`nproc` ./build-android.sh --boost=1.74.0 \
		--arch=$(APP_ABI) --target-version=$(NDK_PLATFORM_LEVEL) "$(ANDROID_NDK_HOME)" > /dev/null
	test -d libs/Boost-for-Android-Prebuilt/boost-1_74_0/include/boost || \
		mkdir -p libs/Boost-for-Android-Prebuilt/boost-1_74_0/include/boost
	test -d libs/Boost-for-Android-Prebuilt/boost-1_74_0/$(APP_ABI)/lib || \
		mkdir -p libs/Boost-for-Android-Prebuilt/boost-1_74_0/$(APP_ABI)/lib

	cp -r libs/Boost-for-Android/build/out/$(APP_ABI)/include/boost-1_74/boost/* libs/Boost-for-Android-Prebuilt/boost-1_74_0/include/boost
	cp -r libs/Boost-for-Android/build/out/$(APP_ABI)/lib/*.a libs/Boost-for-Android-Prebuilt/boost-1_74_0/$(APP_ABI)/lib

	cd libs/Boost-for-Android-Prebuilt/boost-1_74_0/$(APP_ABI)/lib && \
		rename 's/$(REMOVE_BOOST_LIBS_SUFFIX)//' *.a

	cp boost/Android.mk libs/Boost-for-Android-Prebuilt/boost-1_74_0

boost-build-stamp: libs/Boost-for-Android/build-android.sh
	touch libs/boost-build-stamp

boost-clean:
	-rm -f libs/boost-build-stamp
	-rm -rf libs/Boost-for-Android-Prebuilt
	-cd libs/Boost-for-Android && \
		git clean -fdx
#------------------------------------------------------------------------------#
# miniupnpc

miniupnpc: miniupnpc-build-stamp
	make  -j`nproc` -C libs/miniupnp/miniupnpc CC="$(CC)" CXX="$(CXX)" AR="$(AR)" RANLIB="$(RANLIB)" CFLAGS="$(CFLAGS)"  LDFLAGS="$(LDFLAGS)" PREFIX="$(EXTERNAL_ROOT)"
	test -d libs/MiniUPnP-for-Android-Prebuilt/miniupnpc-2.1/$(TARGET_I2P_ABI)/lib || \
		mkdir -p libs/MiniUPnP-for-Android-Prebuilt/miniupnpc-2.1/$(TARGET_I2P_ABI)/lib
	cp libs/miniupnp/miniupnpc/libminiupnpc.a libs/MiniUPnP-for-Android-Prebuilt/miniupnpc-2.1/$(TARGET_I2P_ABI)/lib/libminiupnpc.a
	test -d libs/MiniUPnP-for-Android-Prebuilt/miniupnpc-2.1/include/miniupnpc || \
		mkdir -p libs/MiniUPnP-for-Android-Prebuilt/miniupnpc-2.1/include/miniupnpc
	cp libs/miniupnp/miniupnpc/*.h libs/MiniUPnP-for-Android-Prebuilt/miniupnpc-2.1/include/miniupnpc
	cp miniupnpc/Android.mk libs/MiniUPnP-for-Android-Prebuilt/miniupnpc-2.1/Android.mk

miniupnpc-build-stamp: libs/miniupnp/miniupnpc/Makefile
	touch libs/miniupnpc-build-stamp

miniupnpc-clean:
	-rm -f libs/miniupnpc-build-stamp
	-rm libs/MiniUPnP-for-Android-Prebuilt/miniupnpc-2.1/$(TARGET_I2P_ABI)/lib/libminiupnpc.a
	-cd libs/miniupnp && \
		git clean -fdx
#------------------------------------------------------------------------------#
# i2pd

i2pd-configure:
	-cd i2pd/android_binary_only/jni && \
		rm Application.mk
	cp i2p/Application.mk i2pd/android_binary_only/jni/Application.mk
	-cd i2pd/android_binary_only/jni && \
		rm Android.mk
	cp i2p/Android.mk i2pd/android_binary_only/jni/Android.mk

i2pd-build-stamp: i2pd-configure
	$(ANDROID_NDK_HOME)/ndk-build -C i2pd/android_binary_only -j`nproc`
	touch i2pd-build-stamp

i2pd: boost miniupnpc openssl i2pd-build-stamp
	test -d bin || mkdir bin
	cp i2pd/android_binary_only/libs/$(TARGET_I2P_ABI)/i2pd bin

i2pd-clean:
	-rm -f bin/i2pd
	-rm -f i2pd-build-stamp
	-cd i2pd && \
		git clean -fdx
	-cd i2pd && \
		git reset HEAD --hard

#------------------------------------------------------------------------------#
#create and clean assets: FYI - i2pd is stored file with an so extension
#in the libs directly, so it is handled like a shared library for local installation

assets: i2pd
	install -d ../i2pd-android-binary/src/main/libs/$(APP_ABI)
	-$(STRIP) bin/i2pd
	-mv bin/i2pd ../i2pd-android-binary/src/main/libs/$(APP_ABI)/libi2pd.so

assets-clean:
	-rm ../i2pd-android-binary/src/main/libs/$(APP_ABI)/libi2pd.so

#------------------------------------------------------------------------------#
# cleanup, cleanup, put the toys away

##clean: openssl-clean i2pd-clean assets-clean
clean: boost-clean openssl-clean i2pd-clean assets-clean

#------------------------------------------------------------------------------#
# debugging stuff

showsetup:
	@echo "NDK_TOOLCHAIN_VERSION: $(NDK_TOOLCHAIN_VERSION)"
	@echo "NDK_TOOLCHAIN: $(NDK_TOOLCHAIN)"
	@echo "NDK_PLATFORM_LEVEL: $(NDK_PLATFORM_LEVEL)"
	@echo "NDK_SYSROOT: $(NDK_SYSROOT)"
	@echo "APP_ABI: $(APP_ABI)"
	@echo "HOST: $(HOST)"
	@echo "CC: $(CC)"
	@echo "LD: $(LD)"
	@echo "CFLAGS: $(CFLAGS)"
	@echo "LDFLAGS: $(LDFLAGS)"
