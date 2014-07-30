//
//  GMStorageViewControllerTableViewController.m
//  imem
//
//  Created by luobin on 14-7-20.
//
//

#import "GMStorageViewController.h"
#import "GMMemManagerProxy.h"

#define kSegmentedControlIndexStoredIndex 0
#define kSegmentedControlIndexLockedIndex 1

@interface GMStorageViewController ()

@property (nonatomic, retain) NSArray *lists;

@end

@implementation GMStorageViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSArray *items = [NSArray arrayWithObjects:@"存储", @"锁定", nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    segmentedControl.frame = CGRectMake(0, 0, 150, 29);
    [segmentedControl addTarget:self action:@selector(segmentDidSelect:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    [segmentedControl release];
    segmentedControl.selectedSegmentIndex = 0;
    self.lists = [[GMMemManagerProxy shareInstance] getLockedList];
}

- (void)dealloc {
    self.lists = nil;
    [super dealloc];
}

- (void)segmentDidSelect:(UISegmentedControl *)segmentedControl {
    NSInteger selectedSegmentIndex = segmentedControl.selectedSegmentIndex;
    if (selectedSegmentIndex == kSegmentedControlIndexStoredIndex) {
        self.lists = [[GMMemManagerProxy shareInstance] getLockedList];
        
    } else if (selectedSegmentIndex == kSegmentedControlIndexLockedIndex) {
        self.lists = [[GMMemManagerProxy shareInstance] getStoredList];
        
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.lists count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
    // Configure the cell...
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    GMMemoryAccessObject *memoryAccessObject = [self.lists objectAtIndex:indexPath.row];
    uint64_t value = [memoryAccessObject value];
    uint64_t address = [memoryAccessObject address];
    NSString *text = [NSString stringWithFormat:@"%ld、0X%08llX:%llu", (long)indexPath.row, address, value];
    cell.textLabel.text = text;
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - Table view data delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GMMemoryAccessObject *memoryAccessObject = [self.lists objectAtIndex:indexPath.row];
}

@end
