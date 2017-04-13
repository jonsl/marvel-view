//
//  webClient.h
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^WebRequestSuccessBlock)(NSData* data, NSURLResponse* response);

typedef void (^WebRequestFailureBlock)(NSError* error);

@interface WebRequest : NSObject

+(void)performRequest:(NSURL*)url
           httpMethod:(NSString*)httpMethod
               header:(NSDictionary*)header
                 body:(NSDictionary*)body
         successBlock:(WebRequestSuccessBlock)successBlock
         failureBlock:(WebRequestFailureBlock)failureBlock;

@end
