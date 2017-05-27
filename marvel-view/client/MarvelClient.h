//
// Created by Jonathan Slater on 28/05/2017.
// Copyright (c) 2017 Jonathan Slater. All rights reserved.
//

#import "MarvelApiClient.h"

@interface MarvelClient : NSObject<MarvelApiClient>

-(void)requestComicsWithOffset:(int)offset
                         count:(int)count
                  successBlock:(void (^)(NSDictionary* data, NSURLResponse* response))successBlock
                  failureBlock:(void (^)(NSError*))failureBlock;

@end
