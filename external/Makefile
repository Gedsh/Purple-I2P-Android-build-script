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
  export I2P_ARCH_ABI := armeabi-v7a
endif
ifneq ($(filter arm64%, $(APP_ABI)),)
 NDK_ABI := arm64
  export I2P_ARCH_ABI := arm64-v8a
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
	openssl-static openssl-static-clean \
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
lib/libcrypto.a:
	cd openssl && \
		./Configure linux-generic$(NDK_BIT) -D__ANDROID_API__=$(NDK_PLATFORM_LEVEL) -DL_ENDIAN $(OPENSSL_CONF_FLAG) && \
		make CC="$(CC)" ANDROID_DEV=$(NDK_SYSROOT)/usr depend && \
		make CC="$(CC)" ANDROID_DEV=$(NDK_SYSROOT)/usr build_libs

lib/libssl.a:
	cp config.sub openssl
	cp config.guess openssl
	cd openssl && \
		./Configure linux-generic$(NDK_BIT) -D__ANDROID_API__=$(NDK_PLATFORM_LEVEL) -DL_ENDIAN $(OPENSSL_CONF_FLAG) && \
		make CC="$(CC)" ANDROID_DEV=$(NDK_SYSROOT)/usr depend && \
		make CC="$(CC)" ANDROID_DEV=$(NDK_SYSROOT)/usr build_libs

openssl-build-stamp: lib/libcrypto.a lib/libssl.a
	touch openssl-build-stamp

openssl: openssl-build-stamp

	test -d libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1a-clang/$TARGET_ARCH_ABI/lib || mkdir -p libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1a-clang/$TARGET_ARCH_ABI/lib
	cp openssl/libcrypto.a libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1a-clang/$TARGET_ARCH_ABI/lib/libcrypto.a
	cp openssl/libssl.a libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1a-clang/$TARGET_ARCH_ABI/lib/libssl.a
	cp openssl/include/openssl/* libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1a-clang/include/openssl

openssl-clean:
	-rm openssl-build-stamp
	-rm libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1a-clang/$TARGET_ARCH_ABI/lib/libcrypto.a
	-rm libs/OpenSSL-for-Android-Prebuilt/openssl-1.1.1a-clang/$TARGET_ARCH_ABI/lib/libssl.a
	-cd openssl && \
		git clean -fdx

#------------------------------------------------------------------------------#
# i2pd

i2pd/configure:
    -cd i2pd/android_binary_only/jni && \
		rm Application.mk
	cp Application.mk i2pd/android_binary_only/jni/Application.mk

i2pd-build-stamp: i2pd/configure
	$ANDROID_NDK_HOME -C i2pd/android_binary_only -j
	touch i2pd-build-stamp

i2pd: openssl i2pd-build-stamp
	test -d bin || mkdir bin
	cp i2pd/android_binary_only/libs/I2P_ARCH_ABI/i2pd bin

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
clean: openssl-clean i2pd-clean assets-clean

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
