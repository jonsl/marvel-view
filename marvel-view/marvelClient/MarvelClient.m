//
//  MarvelSession.m
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "MarvelClient.h"
#import "Extensions.h"

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

+(void)performComicsRequest:(WebRequestSuccessBlock)successBlock failureBlock:(WebRequestFailureBlock)failureBlock {

    NSString* urlString = [NSString stringWithFormat:@"%@%@?ts=%ld&apikey=%@&hash=%@", [NSString stringWithUTF8String:s_kMarvelBaseUrl], [NSString stringWithUTF8String:s_kMarvelComicsEndpoint], s_timestamp, [NSString stringWithUTF8String:s_kMarvelPublicKey], [MarvelClient digest]];

    [WebRequest performRequest:[NSURL URLWithString:urlString]
                    httpMethod:@"GET"
                        header:nil
                          body:nil
                  successBlock:^(NSData *data, NSURLResponse *response) {
        
        if (successBlock) {
            successBlock(data, response);
        }
        
    } failureBlock:^(NSError *error) {
        
        if (failureBlock) {
            failureBlock(error);
        }
        
    }];

    ++s_timestamp;
}

@end
