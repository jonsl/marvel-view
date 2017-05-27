//
//  NetworkRequest.m
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "NetworkRequest.h"
#import "NetworkClient.h"

static NSString* const kNetworkErrorDomain = @"NetworkErrorErrorDomain";

@implementation NetworkRequest

-(instancetype)initWithUrl:(NSURL*)url
                httpMethod:(NSString*)httpMethod
                   timeOut:(NSTimeInterval)timeOut
                  userInfo:(NSDictionary*)userInfo
                   success:(RequestSuccess)success
                   failure:(RequestFailure)failure {

    if ((self = [super init])) {

        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
        [request setHTTPMethod:httpMethod];
        [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
        [request setURL:url];
        if (timeOut > 0) {
            [request setTimeoutInterval:timeOut];
        }

        self.request = request;
        self.userInfo = userInfo;
        self.success = success;
        self.failure = failure;

    }
    return self;
}

-(void)main {

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:self.request
                                                                 completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {

                                                                     NSParameterAssert([response isKindOfClass:[NSHTTPURLResponse class]]);
                                                                     NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;

                                                                     NSError* jsonError = nil;
                                                                     id jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                   options:NSJSONReadingMutableContainers
                                                                                                                     error:&jsonError];

                                                                     if (error || jsonError || httpResponse.statusCode != 200) {

                                                                         NSError* requestError = error != nil ? error : [NSError errorWithDomain:kNetworkErrorDomain
                                                                                                                                            code:httpResponse.statusCode
                                                                                                                                        userInfo:jsonData];
                                                                         NSLog(@"error: %@", requestError);

                                                                         if (self.failure) {
                                                                             self.failure(requestError);
                                                                         }

                                                                     } else {

                                                                         if (self.success) {
                                                                             self.success(jsonData, response);
                                                                         }
                                                                     }

                                                                     ++self.requestCount;

                                                                     dispatch_semaphore_signal(sem);
                                                                 }];

    [task resume];

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

@end
