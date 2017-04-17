//
//  webClient.m
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "WebRequest.h"

@implementation WebRequest {

}

+(void)performRequest:(NSURL*)url
           httpMethod:(NSString*)httpMethod
               header:(NSDictionary*)header
                 body:(NSData*)body
         successBlock:(WebRequestSuccessBlock)successBlock
         failureBlock:(WebRequestFailureBlock)failureBlock {

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy   // use etag transparently
                                                       timeoutInterval:60];

    [request setHTTPMethod:httpMethod];

    for (NSString* key in header) {
        [request setValue:[header objectForKey:key] forHTTPHeaderField:key];
    }
    [request setHTTPBody:body];

    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    configuration.HTTPAdditionalHeaders = header;

    NSURLSession* session = [NSURLSession sessionWithConfiguration:configuration];

    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {

                                                if (error) {

                                                    if (failureBlock) {
                                                        failureBlock(error);
                                                    }

                                                } else {

                                                    if (successBlock) {
                                                        
                                                        NSError* error = nil;
                                                        
                                                        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                                        
                                                        successBlock(json, response);
                                                    }

                                                }

                                            }];

    [task resume];
}

@end
