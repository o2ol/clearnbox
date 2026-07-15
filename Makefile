export THEOS ?= /Users/macmini/work/theos
ARCHS = arm64
TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = CleanBox

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = CleanBox

CleanBox_FILES = main.m \
	CBAppDelegate.m \
	CBCleanManager.m \
	CBRootViewController.m \
	CBDetailViewController.m \
	CBSettingsViewController.m \
	CBHelpViewController.m \
	CBAboutViewController.m \
	CBVersionViewController.m \
	CBCopyUtil.m \
	CBAppCell.m \
	CBSettings.m \
	CBStorageInfo.m \
	CBStorageHeaderView.m \
	CBTheme.m \
	CBGlassView.m

CleanBox_FRAMEWORKS = UIKit Foundation CoreGraphics CoreServices
CleanBox_PRIVATE_FRAMEWORKS = MobileCoreServices
CleanBox_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-deprecated-declarations -Wno-objc-method-access
CleanBox_CODESIGN_FLAGS = -Sentitlements.plist
CleanBox_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk
