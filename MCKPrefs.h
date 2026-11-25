#import <UIKit/UIKit.h>

#define MCK_DOMAIN CFSTR("com.cursorus.macoska")

// Read once per process launch (a respring applies changes), so layout code
// never talks to cfprefsd.
static inline NSDictionary *MCKPrefsDict(void) {
    static NSDictionary *d;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSDictionary *r = nil;
        CFArrayRef keys = CFPreferencesCopyKeyList(MCK_DOMAIN, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (keys) {
            r = CFBridgingRelease(CFPreferencesCopyMultiple(keys, MCK_DOMAIN, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
            CFRelease(keys);
        }
        d = r ?: @{};
    });
    return d;
}

static inline BOOL MCKBool(NSString *key, BOOL def) {
    id v = MCKPrefsDict()[key];
    return v ? [v boolValue] : def;
}

static inline CGFloat MCKFloat(NSString *key, CGFloat def) {
    id v = MCKPrefsDict()[key];
    return v ? [v doubleValue] : def;
}

static inline CGFloat MCKDockScale(void) {
    if (!MCKBool(@"dockEnabled", NO)) return 1.0;
    CGFloat s = MCKFloat(@"dockScale", 1.2);
    return MIN(MAX(s, 0.8), 1.6);
}
