//
//  GMSelectProcessViewController2TableViewController.m
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import "GMSelectProcessViewController.h"
#import "GMMem.h"
#import <AppList/AppList.h>
#import <SpringBoard/SBApplication.h>

@interface GMSelectProcessViewController ()

@property (nonatomic, retain) NSDictionary *applications;
@property (nonatomic, retain) ALApplicationTableDataSource *dataSource;

@end

@implementation GMSelectProcessViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)] autorelease];
    }
    return self;
}

- (void)dealloc {
    self.didSelectProcessBlock = nil;
    self.dataSource.tableView = nil;
	self.dataSource = nil;
    [super dealloc];
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dataSource = [[[ALApplicationTableDataSource alloc] init] autorelease];
    self.dataSource.sectionDescriptors = [self.class standardSectionDescriptors];
	self.tableView.dataSource = self.dataSource;
	self.dataSource.tableView = self.tableView;
}

+ (NSArray *)standardSectionDescriptors
{
	NSNumber *iconSize = [NSNumber numberWithUnsignedInteger:ALApplicationIconSizeSmall];
	return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"System Applications", ALSectionDescriptorTitleKey,
             @"(isSystemApplication = TRUE) AND (pid > 0)", ALSectionDescriptorPredicateKey,
             @"UITableViewCell", ALSectionDescriptorCellClassNameKey,
             iconSize, ALSectionDescriptorIconSizeKey,
             (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"User Applications", ALSectionDescriptorTitleKey,
             @"(isSystemApplication = FALSE) AND (pid > 0)", ALSectionDescriptorPredicateKey,
             @"UITableViewCell", ALSectionDescriptorCellClassNameKey,
             iconSize, ALSectionDescriptorIconSizeKey,
             (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
             nil],
            nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.applications = nil;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.didSelectProcessBlock) {
        NSString *displayIdentifier = [self.dataSource displayIdentifierForIndexPath:indexPath];
        ALApplicationList *applicationList = [ALApplicationList sharedApplicationList];
        pid_t pid = [[applicationList valueForKey:@"pid" forDisplayIdentifier:displayIdentifier] intValue];
        self.didSelectProcessBlock(pid);
        [self dismiss];
    }
}

@end
