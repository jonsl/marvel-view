//
// Created by Jonathan Slater on 29/05/2017.
// Copyright (c) 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Observer

-(void)notify;

-(void)notifyWithError:(NSError*)error;

@end
