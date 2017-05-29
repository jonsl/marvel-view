//
// Created by Jonathan Slater on 29/05/2017.
// Copyright (c) 2017 Jonathan Slater. All rights reserved.
//

#import "Observer.h"

@protocol Subject

-(void)addObserver:(NSObject<Observer>*)observer;

-(void)removeObserver:(NSObject<Observer>*)observer;

@end
