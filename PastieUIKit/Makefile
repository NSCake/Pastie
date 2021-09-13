export TARGET = iphone:latest:13.0
export ARCHS = arm64 arm64e
# INSTALL_TARGET_PROCESSES = MobileSMS
include $(THEOS)/makefiles/common.mk

SOURCES := $(wildcard *.m)

TWEAK_NAME = PastieUIKit
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_CFLAGS += -fobjc-arc -Wno-objc-string-compare -Wno-shorten-64-to-32

include $(THEOS_MAKE_PATH)/tweak.mk

before-stage::
	find . -name ".DS_Store" -delete

