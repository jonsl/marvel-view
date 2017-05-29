//
//  ModelManager.m
//  marvel-view
//
//  Created by Jonathan Slater on 24/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "AppDelegate.h"
#import "ModelManager.h"
#import "Comic+CoreDataProperties.h"
#import "MarvelClient.h"

static NSString* kModelManagerErrorDomain = @"ModelManagerErrorDomain";

int const kRequestCount = 10;

static int const kRequestMultiple = 4;

@interface ModelManager()

@property (readonly, nonatomic) NSManagedObjectContext* mainManagedObjectContext;

@end

@implementation ModelManager {

    NSMutableArray<NSObject<Observer>*>* _observers;

    MarvelClient* _marvelClient;

    int _requestOffset;

}

+(instancetype)sharedInstance {
    static ModelManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ModelManager alloc] init];
    });
    return instance;
}

-(instancetype)init {
    if ((self = [super init])) {
        _marvelClient = [[MarvelClient alloc] init];
    }
    return self;
}

-(void)requestComicWithOffset:(int)row {

    BOOL shouldRequest = _requestOffset < (row + (kRequestCount * kRequestMultiple));

    if (shouldRequest) {

        [_marvelClient requestComicsWithOffset:_requestOffset
                                         count:kRequestCount
                                  successBlock:^(NSDictionary* data, NSURLResponse* response) {

                                      [self insertNewComicsFromDictionary:data];

                                  }
                                  failureBlock:^(NSError* error) {

                                      _requestOffset -= kRequestCount;

                                      [self notifyWithError:error];

                                  }];

        _requestOffset += kRequestCount;

        NSLog(@"_requestOffset = %i, row = %i", _requestOffset, row);
    }
}

-(void)clearData {
    [self.mainManagedObjectContext performBlockAndWait:^{

        NSFetchRequest* fetchRequest = [Comic fetchRequest];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Comic"
                                            inManagedObjectContext:self.mainManagedObjectContext]];
        [fetchRequest setIncludesPropertyValues:NO];

        NSError* error = nil;

        NSArray* comics = [self.mainManagedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!error) {
            for (NSManagedObject* comic in comics) {
                [self.mainManagedObjectContext deleteObject:comic];
            }
            if ([self.mainManagedObjectContext save:&error]) {
                [self notify];
            } else {
                [self notifyWithError:error];
            }
        } else {
            [self notifyWithError:error];
        }
    }];
}

-(NSUInteger)comicsCount {
    NSFetchRequest* fetchRequest = [Comic fetchRequest];
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setIncludesSubentities:NO];

    NSError* error = nil;
    NSUInteger count = [self.mainManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    if (count == NSNotFound) {
        NSLog(@"comicsCount: NSNotFound, %@", error);
        return 0;
    }
    return count;
}

-(NSManagedObjectContext*)mainManagedObjectContext {
    AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* context = appDelegate.persistentContainer.viewContext;
    NSParameterAssert(context);
    return context;
}

-(void)insertNewComicsFromDictionary:(NSDictionary*)dictionary {
    NSManagedObjectContext* temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.mainManagedObjectContext;
    
    [temporaryContext performBlock:^{
        
        NSArray* comics = dictionary[@"results"];
        if (comics) {
            /*
             * add new comic entities to temporary
             */
            for (NSDictionary* comic in comics) {
                [self insertNewComicEntityFromDictionary:comic managedObjectContext:temporaryContext];
            }
            
            /*
             * save temporary back into main and save main
             */
            __block NSError* error = nil;
            if ([temporaryContext save:&error]) {
                
                [self.mainManagedObjectContext performBlock:^{
                    
                    if ([self.mainManagedObjectContext save:&error]) {
                        [self notify];
                    } else {
                        [self notifyWithError:error];
                    }
                    
                }];
                
            } else {
                [self notifyWithError:error];
            }
        } else {
            NSError* error = [NSError errorWithDomain:kModelManagerErrorDomain
                                                 code:-1
                                             userInfo:@{@"reason": @"invalid data"}];
            [self notifyWithError:error];
        }
    }];
}

-(NSManagedObject*)insertNewComicEntityFromDictionary:(NSDictionary*)comic
                                 managedObjectContext:(NSManagedObjectContext*)managedObjectContext {

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

-(void)notify {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSObject<Observer>* observer in _observers) {
            [observer notify];
        }
    });
}

-(void)notifyWithError:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSObject<Observer>* observer in _observers) {
            [observer notifyWithError:error];
        }
    });
}

#pragma mark - Subject

-(void)addObserver:(NSObject<Observer>*)observer {
    if (!_observers) {
        _observers = [NSMutableArray array];
    }
    [_observers addObject:observer];
}

-(void)removeObserver:(NSObject<Observer>*)observer {
    [_observers removeObject:observer];
}

@end
