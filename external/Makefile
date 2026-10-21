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
NDK_PLATFORM_LEVEL ?= 21
APP_ABI ?= armeabi-v7a
NDK_ABI ?= $(APP_ABI)

PIEFLAGS ?= -fPIE

ifneq ($(filter arm%, $(APP_ABI)),)
  NDK_ABI := arm
endif
ifneq ($(filter arm64%, $(APP_ABI)),)
 NDK_ABI := arm64
endif
ifneq ($(filter x86_64%, $(APP_ABI)),)
 NDK_ABI := x86_64
endif

NDK_UNAME := $(shell uname -s | tr '[A-Z]' '[a-z]')
ifneq ($(filter mips%, $(NDK_ABI)),)
 HOST := $(NDK_ABI)el-linux-android
endif
ifneq ($(filter arm64, $(NDK_ABI)),)
 HOST := aarch64-linux-android
endif
ifneq ($(filter arm, $(NDK_ABI)),)
 HOST := armv7a-linux-androideabi
endif
ifneq ($(filter x86, $(NDK_ABI)),)
 HOST := i686-linux-android
endif
ifneq ($(filter x86_64, $(NDK_ABI)),)
 HOST := x86_64-linux-android
endif

NDK_TOOLCHAIN_BASE=$(ANDROID_NDK_HOME)/toolchains/llvm/prebuilt/$(NDK_UNAME)-$(NDK_PROCESSOR)
NDK_SYSROOT=$(NDK_TOOLCHAIN_BASE)/sysroot

TARGET_ARCH_ABI = $(APP_ABI)

CC := $(NDK_TOOLCHAIN_BASE)/bin/$(HOST)$(NDK_PLATFORM_LEVEL)-clang
CXX := $(NDK_TOOLCHAIN_BASE)/bin/$(HOST)$(NDK_PLATFORM_LEVEL)-clang++ --sysroot=$(NDK_SYSROOT)
CPP := $(NDK_TOOLCHAIN_BASE)/bin/$(HOST)$(NDK_PLATFORM_LEVEL)-clang++ --sysroot=$(NDK_SYSROOT)
LD := $(NDK_TOOLCHAIN_BASE)/bin/ld.lld
AR := $(NDK_TOOLCHAIN_BASE)/bin/llvm-ar
RANLIB := $(NDK_TOOLCHAIN_BASE)/bin/llvm-ranlib

ifeq ($(DEBUG), 1)
	STRIP := $(NOOP)
else
	STRIP := $(NDK_TOOLCHAIN_BASE)/bin/llvm-strip --strip-unneeded -R .note -R .comment --strip-debug
endif


CFLAGS = -DANDROID $(TARGET_CFLAGS) $(PIEFLAGS)
LDFLAGS = -llog $(TARGET_LDFLAGS) $(PIEFLAGS)

ifeq ($(APP_ABI),arm64-v8a)
    LDFLAGS += -Wl,-z,max-page-size=16384
endif
ifeq ($(APP_ABI),x86_64)
    LDFLAGS += -Wl,-z,max-page-size=16384
endif

# change 'release' to 'debug' for unoptimized debug builds
ifeq ($(APP_ABI),armeabi-v7a)
	CFLAGS += $(TARGET_arm_release_CFLAGS)
endif
ifeq ($(APP_ABI),armeabi)
	CFLAGS += $(TARGET_thumb_release_CFLAGS)
endif

CFLAGS += -ffunction-sections -fdata-sections -fvisibility=hidden -O3 -funsafe-math-optimizations -ftree-vectorize -fvectorize -fslp-vectorize
LDFLAGS += -Wl,--gc-sections

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
 OPENSSL_CONF_FLAG+=no-rc4 enable-ec_nistp_64_gcc_128
endif

# OpenSSL's 'make depend' fails if _MIPS_SZLONG is not set:
ifneq ($(filter mips%, $(NDK_ABI)),)
 ifneq ($(findstring 64, $(NDK_ABI)),)
  OPENSSL_CONF_FLAG+=-D_MIPS_SZLONG=64
 else
  OPENSSL_CONF_FLAG+=-D_MIPS_SZLONG=32 -D__MIPSEL__
 endif
endif
libs/openssl-build-stamp: libs/openssl/Configure
	cd libs/openssl && \
		export ANDROID_NDK_ROOT="$(ANDROID_NDK_HOME)" PATH="$(NDK_TOOLCHAIN_BASE)/bin:$$PATH" && \
		./Configure android-$(NDK_ABI) -D__ANDROID_API__=$(NDK_PLATFORM_LEVEL) no-shared $(OPENSSL_CONF_FLAG) -DNO_RECVMMSG && \
		$(MAKE) -j`nproc` build_libs
	touch libs/openssl-build-stamp

openssl: libs/openssl-build-stamp

	test -d libs/OpenSSL-for-Android-Prebuilt/openssl/$(TARGET_I2P_ABI)/lib || \
		mkdir -p libs/OpenSSL-for-Android-Prebuilt/openssl/$(TARGET_I2P_ABI)/lib
	cp libs/openssl/libcrypto.a libs/OpenSSL-for-Android-Prebuilt/openssl/$(TARGET_I2P_ABI)/lib/libcrypto.a
	cp libs/openssl/libssl.a libs/OpenSSL-for-Android-Prebuilt/openssl/$(TARGET_I2P_ABI)/lib/libssl.a
	test -d libs/OpenSSL-for-Android-Prebuilt/openssl/include/openssl || \
		mkdir -p libs/OpenSSL-for-Android-Prebuilt/openssl/include/openssl
	cp libs/openssl/include/openssl/* libs/OpenSSL-for-Android-Prebuilt/openssl/include/openssl

openssl-clean:
	-rm libs/openssl-build-stamp
	-rm -rf libs/OpenSSL-for-Android-Prebuilt/openssl
	-cd libs/openssl && \
		git clean -fdx

#------------------------------------------------------------------------------#
# boost

boost: boost-build-stamp
	@cd libs/Boost-for-Android && \
	CXXFLAGS="-std=c++20" NCPU=`nproc` ./build-android.sh --boost=1.84.0 \
		--with-libraries=program_options --layout=system \
		--arch=$(APP_ABI) --target-version=$(NDK_PLATFORM_LEVEL) "$(ANDROID_NDK_HOME)" \
		> "$(EXTERNAL_ROOT)/libs/boost-build.log" 2>&1 || \
		{ echo "Boost build failed; last 100 log lines:"; tail -n 100 "$(EXTERNAL_ROOT)/libs/boost-build.log"; exit 1; }
	@test -s libs/Boost-for-Android/build/out/$(APP_ABI)/lib/libboost_program_options.a && \
		test -f libs/Boost-for-Android/build/out/$(APP_ABI)/include/boost/version.hpp || \
		{ echo "Boost output missing; last 100 log lines:"; tail -n 100 libs/boost-build.log; exit 1; }
	@echo "Boost 1.84.0 built for $(APP_ABI); details: libs/boost-build.log"
	mkdir -p libs/Boost-for-Android-Prebuilt/boost/include/boost
	mkdir -p libs/Boost-for-Android-Prebuilt/boost/$(APP_ABI)/lib
	cp -r libs/Boost-for-Android/build/out/$(APP_ABI)/include/boost/* libs/Boost-for-Android-Prebuilt/boost/include/boost
	cp libs/Boost-for-Android/build/out/$(APP_ABI)/lib/libboost_program_options.a libs/Boost-for-Android-Prebuilt/boost/$(APP_ABI)/lib

boost-build-stamp: libs/Boost-for-Android/build-android.sh
	touch libs/boost-build-stamp

boost-clean:
	-rm -f libs/boost-build-stamp
	-rm -f libs/boost-build.log
	-rm -rf libs/Boost-for-Android-Prebuilt
	-cd libs/Boost-for-Android && \
		git clean -fdx
#------------------------------------------------------------------------------#
# miniupnpc

miniupnpc: miniupnpc-build-stamp
	make  -j`nproc` -C libs/miniupnp/miniupnpc CC="$(CC)" CXX="$(CXX)" AR="$(AR)" RANLIB="$(RANLIB)" CFLAGS="$(CFLAGS)"  LDFLAGS="$(LDFLAGS)" PREFIX="$(EXTERNAL_ROOT)"
	test -d libs/MiniUPnP-for-Android-Prebuilt/miniupnpc/$(TARGET_I2P_ABI)/lib || \
		mkdir -p libs/MiniUPnP-for-Android-Prebuilt/miniupnpc/$(TARGET_I2P_ABI)/lib
	cp libs/miniupnp/miniupnpc/build/libminiupnpc.a libs/MiniUPnP-for-Android-Prebuilt/miniupnpc/$(TARGET_I2P_ABI)/lib/libminiupnpc.a
	test -d libs/MiniUPnP-for-Android-Prebuilt/miniupnpc/include/miniupnpc || \
		mkdir -p libs/MiniUPnP-for-Android-Prebuilt/miniupnpc/include/miniupnpc
	cp libs/miniupnp/miniupnpc/include/*.h libs/MiniUPnP-for-Android-Prebuilt/miniupnpc/include/miniupnpc
	cp miniupnpc/Android.mk libs/MiniUPnP-for-Android-Prebuilt/miniupnpc/Android.mk

miniupnpc-build-stamp: libs/miniupnp/miniupnpc/Makefile
	touch libs/miniupnpc-build-stamp

miniupnpc-clean:
	-rm -f libs/miniupnpc-build-stamp
	-rm -rf libs/MiniUPnP-for-Android-Prebuilt/miniupnpc
	-cd libs/miniupnp && \
		git clean -fdx
#------------------------------------------------------------------------------#
# i2pd

i2pd-build-stamp:
	$(ANDROID_NDK_HOME)/ndk-build NDK_DEBUG=$(DEBUG) -C i2p -j`nproc`
	touch i2pd-build-stamp

i2pd: boost miniupnpc openssl i2pd-build-stamp
	test -d bin || mkdir bin
	cp i2p/libs/$(TARGET_I2P_ABI)/i2pd bin

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
clean: boost-clean openssl-clean miniupnpc-clean i2pd-clean assets-clean

#------------------------------------------------------------------------------#
# debugging stuff

showsetup:
	@echo "NDK_PLATFORM_LEVEL: $(NDK_PLATFORM_LEVEL)"
	@echo "NDK_SYSROOT: $(NDK_SYSROOT)"
	@echo "APP_ABI: $(APP_ABI)"
	@echo "HOST: $(HOST)"
	@echo "CC: $(CC)"
	@echo "LD: $(LD)"
	@echo "CFLAGS: $(CFLAGS)"
	@echo "LDFLAGS: $(LDFLAGS)"
