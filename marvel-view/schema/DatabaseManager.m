//
//  DatabaseManager.m
//  marvel-view
//
//  Created by Jonathan Slater on 24/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "DatabaseManager.h"
#import "AppDelegate.h"
#import "Comic+CoreDataProperties.h"

@implementation DatabaseManager

+(DatabaseManager*)sharedManager {
    static DatabaseManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        instance = [[DatabaseManager alloc] init];
        
    });
    
    return instance;
}

-(NSManagedObjectContext*)mainManagedObjectContext {
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* context = appDelegate.persistentContainer.viewContext;
    NSParameterAssert(context);
    return context;
}

-(void)clear:(NSError**)error {
    [self.mainManagedObjectContext performBlockAndWait: ^void(void) {

        NSFetchRequest* fetchRequest = [Comic fetchRequest];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Comic"
                                            inManagedObjectContext:self.mainManagedObjectContext]];
        [fetchRequest setIncludesPropertyValues:NO];

        NSArray* comics = [self.mainManagedObjectContext executeFetchRequest:fetchRequest error:error];
        if (error && *error) {
            return ;
        }
        
        for (NSManagedObject* comic in comics) {
            
            [self.mainManagedObjectContext deleteObject:comic];
            
        }
        [self.mainManagedObjectContext save:error];
    }];
}

-(NSUInteger)comicsCount {
    NSFetchRequest* fetchRequest = [Comic fetchRequest];
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setIncludesSubentities:NO];
    
    NSError* error = nil;
    NSUInteger count = [self.mainManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"DatabaseManager: comicsCount: error: %@", [error description]);
        return 0;
    }
    if (count == NSNotFound) {
        NSLog(@"DatabaseManager: comicsCount: NSNotFound");
        return 0;
    }
    return count;
}

-(NSManagedObject*)insertNewComicEntityFromDictionary:(NSDictionary*)comic managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    NSManagedObject* entity = [NSEntityDescription insertNewObjectForEntityForName:@"Comic" inManagedObjectContext:managedObjectContext];

    if (comic[@"description"] != [NSNull null]) {
        [entity setValue:comic[@"description"] forKey:@"desc"];
    }
    if (comic[@"id"] != [NSNull null]) {
        [entity setValue:[comic[@"id"] stringValue] forKey:@"uniqueId"];
    }
    if (comic[@"thumbnail"] != [NSNull null]) {
        NSDictionary* thumbnail = comic[@"thumbnail"];
        NSString* thumbnailUrl = [NSString stringWithFormat:@"%@.%@", thumbnail[@"path"], thumbnail[@"extension"]];
        [entity setValue:thumbnailUrl forKey:@"thumbnail"];
    }
    
    if (comic[@"title"] != [NSNull null]) {
        [entity setValue:comic[@"title"] forKey:@"title"];
    }
    for (NSDictionary* date in comic[@"dates"]) {
        if ([date[@"type"] isEqualToString:@"onsaleDate"]) {
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"YYYY-MM-dd\'T\'HH:mm:ssZZZZZ"];
            NSDate* onSaleDate = [df dateFromString:date[@"date"]];
            [entity setValue:onSaleDate forKey:@"onSaleDate"];
            break;
        }
    }
    return entity;
}

@end
