//
//  Comic+CoreDataProperties.h
//  marvel-view
//
//  Created by Jonathan Slater on 24/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "Comic+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Comic (CoreDataProperties)

+ (NSFetchRequest<Comic *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *desc;
@property (nullable, nonatomic, copy) NSDate *onSaleDate;
@property (nullable, nonatomic, copy) NSString *thumbnail;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSString *uniqueId;

@end

NS_ASSUME_NONNULL_END
