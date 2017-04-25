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
static NSUInteger const kRequestLimit = 20;

@interface ComicsTableViewController ()<NSFetchedResultsControllerDelegate>

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

    NSFetchRequest* fetchRequest = [Comic fetchRequest];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"onSaleDate" ascending:NO]]];
    [fetchRequest setFetchBatchSize:kRequestLimit];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[DatabaseManager sharedManager].context
                                                                          sectionNameKeyPath:nil cacheName:nil];//@"Root"];
    self.fetchedResultsController.delegate = self;
    
    NSError* error = nil;
    
    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"viewDidLoad: performFetch error: %@", [error description]);
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDataNotification:) name:kNewDataNotification object:nil];
    
    [[DatabaseManager sharedManager] clear:nil];
    
    NSUInteger comicsCount = [DatabaseManager sharedManager].comicsCount;
    if (comicsCount == 0) {

        [self requestData];

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
            if (error) {
                NSLog(@"newDataNotification: context save error: %@", [error description]);
            }
        }
    }
}

-(void)requestData {

    [MarvelClient performComicsRequestWithCount:2000
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

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Comic *info = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = info.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", info.onSaleDate];
}

#pragma mark - NSFetchedResultsControllerDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_fetchedResultsController sections].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ComicDetailTableCell" forIndexPath:indexPath];
    
    // Set up the cell...
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
