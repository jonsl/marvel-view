//
//  NetworkManager.m
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "NetworkClient.h"
#import "Reachability.h"

@interface NetworkClient()

@property (nonatomic) Reachability* reachability;

@end

@implementation NetworkClient

+(instancetype)sharedInstance {
    static NetworkClient* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        instance = [[NetworkClient alloc] init];
        
    });
    return instance;
}

-(instancetype)init {
    if ((self = [super init])) {
        
        self.queue = [[NetworkRequestQueue alloc] init];

        /*
         observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
         */
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

        self.reachability = [Reachability reachabilityForInternetConnection];
        [self.reachability startNotifier];
        [self updateReachability:self.reachability];
    }
    return self;
}

-(void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
}

-(void)setRemoteHostName:(NSString *)remoteHostName {
    if (_remoteHostName != remoteHostName) {
        self.reachability = [Reachability reachabilityWithHostName:remoteHostName];
        [self.reachability startNotifier];
        [self updateReachability:self.reachability];
    }
}

/*
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification*)notification {
    Reachability* reachability = [notification object];
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    [self updateReachability:reachability];
}

-(void)updateReachability:(Reachability*)reachability {
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    BOOL connectionRequired = [reachability connectionRequired];

        if (connectionRequired)
        {
//            baseLabelText = NSLocalizedString(@"Cellular data network is available.\nInternet traffic will be routed through it after a connection is established.", @"Reachability text if a connection is required");
        }
        else
        {
//            baseLabelText = NSLocalizedString(@"Cellular data network is active.\nInternet traffic will be routed through it.", @"Reachability text if a connection is not required");
        }
}

@end
