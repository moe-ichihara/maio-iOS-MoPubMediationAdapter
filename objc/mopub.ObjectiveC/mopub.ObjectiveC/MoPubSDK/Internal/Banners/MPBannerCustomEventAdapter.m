//
//  MPBannerCustomEventAdapter.m
//
//  Copyright 2018-2019 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPBannerCustomEventAdapter.h"

#import "MPAdConfiguration.h"
#import "MPAdTargeting.h"
#import "MPBannerCustomEvent.h"
#import "MPCoreInstanceProvider.h"
#import "MPError.h"
#import "MPLogging.h"
#import "MPAdImpressionTimer.h"
#import "MPBannerCustomEvent+Internal.h"

@interface MPBannerCustomEventAdapter () <MPAdImpressionTimerDelegate>

@property (nonatomic, strong) MPBannerCustomEvent *bannerCustomEvent;
@property (nonatomic, strong) MPAdConfiguration *configuration;
@property (nonatomic, assign) BOOL hasTrackedImpression;
@property (nonatomic, assign) BOOL hasTrackedClick;
@property (nonatomic) MPAdImpressionTimer *impressionTimer;
@property (nonatomic) UIView *adView;

- (void)trackClickOnce;

@end

@implementation MPBannerCustomEventAdapter

- (instancetype)initWithConfiguration:(MPAdConfiguration *)configuration delegate:(id<MPBannerAdapterDelegate>)delegate
{
    if (!configuration.customEventClass) {
        return nil;
    }
    return [self initWithDelegate:delegate];
}

- (void)unregisterDelegate
{
    if ([self.bannerCustomEvent respondsToSelector:@selector(invalidate)]) {
        // Secret API to allow us to detach the custom event from (shared instance) routers synchronously
        [self.bannerCustomEvent performSelector:@selector(invalidate)];
    }
    self.bannerCustomEvent.delegate = nil;

    // make sure the custom event isn't released synchronously as objects owned by the custom event
    // may do additional work after a callback that results in unregisterDelegate being called
    [[MPCoreInstanceProvider sharedProvider] keepObjectAliveForCurrentRunLoopIteration:_bannerCustomEvent];

    [super unregisterDelegate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration targeting:(MPAdTargeting *)targeting containerSize:(CGSize)size
{
    MPLogInfo(@"Looking for custom event class named %@.", configuration.customEventClass);
    self.configuration = configuration;

    MPBannerCustomEvent *customEvent = [[configuration.customEventClass alloc] init];
    if (![customEvent isKindOfClass:[MPBannerCustomEvent class]]) {
        NSError * error = [NSError customEventClass:configuration.customEventClass doesNotInheritFrom:MPBannerCustomEvent.class];
        MPLogEvent([MPLogEvent error:error message:nil]);
        [self.delegate adapter:self didFailToLoadAdWithError:error];
        return;
    }
        

    self.bannerCustomEvent = customEvent;
    self.bannerCustomEvent.delegate = self;
    self.bannerCustomEvent.localExtras = targeting.localExtras;
    
    [self.bannerCustomEvent requestAdWithSize:size customEventInfo:configuration.customEventClassData adMarkup:configuration.advancedBidPayload];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
    [self.bannerCustomEvent rotateToOrientation:newOrientation];
}

- (void)didDisplayAd
{
    if([self shouldTrackImpressionOnDisplay]) {
        [self trackImpressionOnDisplay];
    } else if (self.configuration.visibleImpressionTrackingEnabled) {
        [self startViewableTrackingTimer];
    } else {
        // Mediated networks except Google AdMob
        // no-op here.
    }

    [self.bannerCustomEvent didDisplayAd];
}

#pragma mark - 1px impression tracking methods

- (void)trackImpressionOnDisplay
{
    self.hasTrackedImpression = YES;
    [self trackImpression];
}

- (void)startViewableTrackingTimer
{
    self.impressionTimer = [[MPAdImpressionTimer alloc] initWithRequiredSecondsForImpression:self.configuration.impressionMinVisibleTimeInSec requiredViewVisibilityPixels:self.configuration.impressionMinVisiblePixels];
    self.impressionTimer.delegate = self;
    [self.impressionTimer startTrackingView:self.adView];
}


- (BOOL)shouldTrackImpressionOnDisplay {
    if (self.configuration.visibleImpressionTrackingEnabled) {
        return NO;
    }
    if([self.bannerCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedImpression) {
        return YES;
    }
    return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - MPPrivateBannerCustomEventDelegate

- (NSString *)adUnitId
{
    return [self.delegate banner].adUnitId;
}

- (UIViewController *)viewControllerForPresentingModalView
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (id)bannerDelegate
{
    return [self.delegate bannerDelegate];
}

- (CLLocation *)location
{
    return [self.delegate location];
}

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didLoadAd:(UIView *)ad
{
    [self didStopLoading];
    if (ad) {
        self.adView = ad;
        [self.delegate adapter:self didFinishLoadingAd:ad];
    } else {
        [self.delegate adapter:self didFailToLoadAdWithError:nil];
    }
}

- (void)bannerCustomEvent:(MPBannerCustomEvent *)event didFailToLoadAdWithError:(NSError *)error
{
    [self didStopLoading];
    [self.delegate adapter:self didFailToLoadAdWithError:error];
}

- (void)bannerCustomEventWillBeginAction:(MPBannerCustomEvent *)event
{
    [self trackClickOnce];
    [self.delegate userActionWillBeginForAdapter:self];
}

- (void)bannerCustomEventDidFinishAction:(MPBannerCustomEvent *)event
{
    [self.delegate userActionDidFinishForAdapter:self];
}

- (void)bannerCustomEventWillLeaveApplication:(MPBannerCustomEvent *)event
{
    [self trackClickOnce];
    [self.delegate userWillLeaveApplicationFromAdapter:self];
}

- (void)trackClickOnce
{
    if ([self.bannerCustomEvent enableAutomaticImpressionAndClickTracking] && !self.hasTrackedClick) {
        self.hasTrackedClick = YES;
        [self trackClick];
    }
}

- (void)bannerCustomEventWillExpandAd:(MPBannerCustomEvent *)event
{
    [self.delegate adWillExpandForAdapter:self];
}

- (void)bannerCustomEventDidCollapseAd:(MPBannerCustomEvent *)event
{
    [self.delegate adDidCollapseForAdapter:self];
}

#pragma mark - MPAdImpressionTimerDelegate

- (void)adViewWillLogImpression:(UIView *)adView
{
    // Track impression for all impression trackers known by the SDK
    [self trackImpression];
    // Track impression for all impression trackers included in the markup
    [self.bannerCustomEvent trackImpressionsIncludedInMarkup];
    // Start viewability tracking
    [self.bannerCustomEvent startViewabilityTracker];
    
    // Notify delegate that an impression tracker was fired
    [self.delegate adapter:self didTrackImpressionForAd:adView];
}

@end
