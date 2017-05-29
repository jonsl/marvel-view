//
//  ModelManager.h
//  marvel-view
//
//  Created by Jonathan Slater on 24/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "Subject.h"

extern int const kRequestCount;

@interface ModelManager : NSObject<Subject>

+(instancetype)sharedInstance;

-(void)requestComicWithOffset:(int)row;

-(void)clearData;

@property (readonly, nonatomic) NSUInteger comicsCount;

@end
