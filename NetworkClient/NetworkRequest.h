//
//  NetworkRequest.h
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RequestSuccess)(id data, NSURLResponse* response);

typedef void (^RequestFailure)(NSError* error);

@interface NetworkRequest : NSOperation

-(instancetype)initWithUrl:(NSURL*)url
                httpMethod:(NSString*)httpMethod
                   timeOut:(NSTimeInterval)timeOut
                  userInfo:(NSDictionary*)userInfo
                   success:(RequestSuccess)success
                   failure:(RequestFailure)failure;

@property (nonatomic, strong) NSURLRequest* request;

@property (nonatomic, assign) int requestCount;

@property (nonatomic, weak) NSOperationQueue* queue;

@property (nonatomic, strong) NSDictionary* userInfo;

@property (nonatomic, copy) RequestSuccess success;

@property (nonatomic, copy) RequestFailure failure;

@end
