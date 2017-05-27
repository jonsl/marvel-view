//
// Created by Jonathan Slater on 27/05/2017.
// Copyright (c) 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MarvelApiClient

@required

-(void)requestComicsWithOffset:(int)offset
                         count:(int)count
                  successBlock:(void (^)(NSDictionary* data, NSURLResponse* response))successBlock
                  failureBlock:(void (^)(NSError*))failureBlock;

@optional

@end
