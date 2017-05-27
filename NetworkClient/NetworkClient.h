//
//  NetworkManager.h
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "NetworkRequestQueue.h"

@interface NetworkClient : NSObject

-(instancetype)init;

-(void)addRequest:(NetworkRequest*)request;

@property (nonatomic, strong) NSString* remoteHostName;

@end
