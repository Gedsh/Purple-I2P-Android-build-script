#APP_ABI := all
#APP_ABI += x86
#APP_ABI += x86_64
APP_ABI += $(TARGET_I2P_ABI)
#can be android-3 but will fail for x86 since arch-x86 is not present at ndkroot/platforms/android-3/ . libz is taken from there.
APP_PLATFORM := android-$(TARGET_I2P_PLATFORM)

NDK_TOOLCHAIN_VERSION := clang
APP_STL := c++_static

APP_CFLAGS += -O3 -ftree-vectorize -fvectorize -fslp-vectorize

# Enable c++17 extensions in source code
APP_CPPFLAGS += -std=c++17 -fexceptions -frtti -fvisibility=default -fPIE
APP_CPPFLAGS += -O3 -ftree-vectorize -fvectorize -fslp-vectorize

APP_CPPFLAGS += -DANDROID_BINARY -DANDROID -D__ANDROID__ -DUSE_UPNP -Wno-deprecated-declarations -fstack-protector
APP_LDFLAGS += -rdynamic -fPIE -pie
ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
APP_CFLAGS += -march=armv7-a -mfpu=neon-vfpv4
APP_CPPFLAGS += -DANDROID_ARM7A -march=armv7-a -mfpu=neon-vfpv4
endif

# Forcing debug optimization. Use `ndk-build NDK_DEBUG=1` instead.
#APP_OPTIM  := debug

# git clone https://github.com/PurpleI2P/Boost-for-Android-Prebuilt.git -b boost-1_72_0
# git clone https://github.com/PurpleI2P/OpenSSL-for-Android-Prebuilt.git
# git clone https://github.com/PurpleI2P/MiniUPnP-for-Android-Prebuilt.git
# git clone https://github.com/PurpleI2P/android-ifaddrs.git
# change to your own
I2PD_LIBS_PATH = $(EXTERNAL_ROOT)/libs
BOOST_PATH = $(I2PD_LIBS_PATH)/Boost-for-Android-Prebuilt
OPENSSL_PATH = $(I2PD_LIBS_PATH)/OpenSSL-for-Android-Prebuilt
MINIUPNP_PATH = $(I2PD_LIBS_PATH)/MiniUPnP-for-Android-Prebuilt
IFADDRS_PATH = $(I2PD_LIBS_PATH)/android-ifaddrs

# don't change me
I2PD_SRC_PATH = $(EXTERNAL_ROOT)/i2pd

LIB_SRC_PATH = $(I2PD_SRC_PATH)/libi2pd
LIB_CLIENT_SRC_PATH = $(I2PD_SRC_PATH)/libi2pd_client
DAEMON_SRC_PATH = $(I2PD_SRC_PATH)/daemon
TRANSLATIONS_PATH = $(I2PD_SRC_PATH)/i18n
