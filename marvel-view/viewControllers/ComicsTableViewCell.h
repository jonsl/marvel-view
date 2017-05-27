//
//  ComicsTableViewCell.h
//  marvel-view
//
//  Created by Jonathan Slater on 27/05/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComicsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView* thumbnail;

@property (weak, nonatomic) IBOutlet UILabel* title;

@property (weak, nonatomic) IBOutlet UILabel* date;

@end
