//
//  DatabaseManager.h
//  marvel-view
//
//  Created by Jonathan Slater on 24/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DatabaseManager : NSObject

+(DatabaseManager*)sharedManager;

-(void)clear:(NSError**)error;

-(NSManagedObject*)insertNewComicEntityFromDictionary:(NSDictionary*)comic
                                 managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@property (readonly, nonatomic) NSManagedObjectContext* mainManagedObjectContext;

@property (readonly, nonatomic) NSUInteger comicsCount;

@end
