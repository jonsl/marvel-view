//
//  ComicsTableViewController.m
//  marvel-view
//
//  Created by Jonathan Slater on 17/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "ComicsTableViewController.h"
#import "MarvelClient.h"
#import "DatabaseManager.h"

@interface ComicsTableViewController ()

@end

@implementation ComicsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Comic"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"onSaleDate" ascending:YES]]];

//    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"saleByDate = %@"];
//    fetchRequest.predicate = predicate;
    
    NSAsynchronousFetchRequest* asyncFetch = [[NSAsynchronousFetchRequest alloc] initWithFetchRequest:fetchRequest
                                                                                      completionBlock:^(NSAsynchronousFetchResult* result) {

        if (result.finalResult) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                
                [self.tableView reloadData];
                
            });
            
            
        }
        
    }];

    __block NSError* error = nil;

    [[DatabaseManager sharedManager].context performBlock:^{
       
        
        NSAsynchronousFetchResult* result = [[DatabaseManager sharedManager].context executeRequest:asyncFetch error:&error];
        
        if (error) {
            
            
            
        }
        
        
    }];
    
    
    
    
    NSArray* result = [[DatabaseManager sharedManager].context executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        return ;
    }
    
    if (result.count > 0) {
        
    } else {
        
        [MarvelClient performComicsRequest:0
                                     limit:100
                                   orderBy:kOrderByOnSaleDate
                                  sortType:Ascending
                              successBlock:^(NSDictionary *data, NSURLResponse *response) {
                                  
                                  NSLog(@"success, data is:\n%@", data);
                                  
                                  [self newServerData:data];
                                  
                              }                     failureBlock:^(NSError* error) {
                                  
                                  NSLog(@"failure, error is {%@}", [error description]);
                                  
                              }];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)newServerData:(NSDictionary*)data {

    if (data) {
        
        NSArray* comics = data[@"results"];
        
        @try {

            for (NSDictionary* comic in comics) {

                [[DatabaseManager sharedManager] insertNewComicEntityFromDictionary:comic];
            }
            
        } @catch (NSException *exception) {
            
            NSLog(@"exception: %@", [exception description]);

        } @finally {

            NSError* error = nil;
            [[DatabaseManager sharedManager].context save:&error];
            if (!error) {
                
                //            dispatch_async(dispatch_get_main_queue(), ^void(void){
                //
                //                [self.tableView reloadData];
                //                
                //            });
            }
        }
        
        
    }

    
    
    
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ComicDetailTableCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
