//
//  NetworkRequest.m
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "NetworkRequest.h"

static NSString* const kNetworkErrorErrorDomain = @"NetworkErrorErrorDomain";

@implementation NetworkRequest {
    
}

@synthesize ready = _ready;

@synthesize executing = _executing;

@synthesize finished = _finished;

-(instancetype)initWithUrl:(NSURL*)url
                httpMethod:(NSString*)httpMethod
                  userInfo:(NSDictionary*)userInfo
                completion:(RequestCompletionBlock)completion {

    if ((self = [super init])) {
        
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
        [request setHTTPMethod:httpMethod];
        [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
        [request setURL:url];
        
        self.request = request;
        self.userInfo = userInfo;
        self.completion = completion;
        
        self.ready = YES;
        
    }
    return self;
}

-(void)setReady:(BOOL)ready {
    
    if (_ready != ready) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
        _ready = ready;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    }
}

-(BOOL)isReady {
    return _ready;
}

-(void)setExecuting:(BOOL)executing {
    if (_executing != executing) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = executing;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    }
}

-(BOOL)isExecuting {
    return _executing;
}

-(void)setFinished:(BOOL)finished {
    if (_finished != finished) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = finished;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    }
}

-(BOOL)isFinished {
    return _finished;
}

-(void)start {
    if (!self.isExecuting) {
        self.ready = NO;
        self.executing = YES;
        self.finished = NO;
        
        NSLog(@"%@ operation started", self.name);
    }
    
    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:self.request
                                                                 completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                                                                     
                                                                     if (self.completionBlock) {
                                                                         self.completion(data, response, error);
                                                                     }
                                                                     
                                                                     [self finish];
                                                                     
                                                                 }];
    
    [task resume];

    ++self.requestCount;
    
}

-(void)finish {
    if (self.isExecuting) {
        self.executing = NO;
        self.finished = YES;
        
        NSLog(@"%@ operation finished", self.name);
    }
}

-(void)cancel {
    [super cancel];

    [self finish];
}

@end
