#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <fcntl.h>
#import <unistd.h>
#import "MCKBarView.h"
#import "MCKPrefs.h"

// SBIconImageInfo on iOS 15: { CGSize size; CGFloat scale; CGFloat continuousCornerRadius; }
typedef struct { CGSize size; CGFloat scale; CGFloat continuousCornerRadius; } MCKIconImageInfo;

@interface UIStatusBar_Modern : UIView @end
@interface SBIconListView : UIView @end
@interface SBDockIconListView : SBIconListView @end
@interface SBFloatingDockView : UIView @end

#define MCK_MARK "/var/tmp/macoska.loading"
#define MCK_LOG  "/var/tmp/macoska.log"

// Plain-text trace. After a hang, the last line of /var/tmp/macoska.log
// shows how far the tweak got.
static void MCKLog(const char *msg) {
    FILE *f = fopen(MCK_LOG, "a");
    if (f) { fprintf(f, "%s\n", msg); fclose(f); }
}

static const void *kMCKBar = &kMCKBar;
static BOOL mckBusy = NO;

// Puts the macOS bar into the system status bar and hides the stock content.
// Every mutation is guarded so layout is never re-invalidated needlessly.
static void MCKSync(UIView *sb) {
    if (mckBusy) return;
    static BOOL isPad;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ isPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad; });
    if (!isPad) return;
    mckBusy = YES;

    MCKBarView *bar = objc_getAssociatedObject(sb, kMCKBar);
    if (!bar) {
        MCKLog("bar: creating");
        bar = [[MCKBarView alloc] initWithFrame:sb.bounds];
        objc_setAssociatedObject(sb, kMCKBar, bar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [sb addSubview:bar];
        MCKLog("bar: created");
    }
    if (!CGRectEqualToRect(bar.frame, sb.bounds)) bar.frame = sb.bounds;
    if (sb.subviews.lastObject != bar) [sb bringSubviewToFront:bar];
    for (UIView *v in sb.subviews) if (v != bar && !v.hidden) v.hidden = YES;

    mckBusy = NO;
}

%group Bar
%hook UIStatusBar_Modern
- (void)layoutSubviews { %orig; MCKSync(self); }
- (void)didMoveToWindow { %orig; MCKSync(self); }
%end
%end

%group Dock
%hook SBDockIconListView
- (MCKIconImageInfo)iconImageInfo {
    static BOOL logged;
    if (!logged) { logged = YES; MCKLog("dock: iconImageInfo called"); }
    MCKIconImageInfo i = %orig;
    CGFloat s = MCKDockScale();
    i.size.width *= s;
    i.size.height *= s;
    i.continuousCornerRadius *= s;
    return i;
}
%end
%hook SBFloatingDockView
+ (CGFloat)defaultHeight { return %orig * MCKDockScale(); }
%end
%end

%ctor {
    // SpringBoard only (apps are left alone until this is stable).
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) return;

    // Crash/hang guard: the marker is removed 15s after a healthy launch.
    // If it is still there, the previous launch never finished, so skip the
    // tweak once. That gets SpringBoard back so you can turn features off
    // in Settings -> macoska, or remove the tweak.
    if (access(MCK_MARK, F_OK) == 0) {
        unlink(MCK_MARK);
        MCKLog("SAFE MODE: previous launch did not finish, tweak skipped");
        return;
    }
    close(open(MCK_MARK, O_CREAT | O_WRONLY, 0644));
    MCKLog("ctor");

    if (MCKBool(@"barEnabled", YES)) { %init(Bar); MCKLog("bar hooks on"); }
    if (MCKBool(@"dockEnabled", NO)) { %init(Dock); MCKLog("dock hooks on"); }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        unlink(MCK_MARK);
        MCKLog("launch ok");
    });
}
