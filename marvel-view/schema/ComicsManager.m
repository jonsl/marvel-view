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

typedef void(^ComicRequestFailureBlock)(NSError* error);

typedef NS_ENUM(NSInteger, SortOrderType) {

    Ascending = 0,

    Descending

};

int const kRequestSize = 10;

NSString* kNewDataNotification = @"NewDataNotification";

static int const kRequestMultiple = 4;

//static NSTimeInterval const kRequestTimeout = 10.0;

static NSString* const NSMarvelClientErrorDomain = @"MarvelClientErrorDomain";

static char const* s_kMarvelBaseUrl = "https://gateway.marvel.com";
static char const* s_kMarvelPublicKey = "d2b30c8bb5eed39c59922fef1cbd1994";
static char const* s_kMarvelPrivateKey = "7ffe55d53a0635476808c96144380b23ba183448";

static char const* s_kMarvelComicsEndpoint = "/v1/public/comics";

static long s_timestamp = 1;

@interface ComicsManager()

@property (readonly, nonatomic) NSManagedObjectContext* mainManagedObjectContext;

@end

@implementation ComicsManager {
    NetworkClient* _networkClient;

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

        _networkClient = [[NetworkClient alloc] init];

    }
    return self;
}

-(void)updateRequestsForRow:(int)row {

    BOOL shouldRequest = _requestOffset < (row + (kRequestSize * kRequestMultiple));

    if (shouldRequest) {

        [self requestWithSize:kRequestSize
                 successBlock:^(NSDictionary* data, NSURLResponse* response) {

                     NSManagedObjectContext* temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                     temporaryContext.parentContext = self.mainManagedObjectContext;

                     NSParameterAssert(data);

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

                         //                                            [self presentViewController:alert animated:YES completion:nil];
                     });
                 }];

        NSLog(@"_requestOffset = %i, row = %i", _requestOffset, row);
    }

}

-(void)clear:(NSError**)error {
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

-(void)requestWithSize:(int)requestSize
          successBlock:(void (^)(NSDictionary* data, NSURLResponse* response))successBlock
          failureBlock:(void (^)(NSError*))failureBlock {

    NSMutableString* urlString = [NSMutableString stringWithFormat:@"%@%@?ts=%ld&apikey=%@&hash=%@", [NSString stringWithUTF8String:s_kMarvelBaseUrl], [NSString stringWithUTF8String:s_kMarvelComicsEndpoint], s_timestamp, [NSString stringWithUTF8String:s_kMarvelPublicKey], [self digest]];

    if (requestSize > 0) {
        [urlString appendFormat:@"&limit=%i", requestSize];
    }

    [urlString appendFormat:@"&orderBy=-onsaleDate&orderBy=title"];
    [urlString appendFormat:@"&offset=%i", _requestOffset];

    NetworkRequest* request = [[NetworkRequest alloc] initWithUrl:[NSURL URLWithString:urlString]
                                                       httpMethod:@"GET"
                                                         userInfo:nil
                                                          success:^(id data, NSURLResponse* response) {

                                                              if ([data isKindOfClass:[NSDictionary class]]) {

                                                                  NSDictionary* comicData = data[@"data"];
                                                                  NSAssert(comicData, @"invalid comic data");

                                                                  if (successBlock) {
                                                                      successBlock(comicData, response);
                                                                  }

                                                              }

                                                          }
                                                          failure:^(NSError* error) {

                                                              if (failureBlock) {
                                                                  failureBlock(error);
                                                              }

                                                          }];

    [_networkClient addRequest:request];

    ++s_timestamp;

    _requestOffset += requestSize;
}

-(NSString*)digest {
    NSString* md5String = [NSString stringWithFormat:@"%ld%@%@", s_timestamp, [NSString stringWithUTF8String:s_kMarvelPrivateKey], [NSString stringWithUTF8String:s_kMarvelPublicKey]];
    return [md5String md5];
}

-(NSManagedObjectContext*)mainManagedObjectContext {
    AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* context = appDelegate.persistentContainer.viewContext;
    NSParameterAssert(context);
    return context;
}

@end
