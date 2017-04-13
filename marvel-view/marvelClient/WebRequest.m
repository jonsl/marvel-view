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

    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];

    request.HTTPMethod = httpMethod;

    for (NSString* key in header) {
        [request setValue:[header objectForKey:key] forHTTPHeaderField:key];
    }
    [request setHTTPBody:body];

    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    configuration.HTTPAdditionalHeaders = header;
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (error) {
            
            if (failureBlock) {
                failureBlock(error);
            }
            
        } else {
            
            if (successBlock) {
                successBlock(data, response);
            }

        }
        
    }];

    [task resume];
}

@end
