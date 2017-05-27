//
//  MarvelSession.m
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "MarvelClient.h"
#import "Extensions.h"
#import "NetworkClient.h"

//static NSTimeInterval const kRequestTimeout = 10.0;

static NSString* const NSMarvelClientErrorDomain = @"MarvelClientErrorDomain";

NSString* const kOrderByFocDate = @"focDate";
NSString* const kOrderByOnSaleDate = @"onsaleDate";
NSString* const kOrderByTitle = @"title";
NSString* const kOrderByIssueNumber = @"issueNumber";
NSString* const kOrderByModified = @"modified";

static char const* s_kMarvelBaseUrl = "https://gateway.marvel.com";
static char const* s_kMarvelPublicKey = "d2b30c8bb5eed39c59922fef1cbd1994";
static char const* s_kMarvelPrivateKey = "7ffe55d53a0635476808c96144380b23ba183448";

static char const* s_kMarvelComicsEndpoint = "/v1/public/comics";

static long s_timestamp = 1;


@implementation MarvelClient

+(int)performComicsRequestWithOffset:(int)offset
                               count:(int)count
                         requestSize:(int)requestSize
                             orderBy:(NSString*)orderBy
                       sortOrderType:(SortOrderType)sortOrderType
                        successBlock:(ComicRequestSuccessBlock)successBlock
                        failureBlock:(ComicRequestFailureBlock)failureBlock {

    int requestOffset = offset;
    for (; requestOffset < (offset + count); requestOffset += requestSize) {

        NSMutableString* urlString = [NSMutableString stringWithFormat:@"%@%@?ts=%ld&apikey=%@&hash=%@", [NSString stringWithUTF8String:s_kMarvelBaseUrl], [NSString stringWithUTF8String:s_kMarvelComicsEndpoint], s_timestamp, [NSString stringWithUTF8String:s_kMarvelPublicKey], [MarvelClient digest]];
        
        if (requestSize > 0) {
            [urlString appendFormat:@"&limit=%i", requestSize];
        }
        if (orderBy) {
            if (sortOrderType == Descending) {
                [urlString appendFormat:@"&orderBy=-%@", orderBy];
            } else {
                [urlString appendFormat:@"&orderBy=%@", orderBy];
            }
        }
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@&offset=%i", urlString, offset]];

        NetworkRequest* request = [[NetworkRequest alloc] initWithUrl:url
                                                           httpMethod:@"GET"
                                                             userInfo:nil
                                                              success:^(id data, NSURLResponse *response) {

                                                                  if ([data isKindOfClass:[NSDictionary class]]) {
                                                                      
                                                                      NSDictionary* comicData = data[@"data"];

                                                                      NSParameterAssert(comicData);
                                                                      
                                                                      if (successBlock) {
                                                                          successBlock(comicData, response);
                                                                      }
                                                                      
                                                                  }

                                                              }
                                                              failure:^(NSError *error) {
                                                                  
                                                                  if (failureBlock) {
                                                                      failureBlock(error);
                                                                  }
                                                                  
                                                              }];
        
        [[NetworkClient sharedInstance].queue addRequest:request];

        ++s_timestamp;
    }

    return requestOffset;
}

+(NSError*)errorWithCode:(NSInteger)code reason:(NSString*)reason {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, nil)
                               };
    return [NSError errorWithDomain:NSMarvelClientErrorDomain
                               code:code
                           userInfo:userInfo];
}

+(NSString*)digest {
    NSString* md5String = [NSString stringWithFormat:@"%ld%@%@", s_timestamp, [NSString stringWithUTF8String:s_kMarvelPrivateKey], [NSString stringWithUTF8String:s_kMarvelPublicKey]];
    return [md5String md5];
}

@end
