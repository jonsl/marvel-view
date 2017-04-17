//
//  MarvelSession.m
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "MarvelClient.h"
#import "Extensions.h"

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

+(NSString*)digest {
    NSString* md5String = [NSString stringWithFormat:@"%ld%@%@", s_timestamp, [NSString stringWithUTF8String:s_kMarvelPrivateKey], [NSString stringWithUTF8String:s_kMarvelPublicKey]];
    return [md5String md5];
}

+(void)performComicsRequest:(int)offset
                      limit:(int)limit
                    orderBy:(NSString*)orderBy
                   sortType:(SortType)sortType
               successBlock:(ComicRequestSuccessBlock)successBlock
               failureBlock:(WebRequestFailureBlock)failureBlock {

    NSMutableString* urlString = [NSMutableString stringWithFormat:@"%@%@?ts=%ld&apikey=%@&hash=%@", [NSString stringWithUTF8String:s_kMarvelBaseUrl], [NSString stringWithUTF8String:s_kMarvelComicsEndpoint], s_timestamp, [NSString stringWithUTF8String:s_kMarvelPublicKey], [MarvelClient digest]];

    if (offset > 0) {
        [urlString appendFormat:@"&offset=%i", offset];
    }
    
    if (limit > 0) {
        [urlString appendFormat:@"&limit=%i", limit];
    }
    if (orderBy) {
        if (sortType == Descending) {
            [urlString appendFormat:@"&orderBy=-%@", orderBy];
        } else {
            [urlString appendFormat:@"&orderBy=%@", orderBy];
        }
    }

    [WebRequest performRequest:[NSURL URLWithString:urlString]
                    httpMethod:@"GET"
                        header:nil
                          body:nil
                  successBlock:^(id data, NSURLResponse* response) {
                      
                      if ([data isKindOfClass:[NSDictionary class]]) {
                          
                          if (successBlock) {
                              successBlock(data, response);
                          }
                      } else {
                          
                          if (failureBlock) {
                              failureBlock([MarvelClient errorWithCode:-1
                                                                reason:@"Returned object is not a dictionary"]);
                          }
                      }


                  } failureBlock:^(NSError* error) {

                if (failureBlock) {
                    failureBlock(error);
                }

            }];

    ++s_timestamp;
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

@end
