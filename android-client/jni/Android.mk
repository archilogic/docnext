LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_C_INCLUDES += \
    jni/webp/include

LOCAL_MODULE := NativeWebp
LOCAL_SRC_FILES := \
   	NativeWebp.cpp \
    webp/src/dec/bits.c \
    webp/src/dec/dsp.c \
    webp/src/dec/frame.c \
    webp/src/dec/idec.c \
    webp/src/dec/quant.c \
    webp/src/dec/tree.c \
    webp/src/dec/vp8.c \
    webp/src/dec/webp.c \
    webp/src/dec/yuv.c

LOCAL_LDLIBS := -llog -lGLESv1_CM

include $(BUILD_SHARED_LIBRARY)
