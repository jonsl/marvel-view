//
//  ViewController.m
//  marvel-view
//
//  Created by Jonathan Slater on 13/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "ViewController.h"
#import "MarvelClient.h"

@interface ViewController()

@end

@implementation ViewController {

}

-(void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.


    [MarvelClient performComicsRequest:0
                                 limit:0
                               orderBy:kOrderByOnSaleDate
                              sortType:Ascending
                          successBlock:^(NSDictionary *data, NSURLResponse *response) {

        NSLog(@"success, data is:\n%@", data);

    }                     failureBlock:^(NSError* error) {

        NSLog(@"failure, error is {%@}", [error description]);

    }];


}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
