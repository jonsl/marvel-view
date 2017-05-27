//
// Created by Jonathan Slater on 28/05/2017.
// Copyright (c) 2017 Jonathan Slater. All rights reserved.
//

#import "NetworkClient.h"
#import "MarvelClient.h"
#import "Extensions.h"

static NSTimeInterval const kRequestTimeout = 10.0;

static NSString* const kMarvelClientErrorDomain = @"MarvelClientErrorDomain";

static char const* s_kMarvelBaseUrl = "https://gateway.marvel.com";
static char const* s_kMarvelPublicKey = "d2b30c8bb5eed39c59922fef1cbd1994";
static char const* s_kMarvelPrivateKey = "7ffe55d53a0635476808c96144380b23ba183448";
static char const* s_kMarvelComicsEndpoint = "/v1/public/comics";

static long s_timestamp = 1;

@implementation MarvelClient {

    NetworkClient* _networkClient;

}

-(instancetype)init {
    if ((self = [super init])) {
        _networkClient = [[NetworkClient alloc] init];
    }
    return self;
}

-(NSString*)digest {
    NSString* md5String = [NSString stringWithFormat:@"%ld%@%@", s_timestamp, [NSString stringWithUTF8String:s_kMarvelPrivateKey], [NSString stringWithUTF8String:s_kMarvelPublicKey]];
    return [md5String md5];
}

-(void)requestComicsWithOffset:(int)offset
                         count:(int)count
                  successBlock:(void (^)(NSDictionary* data, NSURLResponse* response))successBlock
                  failureBlock:(void (^)(NSError*))failureBlock {

    NSMutableString* urlString = [NSMutableString stringWithFormat:@"%@%@?ts=%ld&apikey=%@&hash=%@", [NSString stringWithUTF8String:s_kMarvelBaseUrl], [NSString stringWithUTF8String:s_kMarvelComicsEndpoint], s_timestamp, [NSString stringWithUTF8String:s_kMarvelPublicKey], [self digest]];

    if (count > 0) {
        [urlString appendFormat:@"&limit=%i", count];
    }

    [urlString appendFormat:@"&orderBy=-onsaleDate&orderBy=title"];
    [urlString appendFormat:@"&offset=%i", offset];

    NetworkRequest* request = [[NetworkRequest alloc] initWithUrl:[NSURL URLWithString:urlString]
                                                       httpMethod:@"GET"
                                                          timeOut:kRequestTimeout
                                                         userInfo:nil
                                                          success:^(id data, NSURLResponse* response) {

                                                              NSDictionary* comicData = data[@"data"];

                                                              if (comicData && [data isKindOfClass:[NSDictionary class]]) {

                                                                  if (successBlock) {
                                                                      successBlock(comicData, response);
                                                                  }

                                                              } else {
                                                                  
                                                                  NSError* requestError = [NSError errorWithDomain:kMarvelClientErrorDomain
                                                                                                              code:-1
                                                                                                          userInfo:@{@"reason" : @"invalid data"}];
                                                                  NSLog(@"error: %@", requestError);

                                                                  if (failureBlock) {
                                                                      failureBlock(requestError);
                                                                  }
                                                              }
                                                          }
                                                          failure:^(NSError* error) {

                                                              NSLog(@"error: %@", error);
                                                              if (failureBlock) {
                                                                  failureBlock(error);
                                                              }
                                                          }];

    [_networkClient queueRequest:request];

    ++s_timestamp;
}

@end
