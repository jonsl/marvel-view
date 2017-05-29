//
//  ApiRequest.m
//  ApiClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "ApiRequest.h"

static NSString* const kNetworkErrorDomain = @"NetworkErrorDomain";

@interface ApiRequest()

@property (nonatomic, copy) ApiRequestSuccess success;

@property (nonatomic, copy) ApiRequestFailure failure;

@end

@implementation ApiRequest

-(instancetype)initWithUrl:(NSURL*)url
                httpMethod:(NSString*)httpMethod
                   timeOut:(NSTimeInterval)timeOut
                  userInfo:(NSDictionary*)userInfo
                   success:(ApiRequestSuccess)success
                   failure:(ApiRequestFailure)failure {

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

                                                                     if (error) {

                                                                         NSLog(@"request %@ failed with error %@", self.request, error);

                                                                         if (self.failure) {
                                                                             self.failure(error);
                                                                         }
                                                                         
                                                                     } else {
                                                                         
                                                                         NSParameterAssert(data && response);
                                                                         NSParameterAssert([response isKindOfClass:[NSHTTPURLResponse class]]);

                                                                         NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
                                                                         
                                                                         NSError* jsonError = nil;
                                                                         id jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                       options:NSJSONReadingMutableContainers
                                                                                                                         error:&jsonError];
                                                                         
                                                                         if (jsonError || httpResponse.statusCode != 200) {
                                                                             
                                                                             NSError* requestError = [NSError errorWithDomain:kNetworkErrorDomain
                                                                                                                         code:httpResponse.statusCode
                                                                                                                     userInfo:jsonData];

                                                                             NSLog(@"request %@ failed with error %@", self.request, requestError);
                                                                             
                                                                             if (self.failure) {
                                                                                 self.failure(requestError);
                                                                             }

                                                                         } else {
                                                                             
                                                                             if (self.success) {
                                                                                 self.success(jsonData, response);
                                                                             }
                                                                         }
                                                                     }
                                                                    
                                                                     ++self.requestCount;

                                                                     dispatch_semaphore_signal(sem);
                                                                 }];

    [task resume];

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

@end
