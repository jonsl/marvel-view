//
//  ComicsTableViewController.m
//  marvel-view
//
//  Created by Jonathan Slater on 17/04/2017.
//  Copyright © 2017 Jonathan Slater. All rights reserved.
//

#import "AppDelegate.h"
#import "ComicsTableViewController.h"
#import "ModelManager.h"
#import "Comic+CoreDataProperties.h"
#import <AsyncImageView/AsyncImageView.h>
#import "Extensions.h"
#import "ComicsTableViewCell.h"

static NSString const* kMarvelBaseUrl = @"https://gateway.marvel.com";

@interface ComicsTableViewController()<NSFetchedResultsControllerDelegate, Observer>

@property (readonly, nonatomic) NSManagedObjectContext* mainManagedObjectContext;

@property (strong, nonatomic) NSFetchedResultsController* fetchedResultsController;

@end

@implementation ComicsTableViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    [[ModelManager sharedInstance] addObserver:self];

    NSFetchRequest* fetchRequest = [Comic fetchRequest];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"onSaleDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
    [fetchRequest setFetchBatchSize:(NSUInteger) kRequestCount];

    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.mainManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;

    NSError* error = nil;

    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"viewDidLoad: performFetch error: %@", [error description]);
    }

    [[ModelManager sharedInstance] clearData];

    NSUInteger comicsCount = [ModelManager sharedInstance].comicsCount;
    if (comicsCount == 0) {
        [[ModelManager sharedInstance] requestComicWithOffset:0];
    }
}

-(void)viewDidUnload {
    self.fetchedResultsController = nil;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

-(void)dealloc {
    [[ModelManager sharedInstance] removeObserver:self];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSManagedObjectContext*)mainManagedObjectContext {
    AppDelegate* appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext* context = appDelegate.persistentContainer.viewContext;
    NSParameterAssert(context);
    return context;
}

-(void)configureCell:(ComicsTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    NSParameterAssert([[_fetchedResultsController objectAtIndexPath:indexPath] isKindOfClass:[Comic class]]);
    Comic* info = (Comic*) [_fetchedResultsController objectAtIndexPath:indexPath];
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

#pragma mark - Observer

-(void)notify {
    NSLog(@"received update");
}

-(void)notifyWithError:(NSError*)error {
    NSString* message = [NSString stringWithFormat:@"%@:%@", error.localizedDescription, error.userInfo];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Network Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction* action) {

                                                   [alert dismissViewControllerAnimated:YES completion:nil];

                                               }];

    [alert addAction:ok];

    [self presentViewController:alert animated:YES completion:nil];
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
    [[ModelManager sharedInstance] requestComicWithOffset:(int) indexPath.row];
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
