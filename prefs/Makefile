include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = macoskaprefs
macoskaprefs_FILES = MCKRootListController.m
macoskaprefs_FRAMEWORKS = UIKit
macoskaprefs_INSTALL_PATH = /Library/PreferenceBundles
macoskaprefs_CFLAGS = -fobjc-arc
# The CI SDK has no Preferences.framework stub; symbols resolve at runtime
# (the Settings app has Preferences loaded before it opens our bundle).
macoskaprefs_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
