#import <UIKit/UIKit.h>

#define MCK_DOMAIN CFSTR("com.cursorus.macoska")

static inline id MCKPref(NSString *key) {
    return CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key, MCK_DOMAIN));
}

static inline BOOL MCKBool(NSString *key, BOOL def) {
    id v = MCKPref(key);
    return v ? [v boolValue] : def;
}

static inline CGFloat MCKFloat(NSString *key, CGFloat def) {
    id v = MCKPref(key);
    return v ? [v doubleValue] : def;
}

static inline CGFloat MCKDockScale(void) {
    if (!MCKBool(@"dockEnabled", YES)) return 1.0;
    CGFloat s = MCKFloat(@"dockScale", 1.2);
    return MIN(MAX(s, 0.8), 1.6);
}
