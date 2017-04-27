//
//  MarvelSession.h
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ComicRequestSuccessBlock)(NSDictionary* data, NSURLResponse* response);

typedef void(^ComicRequestFailureBlock)(NSError* error);

typedef NS_ENUM(NSInteger, SortOrderType) {
    
    Ascending = 0,
    
    Descending
    
};

extern NSString* const kOrderByFocDate;
extern NSString* const kOrderByOnSaleDate;
extern NSString* const kOrderByTitle;
extern NSString* const kOrderByIssueNumber;
extern NSString* const kOrderByModified;

@interface MarvelClient : NSObject

+(int)performComicsRequestWithOffset:(int)offset
                               count:(int)count
                         requestSize:(int)requestSize
                             orderBy:(NSString*)orderBy
                       sortOrderType:(SortOrderType)sortOrderType
                        successBlock:(ComicRequestSuccessBlock)successBlock
                        failureBlock:(ComicRequestFailureBlock)failureBlock;

@end
