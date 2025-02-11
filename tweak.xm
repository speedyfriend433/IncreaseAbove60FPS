#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Since PSHeader/PS.h isn’t available, we use this simple check to determine if the process is an app.
// If UIApplication exists, we’re likely running in an app process.
#define IS_APP (NSClassFromString(@"UIApplication") != nil)

@interface CAMetalLayer (Private)
@property (assign) CGFloat drawableTimeoutSeconds;
@end

#ifndef __IPHONE_15_0
typedef struct {
    NSInteger minimum;
    NSInteger preferred;
    NSInteger maximum;
} CAFrameRateRange;
#endif

// Global variable to cache the maximum frames per second value.
static NSInteger maxFPS = -1;
static NSInteger getMaxFPS(void) {
    if (maxFPS == -1)
        maxFPS = [UIScreen mainScreen].maximumFramesPerSecond;
    return maxFPS;
}

// This function checks if the tweak should be enabled for the current app.
// It reads a list of bundle identifiers from NSUserDefaults (under the domain "com.ps.coreanimationhighfps")
// and disables the tweak if the current app is in that list.
static BOOL shouldEnableForBundleIdentifier(NSString *bundleIdentifier) {
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.ps.coreanimationhighfps"];
    NSArray<NSString *> *disabledApps = [prefs objectForKey:@"CAHighFPS"];
    return ![disabledApps containsObject:bundleIdentifier];
}

#pragma mark - CADisplayLink Hooks

%hook CADisplayLink

- (void)setFrameInterval:(NSInteger)interval {
    // Force a frame interval of 1.
    %orig(1);
    if ([self respondsToSelector:@selector(setPreferredFramesPerSecond:)])
        self.preferredFramesPerSecond = 0;
}

- (void)setPreferredFramesPerSecond:(NSInteger)fps {
    // Always force to maximum by passing 0.
    %orig(0);
}

- (void)setPreferredFrameRateRange:(CAFrameRateRange)range {
    NSInteger maximum = getMaxFPS();
    range.minimum   = 30;
    range.preferred = maximum;
    range.maximum   = maximum;
    %orig(range);
}

%end

#pragma mark - CAMetalLayer Hooks

%hook CAMetalLayer

- (NSUInteger)maximumDrawableCount {
    // Return a fixed drawable count of 2.
    return 2;
}

- (void)setMaximumDrawableCount:(NSUInteger)count {
    %orig(2);
}

%end

#pragma mark - Metal Drawable Hooks

%hook CAMetalDrawable

- (void)presentAfterMinimumDuration:(CFTimeInterval)duration {
    // Force presentation after a minimum duration based on maxFPS.
    %orig(1.0 / (double)getMaxFPS());
}

%end

#pragma mark - Metal Command Buffer Hooks

%hook MTLCommandBuffer

- (void)presentDrawable:(id)drawable afterMinimumDuration:(CFTimeInterval)minimumDuration {
    // Override the minimum duration so that presentation is as fast as possible.
    %orig(drawable, 1.0 / (double)getMaxFPS());
}

%end

#pragma mark - Initialization

%ctor {
    // Check if the process is an app and whether the current bundle identifier is enabled for high FPS.
    if (IS_APP && shouldEnableForBundleIdentifier([[NSBundle mainBundle] bundleIdentifier])) {
        %init;
    }
}
