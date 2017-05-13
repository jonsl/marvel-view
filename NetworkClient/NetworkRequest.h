//
//  NetworkRequest.h
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RequestCompletionBlock)(NSData* data, NSURLResponse* response, NSError* error);

@interface NetworkRequest : NSOperation

-(instancetype)initWithUrl:(NSURL*)url
                httpMethod:(NSString*)httpMethod
                  userInfo:(NSDictionary*)userInfo
                completion:(RequestCompletionBlock)completion;

@property (nonatomic, strong) NSURLRequest* request;

@property (nonatomic, assign) int requestCount;

//@property (nonatomic, strong) NSOperationQueue* queue;

@property (nonatomic, strong) NSDictionary* userInfo;

@property (nonatomic, copy) RequestCompletionBlock completion;

@end
