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
#import "Comic+CoreDataProperties.h"

static NSString* kNewDataNotification = @"NewDataNotification";
static NSUInteger const kRequestLimit = 10;

@interface ComicsTableViewController ()

@property (strong, nonatomic) NSFetchedResultsController* fetchedResultsController;

@end

@implementation ComicsTableViewController {
    
    NSUInteger _requestOffset;
    NSUInteger _fetchOffset;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDataNotification:) name:kNewDataNotification object:nil];
    
//    [[DatabaseManager sharedManager] clear:nil];
    
    NSUInteger comicsCount = [DatabaseManager sharedManager].comicsCount;
    
    if (comicsCount == 0) {

        [self requestData];

    } else {
        
        [self fetchData];
        
    }
    
}

- (void)viewDidUnload {
    self.fetchedResultsController = nil;
}

-(void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)newDataNotification:(NSNotification*)notification {
    
    if ([[notification name] isEqualToString:kNewDataNotification]) {

        NSDictionary* data = [notification userInfo];
        NSAssert(data, @"data is nil");
        
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
            
        }
    }
}

-(void)requestData {

    [MarvelClient performComicsRequestWithCount:100
                                          limit:kRequestLimit
                                        orderBy:kOrderByOnSaleDate
                                  sortOrderType:Descending
                                   successBlock:^(NSDictionary *data, NSURLResponse *response) {
                                       
                                       [[NSNotificationCenter defaultCenter] postNotificationName:kNewDataNotification
                                                                                           object:self
                                                                                         userInfo:data];
                                       
                                   }
                                   failureBlock:^(NSError *error) {
                                       
                                       NSLog(@"requestData failed with: %@", [error description]);

                                   }];

}

-(void)fetchData {
    
    __block NSError* error = nil;

    NSFetchRequest* fetchRequest = [Comic fetchRequest];
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
    
    [[DatabaseManager sharedManager].context performBlockAndWait:^{

        NSAsynchronousFetchResult* result = [[DatabaseManager sharedManager].context executeRequest:asyncFetch error:&error];
        
        if (error) {

        }

    }];
    
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
