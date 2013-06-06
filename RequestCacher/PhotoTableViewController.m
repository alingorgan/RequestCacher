//
//  PhotoTableViewController.m
//  RequestCacher
//
//  Created by Alin Gorgan on 1/7/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "PhotoTableViewController.h"
#import "PhotoCell.h"
#import "CoreDataStack.h"
#import "Request+Cache.h"

@interface PhotoTableViewController ()

@property (nonatomic, strong) NSArray* photoArray;

@end

@implementation PhotoTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.photoArray = [NSArray arrayWithObjects:
                       @"http://p.rdcpix.com/v01/ld7b5e443-m0s.jpg",
                       @"http://p.rdcpix.com/v01/ld01f7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l27cbef43-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l12f4e643-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l0e0afb43-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l06fff943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l1b74cb43-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l8c66f943-m0s.jpg",
                       @"http://p.rdcpix.com/v02/le63bd843-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l06fff943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l1b74cb43-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9d1d7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9a1af543-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l5c1c7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/lb73a0244-m0s.jpg",
                       @"http://p.rdcpix.com/v01/lb7c4f643-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9d1d7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9a1af543-m0s.jpg",
                       @"http://p.rdcpix.com/v01/ld3bed343-m0s.jpg",
                       @"http://p.rdcpix.com/v01/le3acd143-m0s.jpg",
                       @"http://p.rdcpix.com/v01/le41e7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9d1d7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9a1af543-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l03cf0144-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l1a62f143-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9d1d7943-m0s.jpg",
                       @"http://p.rdcpix.com/v01/l9a1af543-m0s.jpg",nil];
}

- (IBAction)clearCacheButtonClicked:(id)sender {
    
    dispatch_queue_t erase_cache_queue = dispatch_queue_create("erase queue", NULL);
    dispatch_async(erase_cache_queue, ^{
        [Request removeAllCachedRequestsUsingContext:[CoreDataStack sharedStackManager].managedObjectContext];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.photoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PhotoCell";
    PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    /// use get - direct url to the image
    [cell.imageView loadImageWithURL:[NSURL URLWithString:[self.photoArray objectAtIndex:indexPath.row]]];
    
    /// use post with an existing webpage that serves the image
//    [cell.imageView loadImageWithURL:[NSURL URLWithString:@"http://myImageproxy.aspx"]
//                          withParams:[self.photoArray objectAtIndex:indexPath.row]];
    
    return cell;
}
@end
