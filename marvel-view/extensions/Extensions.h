//
//  Extensions.h
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject(Associating)

@property (nonatomic, strong) id associatedObject;

@end

@interface NSString(Md5)

-(NSString*)md5;

@end

@interface NSData(Md5)

-(NSString*)md5;

@end
