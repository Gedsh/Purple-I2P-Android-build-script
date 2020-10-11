LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libminiupnpc
LOCAL_SRC_FILES := $(TARGET_ARCH_ABI)/lib/libminiupnpc.a
include $(PREBUILT_STATIC_LIBRARY)
