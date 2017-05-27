//
//  NetworkManager.h
//  NetworkClient
//
//  Created by Jonathan Slater on 13/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "NetworkRequestQueue.h"

@interface NetworkClient : NSObject

+(instancetype)sharedInstance;

@property (nonatomic, strong) NSString* remoteHostName;

@property (nonatomic, strong) NetworkRequestQueue* queue;

@end
