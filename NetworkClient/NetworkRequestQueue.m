//
//  NetworkRequestQueue.m
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "NetworkRequestQueue.h"

@implementation NetworkRequestQueue

-(instancetype)init {
    if ((self = [super init])) {
        
        self.maxConcurrentOperationCount = 1;
        
    }
    return self;
}

-(void)dealloc {
    for (NetworkRequest* request in [self operations]) {
        request.queue = nil;
    }
}

-(void)setSuspended:(BOOL)suspended {
    [super setSuspended:suspended];
    
}

-(void)addRequest:(NetworkRequest*)request {
    [self addOperation:request];
}

- (void)addOperation:(NSOperation *)op {
    
    NSAssert([op isKindOfClass:[NetworkRequest class]], @"invalid request added to queue");
    
    [super addOperation:op];
    
    ((NetworkRequest*)op).queue = self;
}

@end
