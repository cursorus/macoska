#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "MCKBarView.h"
#import "MCKPrefs.h"

// SBIconImageInfo on iOS 15: { CGSize size; CGFloat scale; CGFloat continuousCornerRadius; }
typedef struct { CGSize size; CGFloat scale; CGFloat continuousCornerRadius; } MCKIconImageInfo;

@interface UIStatusBar_Modern : UIView @end
@interface SBIconListView : UIView @end
@interface SBDockIconListView : SBIconListView @end
@interface SBFloatingDockView : UIView @end

static const void *kMCKBar = &kMCKBar;

// Puts the macOS bar into the system status bar and hides the stock content.
// The status bar keeps its frame, so app layout does not shift.
static void MCKSync(UIView *sb) {
    MCKBarView *bar = objc_getAssociatedObject(sb, kMCKBar);
    if (!MCKBool(@"barEnabled", YES)) {
        if (bar) {
            [bar removeFromSuperview];
            objc_setAssociatedObject(sb, kMCKBar, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            for (UIView *v in sb.subviews) v.hidden = NO;
        }
        return;
    }
    if (!bar) {
        bar = [[MCKBarView alloc] initWithFrame:sb.bounds];
        objc_setAssociatedObject(sb, kMCKBar, bar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [sb addSubview:bar];
    }
    bar.frame = sb.bounds;
    [sb bringSubviewToFront:bar];
    for (UIView *v in sb.subviews) if (v != bar) v.hidden = YES;
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
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) return;
    %init(Bar);
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        %init(Dock);
    }
}
