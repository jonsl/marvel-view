//
//  MarvelSession.h
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "WebRequest.h"

@interface MarvelClient : NSObject

+(void)performComicsRequest:(WebRequestSuccessBlock)successBlock failureBlock:(WebRequestFailureBlock)failureBlock;

@end
