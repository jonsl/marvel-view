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
#import <AsyncImageView/AsyncImageView.h>

static NSString* kNewDataNotification = @"NewDataNotification";
static int const kRequestCount = 100;
static int const kRequestSize = 20;

@interface ComicsTableViewController ()<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController* fetchedResultsController;

@end

@implementation ComicsTableViewController {
    
    int _requestOffset;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDataNotification:) name:kNewDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asyncImageLoadDidFinishNotification:) name:AsyncImageLoadDidFinish object:nil];

    NSFetchRequest* fetchRequest = [Comic fetchRequest];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"onSaleDate" ascending:NO]]];
    [fetchRequest setFetchBatchSize:kRequestSize];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[DatabaseManager sharedManager].context
                                                                          sectionNameKeyPath:nil cacheName:nil];//@"Root"];
    self.fetchedResultsController.delegate = self;
    
    NSError* error = nil;
    
    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"viewDidLoad: performFetch error: %@", [error description]);
    }

    _requestOffset = 0;
    
    [[DatabaseManager sharedManager] clear:nil];
    
    NSUInteger comicsCount = [DatabaseManager sharedManager].comicsCount;
    if (comicsCount == 0) {

        [self checkRequestData:0];

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
            
            NSError* error = nil;
            BOOL success = [[DatabaseManager sharedManager].context save:&error];
            if (!success) {
                NSLog(@"newDataNotification: context save error: %@", [error description]);
            }
            
        } @catch (NSException *exception) {
            
            NSLog(@"exception: %@", [exception description]);
            
        } @finally {

            [self.tableView reloadData];
        }
    }
}

-(void)asyncImageLoadDidFinishNotification:(NSNotification*)notification {
    
}

-(void)checkRequestData:(int)currentOffset {
    if (_requestOffset < (currentOffset + kRequestCount)) {
        _requestOffset = [MarvelClient performComicsRequestWithOffset:_requestOffset
                                                                count:kRequestCount
                                                          requestSize:kRequestSize
                                                              orderBy:kOrderByOnSaleDate
                                                        sortOrderType:Descending
                                                         successBlock:^(NSDictionary *data, NSURLResponse *response) {

                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:kNewDataNotification
                                                                                                                     object:self
                                                                                                                   userInfo:data];
                                                             });
                                                         }
                                                         failureBlock:^(NSError *error) {
                                                             
                                                             NSLog(@"requestData failed with: %@", [error description]);
                                                         }];
        NSLog(@"_requestOffset = %i, currentOffset = %i", _requestOffset, currentOffset);
    }
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Comic *info = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.numberOfLines = 2;   // multiline
    cell.textLabel.text = info.title;
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [formatter stringFromDate:info.onSaleDate]];
    [[cell.imageView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.imageView.image = [UIImage imageNamed:@"placeholder"];
    if (info.thumbnail) {
        CGRect frame = cell.imageView.bounds;
        AsyncImageView* asyImage = [[AsyncImageView alloc] initWithFrame:frame];
        asyImage.imageURL = [NSURL URLWithString:info.thumbnail];
        asyImage.layer.borderWidth = 2.0f;
        asyImage.contentMode = UIViewContentModeScaleToFill;
        asyImage.layer.masksToBounds= YES;
        asyImage.showActivityIndicator = YES;
        [cell.imageView addSubview:asyImage];
    }
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
    
    [self checkRequestData:(int)indexPath.row];

    return cell;
}

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
