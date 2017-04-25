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

+(void)performComicsRequestWithCount:(int)count
                               limit:(int)limit
                             orderBy:(NSString*)orderBy
                       sortOrderType:(SortOrderType)sortOrderType
                        successBlock:(ComicRequestSuccessBlock)successBlock
                        failureBlock:(ComicRequestFailureBlock)failureBlock {

    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:configuration];
    

    for (int offset = 0; offset < count; offset += limit) {

        NSMutableString* urlString = [NSMutableString stringWithFormat:@"%@%@?ts=%ld&apikey=%@&hash=%@", [NSString stringWithUTF8String:s_kMarvelBaseUrl], [NSString stringWithUTF8String:s_kMarvelComicsEndpoint], s_timestamp, [NSString stringWithUTF8String:s_kMarvelPublicKey], [MarvelClient digest]];
        
        if (limit > 0) {
            [urlString appendFormat:@"&limit=%i", limit];
        }
        if (orderBy) {
            if (sortOrderType == Descending) {
                [urlString appendFormat:@"&orderBy=-%@", orderBy];
            } else {
                [urlString appendFormat:@"&orderBy=%@", orderBy];
            }
        }
        
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
        [request setHTTPMethod:@"GET"];
        [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@&offset=%i", urlString, offset]]];

        NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                                                    
                                                    if (error) {
                                                        
                                                        if (failureBlock) {
                                                            failureBlock(error);
                                                        }
                                                        
                                                    } else {
                                                        
                                                        if (successBlock) {
                                                            
                                                            NSError* error = nil;
                                                            
                                                            id jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                                                            if ([jsonData isKindOfClass:[NSDictionary class]]) {
                                                                
                                                                if (successBlock) {
                                                                    successBlock(jsonData[@"data"], response);
                                                                }
                                                            } else {
                                                                
                                                                if (failureBlock) {
                                                                    failureBlock([MarvelClient errorWithCode:-1
                                                                                                      reason:@"Returned object is not a dictionary"]);
                                                                }
                                                            }
                                                        }
                                                        
                                                    }
                                                    
                                                }];
        
        [task resume];

        ++s_timestamp;
}
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
