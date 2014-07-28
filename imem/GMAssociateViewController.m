//
//  GMAssociateViewController.m
//  imem
//
//  Created by luobin on 14-7-28.
//
//

#import "GMAssociateViewController.h"

@interface GMAssociateViewController ()

@end

@implementation GMAssociateViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (NSString *)searchText {
    return [[self.displayController.searchBar text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reuseIdentifier"] autorelease];
    }
    // Configure the cell...
    if (indexPath.row == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"自动匹配\"%@\"", self.searchText];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = [NSString stringWithFormat:@"搜索整型\"%@\"", self.searchText];
    } else if (indexPath.row == 2) {
        cell.textLabel.text = [NSString stringWithFormat:@"字符\"%@\"", self.searchText];
    } else if (indexPath.row == 3) {
        cell.textLabel.text = [NSString stringWithFormat:@"搜索小数\"%@\"", self.searchText];
    }
    return cell;
}


#pragma mark - SearchDisplayDelegate

- (BOOL)searchDisplayController:(SearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return YES;
}


@end
