//
//  MarvelSession.h
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "WebRequest.h"

typedef void(^ComicRequestSuccessBlock)(NSDictionary* data, NSURLResponse* response);

typedef NS_ENUM(NSInteger, SortType) {
    
    Ascending = 0,
    
    Descending
    
};

extern NSString* const kOrderByFocDate;
extern NSString* const kOrderByOnSaleDate;
extern NSString* const kOrderByTitle;
extern NSString* const kOrderByIssueNumber;
extern NSString* const kOrderByModified;

@interface MarvelClient : NSObject

+(void)performComicsRequest:(int)offset
                      limit:(int)limit
                    orderBy:(NSString*)orderBy
                   sortType:(SortType)sortType
               successBlock:(ComicRequestSuccessBlock)successBlock
               failureBlock:(WebRequestFailureBlock)failureBlock;

@end
