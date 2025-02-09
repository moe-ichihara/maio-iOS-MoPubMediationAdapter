//
//  MaioAdapterConfiguration.h
//  mopub.ObjectiveC
//
//  Created by Kasamatsu on 2019/04/17.
//  Copyright © 2019 maio. All rights reserved.
//

#import "MPBaseAdapterConfiguration.h"

@interface MaioAdapterConfiguration : MPBaseAdapterConfiguration

@property (nonatomic, copy, readonly) NSString * adapterVersion;
@property (nonatomic, copy, readonly) NSString * biddingToken;
@property (nonatomic, copy, readonly) NSString * moPubNetworkName;
@property (nonatomic, copy, readonly) NSString * networkSdkVersion;

@end
