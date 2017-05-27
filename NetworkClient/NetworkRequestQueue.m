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

-(void)setSuspended:(BOOL)suspended {
    [super setSuspended:suspended];
    
}

-(void)addOperation:(NSOperation *)op {
    
    NSParameterAssert([op isKindOfClass:[NetworkRequest class]]);
    
    [super addOperation:op];
    
    ((NetworkRequest*)op).queue = self;
}

@end
