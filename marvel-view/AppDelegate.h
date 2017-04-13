//
//  AppDelegate.h
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

