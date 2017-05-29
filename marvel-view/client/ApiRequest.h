//
//  ApiRequest.h
//  ApiClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApiRequestQueue;

typedef void (^ApiRequestSuccess)(id data, NSURLResponse* response);

typedef void (^ApiRequestFailure)(NSError* error);

@interface ApiRequest : NSOperation

-(instancetype)initWithUrl:(NSURL*)url
                httpMethod:(NSString*)httpMethod
                   timeOut:(NSTimeInterval)timeOut
                  userInfo:(NSDictionary*)userInfo
                   success:(ApiRequestSuccess)success
                   failure:(ApiRequestFailure)failure;

@property (nonatomic, strong) NSURLRequest* request;

@property (nonatomic, assign) int requestCount;

@property (nonatomic, weak) ApiRequestQueue* queue;

@property (nonatomic, strong) NSDictionary* userInfo;

@end
