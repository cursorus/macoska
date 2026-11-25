#import "MCKBarView.h"

static UILabel *MCKLabel(NSString *t, CGFloat size, UIFontWeight w) {
    UILabel *l = [UILabel new];
    l.text = t;
    l.font = [UIFont systemFontOfSize:size weight:w];
    l.textColor = UIColor.labelColor;
    return l;
}

static UIImage *MCKSymbolImage(NSString *name) {
    UIImageSymbolConfiguration *c = [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightMedium];
    return [UIImage systemImageNamed:name withConfiguration:c];
}

static UIImageView *MCKSymbol(NSString *name) {
    UIImageView *v = [[UIImageView alloc] initWithImage:MCKSymbolImage(name)];
    v.tintColor = UIColor.labelColor;
    v.contentMode = UIViewContentModeScaleAspectFit;
    return v;
}

@implementation MCKBarView {
    UIVisualEffectView *_blur;
    UIStackView *_left, *_right;
    UIImageView *_battery;
    UILabel *_clock;
    NSDateFormatter *_fmt;
    NSTimer *_timer;
    NSString *_batterySym;
}

- (instancetype)initWithFrame:(CGRect)f {
    if (!(self = [super initWithFrame:f])) return nil;
    self.userInteractionEnabled = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    _blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
    [self addSubview:_blur];

    // Active app name: SpringBoard (home screen) shows "Finder", like the macOS desktop.
    NSString *name = @"Finder";
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        NSDictionary *info = NSBundle.mainBundle.infoDictionary;
        name = info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"] ?: @"App";
    }
    NSString *apple = [NSString stringWithFormat:@"%C", (unichar)0xF8FF];
    NSMutableArray *items = [NSMutableArray arrayWithObjects:MCKLabel(apple, 16, UIFontWeightRegular), MCKLabel(name, 13, UIFontWeightBold), nil];
    for (NSString *t in @[@"File", @"Edit", @"View", @"Go", @"Window", @"Help"]) {
        [items addObject:MCKLabel(t, 13, UIFontWeightRegular)];
    }
    _left = [[UIStackView alloc] initWithArrangedSubviews:items];
    _left.spacing = 16;
    _left.alignment = UIStackViewAlignmentCenter;
    [self addSubview:_left];

    UIDevice.currentDevice.batteryMonitoringEnabled = YES;
    _battery = MCKSymbol(@"battery.100");
    _batterySym = @"battery.100";
    _clock = MCKLabel(@"", 13, UIFontWeightRegular);
    _right = [[UIStackView alloc] initWithArrangedSubviews:@[_battery, MCKSymbol(@"wifi"), MCKSymbol(@"magnifyingglass"), MCKSymbol(@"switch.2"), _clock]];
    _right.spacing = 14;
    _right.alignment = UIStackViewAlignmentCenter;
    [self addSubview:_right];

    _fmt = [NSDateFormatter new];
    _fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    _fmt.dateFormat = @"EEE MMM d h:mm a";
    [self tick];
    return self;
}

- (void)tick {
    NSString *s = [_fmt stringFromDate:NSDate.date];
    if (![s isEqualToString:_clock.text]) {
        _clock.text = s;
        [self setNeedsLayout];
    }
    float lv = UIDevice.currentDevice.batteryLevel;
    NSString *sym = (lv < 0 || lv > 0.6f) ? @"battery.100" : (lv > 0.15f ? @"battery.25" : @"battery.0");
    if (![sym isEqualToString:_batterySym]) {
        _batterySym = sym;
        _battery.image = MCKSymbolImage(sym);
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [_timer invalidate];
    _timer = nil;
    if (self.window) {
        __weak MCKBarView *w = self;
        _timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer *t) { [w tick]; }];
        _timer.tolerance = 0.5;
        [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
        [self tick];
    }
}

- (void)dealloc {
    [_timer invalidate];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width, H = self.bounds.size.height;
    _blur.frame = self.bounds;
    CGSize ls = [_left systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    _left.frame = CGRectMake(14, (H - ls.height) / 2, ls.width, ls.height);
    CGSize rs = [_right systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    _right.frame = CGRectMake(W - 14 - rs.width, (H - rs.height) / 2, rs.width, rs.height);
}

@end
