//
//  ComicsManager.m
//  marvel-view
//
//  Created by Jonathan Slater on 24/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "AppDelegate.h"
#import <NetworkClient.h>
#import "ComicsManager.h"
#import "Comic+CoreDataProperties.h"
#import "Extensions.h"
#import "MarvelClient.h"

int const kRequestCount = 10;

NSString* kNewDataNotification = @"NewDataNotification";

static int const kRequestMultiple = 4;

@interface ComicsManager()

@property (readonly, nonatomic) NSManagedObjectContext* mainManagedObjectContext;

@end

@implementation ComicsManager {
    MarvelClient* _marvelClient;

    int _requestOffset;

}

+(instancetype)sharedInstance {
    static ComicsManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ComicsManager alloc] init];
    });
    return instance;
}

-(instancetype)init {
    if ((self = [super init])) {

        _marvelClient = [[MarvelClient alloc] init];

    }
    return self;
}

-(void)updateRequestsForRow:(int)row {

    BOOL shouldRequest = _requestOffset < (row + (kRequestCount * kRequestMultiple));

    if (shouldRequest) {

        [_marvelClient requestComicsWithOffset:_requestOffset
                                         count:kRequestCount
                                  successBlock:^(NSDictionary* data, NSURLResponse* response) {

                                      NSParameterAssert(data);
                                      
                                      NSManagedObjectContext* temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                                      temporaryContext.parentContext = self.mainManagedObjectContext;

                                      [temporaryContext performBlock:^{

                                          NSArray* comics = data[@"results"];

                                          for (NSDictionary* comic in comics) {
                                              [self insertNewComicEntityFromDictionary:comic managedObjectContext:temporaryContext];
                                          }

                                          NSError* error = nil;
                                          if (![temporaryContext save:&error]) {

                                              NSLog(@"newDataNotification: temp context save error: %@", [error description]);
                                          }

                                          [self.mainManagedObjectContext performBlock:^{

                                              NSError* error = nil;
                                              if (![self.mainManagedObjectContext save:&error]) {

                                                  NSLog(@"newDataNotification: main context save error: %@", [error description]);

                                              }

                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:kNewDataNotification
                                                                                                      object:self
                                                                                                    userInfo:data];
                                              });

                                          }];

                                      }];
                                  }
                                  failureBlock:^(NSError* error) {

                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          NSString* message = [NSString stringWithFormat:@"%@:%@", error.localizedDescription, error.userInfo];
                                          UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Network Error"
                                                                                                         message:message
                                                                                                  preferredStyle:UIAlertControllerStyleAlert];

                                          UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK"
                                                                                       style:UIAlertActionStyleDefault
                                                                                     handler:^(UIAlertAction* action) {

                                                                                         [alert dismissViewControllerAnimated:YES completion:nil];

                                                                                     }];

                                          [alert addAction:ok];

//                                          [self presentViewController:alert animated:YES completion:nil];
                                      });
                                  }];

        _requestOffset += kRequestCount;

        NSLog(@"_requestOffset = %i, row = %i", _requestOffset, row);
    }
}

-(void)clearData:(NSError**)error {
    [self.mainManagedObjectContext performBlockAndWait:^void(void) {

        NSFetchRequest* fetchRequest = [Comic fetchRequest];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Comic"
                                            inManagedObjectContext:self.mainManagedObjectContext]];
        [fetchRequest setIncludesPropertyValues:NO];

        NSArray* comics = [self.mainManagedObjectContext executeFetchRequest:fetchRequest error:error];
        if (error && *error) {
            return;
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
        NSLog(@"ComicsManager: comicsCount: error: %@", [error description]);
        return 0;
    }
    if (count == NSNotFound) {
        NSLog(@"ComicsManager: comicsCount: NSNotFound");
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

-(NSManagedObjectContext*)mainManagedObjectContext {
    AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* context = appDelegate.persistentContainer.viewContext;
    NSParameterAssert(context);
    return context;
}

@end
