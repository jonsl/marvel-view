//
// Created by Jonathan Slater on 28/05/2017.
// Copyright (c) 2017 Jonathan Slater. All rights reserved.
//

#import "MarvelClient.h"
#import "ApiRequestQueue.h"
#import "ApiRequest.h"
#import "Reachability.h"
#import "Extensions.h"

static NSTimeInterval const kRequestTimeout = 10.0;

static NSString* kMarvelClientErrorDomain = @"MarvelClientErrorDomain";

static NSString* kMarvelBaseUrl = @"https://gateway.marvel.com";

static long ApiTmestamp = 1;

static NSString* kMarvelPublicKey = @"d2b30c8bb5eed39c59922fef1cbd1994";

static NSString* kMarvelPrivateKey = @"7ffe55d53a0635476808c96144380b23ba183448";

static NSString* kMarvelComicsEndpoint = @"/v1/public/comics";

@interface MarvelClient()

@property (nonatomic, strong) Reachability* reachability;

@property (nonatomic, strong) ApiRequestQueue* requestQueue;

@end

@implementation MarvelClient

-(instancetype)init {
    if ((self = [super init])) {

        // observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

        self.reachability = [Reachability reachabilityWithHostName:kMarvelBaseUrl];
        [self.reachability startNotifier];
        [self updateReachability:self.reachability];

        self.requestQueue = [[ApiRequestQueue alloc] init];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

-(void)requestComicsWithOffset:(int)offset
                         count:(int)count
                  successBlock:(void (^)(NSDictionary* data, NSURLResponse* response))successBlock
                  failureBlock:(void (^)(NSError*))failureBlock {
    
    NSMutableString* urlString = [NSMutableString stringWithFormat:@"%@%@?ts=%ld&apikey=%@&hash=%@", kMarvelBaseUrl, kMarvelComicsEndpoint, ApiTmestamp, kMarvelPublicKey, [self digest]];

    // set parameters
    if (count > 0) {
        [urlString appendFormat:@"&limit=%i", count];
    }
    [urlString appendFormat:@"&orderBy=-onsaleDate&orderBy=title"];
    [urlString appendFormat:@"&offset=%i", offset];

    ApiRequest* request = [[ApiRequest alloc] initWithUrl:[NSURL URLWithString:urlString]
                                               httpMethod:@"GET"
                                                  timeOut:kRequestTimeout
                                                 userInfo:nil
                                                  success:^(id data, NSURLResponse* response) {

                                                      NSDictionary* comicData = data[@"data"];

                                                      if (comicData && [data isKindOfClass:[NSDictionary class]]) {

                                                          if (successBlock) {
                                                              successBlock(comicData, response);
                                                          }

                                                      } else {

                                                          NSError* requestError = [NSError errorWithDomain:kMarvelClientErrorDomain
                                                                                                      code:-1
                                                                                                  userInfo:@{@"reason": @"invalid data"}];

                                                          if (failureBlock) {
                                                              failureBlock(requestError);
                                                          }
                                                      }
                                                  }
                                                  failure:^(NSError* error) {

                                                      if (failureBlock) {
                                                          failureBlock(error);
                                                      }
                                                  }];

    [self.requestQueue addOperation:request];

    ++ApiTmestamp;
}

// Called by Reachability whenever status changes
-(void)reachabilityChanged:(NSNotification*)notification {
    Reachability* reachability = [notification object];
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    [self updateReachability:reachability];
}

-(void)updateReachability:(Reachability*)reachability {
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    BOOL connectionRequired = [reachability connectionRequired];

    switch (networkStatus) {
        case NotReachable: {
            //            self.queue.suspended = YES;
            break;
        }
        case ReachableViaWiFi: {
            break;
        }
        case ReachableViaWWAN: {
            break;
        }
    }

//    if (connectionRequired)
//    {
//        baseLabelText = NSLocalizedString(@"Cellular data network is available.\nInternet traffic will be routed through it after a connection is established.", @"Reachability text if a connection is required");
//    }
//    else
//    {
//        baseLabelText = NSLocalizedString(@"Cellular data network is active.\nInternet traffic will be routed through it.", @"Reachability text if a connection is not required");
//    }
}

-(NSString*)digest {
    NSString* md5String = [NSString stringWithFormat:@"%ld%@%@", ApiTmestamp, kMarvelPrivateKey, kMarvelPublicKey];
    return [md5String md5];
}

@end
