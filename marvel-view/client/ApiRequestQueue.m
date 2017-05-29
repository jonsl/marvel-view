//
//  ApiRequestQueue.m
//  ApiClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "ApiRequestQueue.h"
#import "ApiRequest.h"

@implementation ApiRequestQueue

-(instancetype)init {
    if ((self = [super init])) {

        self.maxConcurrentOperationCount = 1;

    }
    return self;
}

-(void)setSuspended:(BOOL)suspended {
    [super setSuspended:suspended];

}

-(void)addOperation:(NSOperation*)op {

    NSParameterAssert([op isKindOfClass:[ApiRequest class]]);

    [super addOperation:op];

    ((ApiRequest*) op).queue = self;
}

@end
