//
//  ComicsManager.h
//  marvel-view
//
//  Created by Jonathan Slater on 24/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ComicsManager.h"

extern int const kRequestSize;

extern NSString* kNewDataNotification;

@interface ComicsManager : NSObject

+(instancetype)sharedInstance;

-(void)updateRequestsForRow:(int)row;

-(void)clear:(NSError**)error;

@property (readonly, nonatomic) NSUInteger comicsCount;

@end
