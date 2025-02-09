//
//  MPNativeCustomEvent.m
//
//  Copyright 2018-2019 Twitter, Inc.
//  Licensed under the MoPub SDK License Agreement
//  http://www.mopub.com/legal/sdk-license-agreement/
//

#import "MPNativeCustomEvent.h"
#import "MPNativeAdError.h"
#import "MPImageDownloadQueue.h"
#import "MPLogging.h"

@interface MPNativeCustomEvent ()

@property (nonatomic, strong) MPImageDownloadQueue *imageDownloadQueue;

@end

@implementation MPNativeCustomEvent

- (id)init
{
    self = [super init];
    if (self) {
        _imageDownloadQueue = [[MPImageDownloadQueue alloc] init];
    }
    
    return self;
}

- (void)precacheImagesWithURLs:(NSArray *)imageURLs completionBlock:(void (^)(NSArray *errors))completionBlock
{
    if (imageURLs.count > 0) {
        [_imageDownloadQueue addDownloadImageURLs:imageURLs completionBlock:^(NSArray *errors) {
            if (completionBlock) {
                completionBlock(errors);
            }
        }];
    } else {
        if (completionBlock) {
            completionBlock(nil);
        }
    }
}

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info
{
    /*override with custom network behavior*/
}

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup
{
    // By default, the original requestAdWithCustomEventInfo: method will be called.
    // Otherwise subclasses must override this method and implement code to load a banner here.
    [self requestAdWithCustomEventInfo:info];
}

@end
