//
//  NetworkRequest.h
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RequestSuccessBlock)(id data, NSURLResponse* response);

typedef void (^RequestFailureBlock)(NSError* error);

@interface NetworkRequest : NSOperation

-(instancetype)initWithUrl:(NSURL*)url
                httpMethod:(NSString*)httpMethod
                  userInfo:(NSDictionary*)userInfo
                   success:(RequestSuccessBlock)success
                   failure:(RequestFailureBlock)failure;

@property (nonatomic, strong) NSURLRequest* request;

@property (nonatomic, assign) int requestCount;

@property (nonatomic, weak) NSOperationQueue* queue;

@property (nonatomic, strong) NSDictionary* userInfo;

@property (nonatomic, copy) RequestSuccessBlock success;

@property (nonatomic, copy) RequestFailureBlock failure;

@end
