//
//  ComicsTableViewController.m
//  marvel-view
//
//  Created by Jonathan Slater on 17/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "AppDelegate.h"
#import "ComicsTableViewController.h"
#import "ComicsManager.h"
#import "Comic+CoreDataProperties.h"
#import <AsyncImageView/AsyncImageView.h>
#import "Extensions.h"
#import "ComicsTableViewCell.h"

@interface ComicsTableViewController()<NSFetchedResultsControllerDelegate>

@property (readonly, nonatomic) NSManagedObjectContext* mainManagedObjectContext;

@property (strong, nonatomic) NSFetchedResultsController* fetchedResultsController;

@end

@implementation ComicsTableViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newDataNotification:) name:kNewDataNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asyncImageLoadDidFinishNotification:) name:AsyncImageLoadDidFinish object:nil];

    NSFetchRequest* fetchRequest = [Comic fetchRequest];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"onSaleDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
    [fetchRequest setFetchBatchSize:(NSUInteger) kRequestCount];

    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.mainManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];//@"Root"];
    self.fetchedResultsController.delegate = self;

    NSError* error = nil;

    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"viewDidLoad: performFetch error: %@", [error description]);
    }

    [[ComicsManager sharedInstance] clearData:&error];
    if (error) {
        NSLog(@"main clear error: %@", [error description]);
        return;
    }

    NSUInteger comicsCount = [ComicsManager sharedInstance].comicsCount;
    if (comicsCount == 0) {

        [[ComicsManager sharedInstance] updateRequestsForRow:0];

    }

}

-(void)viewDidUnload {
    self.fetchedResultsController = nil;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

-(void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)newDataNotification:(NSNotification*)notification {
    NSParameterAssert([NSThread isMainThread]);

    if ([[notification name] isEqualToString:kNewDataNotification]) {

    }
}

-(NSManagedObjectContext*)mainManagedObjectContext {
    AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* context = appDelegate.persistentContainer.viewContext;
    NSParameterAssert(context);
    return context;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView {
//    NSArray *visibleCells = [self.tableView visibleCells];
//    [visibleCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        MyTableViewCell *cell = (MyTableViewCell *)obj;
//        NSString *url = ...;
//        [cell showImageURL:url];
//    }];
}

-(void)asyncImageLoadDidFinishNotification:(NSNotification*)notification {
    [self.tableView setNeedsDisplay];
}

-(void)configureCell:(ComicsTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    Comic* info = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.title.text = info.title;
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    cell.date.text = [NSString stringWithFormat:@"%@", [formatter stringFromDate:info.onSaleDate]];
    cell.thumbnail.image = [UIImage imageNamed:@"placeholder"];
    if (cell.thumbnail.associatedObject) {
        [[AsyncImageLoader sharedLoader] cancelLoadingURL:cell.thumbnail.associatedObject];
        cell.thumbnail.associatedObject = nil;
    }
    NSParameterAssert(info.thumbnail);
    if (info.thumbnail) {
        cell.thumbnail.associatedObject = [[NSURL URLWithString:info.thumbnail] copy];

        [[cell.thumbnail subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

        CGRect frame = cell.thumbnail.bounds;
        AsyncImageView* asyImage = [[AsyncImageView alloc] initWithFrame:frame];
        asyImage.imageURL = cell.thumbnail.associatedObject;
        asyImage.layer.borderWidth = 2.0f;
        asyImage.contentMode = UIViewContentModeScaleToFill;
        asyImage.layer.masksToBounds = YES;
        asyImage.showActivityIndicator = YES;
        [cell.thumbnail addSubview:asyImage];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController*)controller {
    [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath {

    UITableView* tableView = self.tableView;

    switch (type) {

        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;

        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController*)controller {
    [self.tableView endUpdates];
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return [_fetchedResultsController sections].count;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    id sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

-(void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    // configure cell
    NSParameterAssert([cell isKindOfClass:[ComicsTableViewCell class]]);

    [self configureCell:(ComicsTableViewCell*) cell atIndexPath:indexPath];

    // request more data if needed
    [[ComicsManager sharedInstance] updateRequestsForRow:(int) indexPath.row];
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    ComicsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ComicDetailTableCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[ComicsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ComicDetailTableCell"];
    }
    return cell;
}

#pragma mark - UIViewController

-(void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
