//
//  GMSelectProcessViewController2TableViewController.m
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import "GMSelectAppViewController.h"
#import "GMMem.h"
#import <AppList/AppList.h>
#import <SpringBoard/SBApplication.h>

@interface GMSelectAppViewController ()

@property (nonatomic, retain) NSDictionary *applications;
@property (nonatomic, retain) ALApplicationTableDataSource *dataSource;
@property (nonatomic, retain) NSTimer *timer;

@end

@implementation GMSelectAppViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.navigationItem.title = @"选择应用";
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.didSelectProcessBlock = nil;
    self.dataSource.tableView = nil;
	self.dataSource = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

#pragma mark - Private
- (void)appDidBecomeActiveNotification:(NSNotification *)notification {
    TKAlert(@"程序已退出，请重新选择！");
    [self reloadData];
}

- (void)reloadData {
#if !TARGET_IPHONE_SIMULATOR
    self.dataSource = [[[ALApplicationTableDataSource alloc] init] autorelease];
    self.dataSource.sectionDescriptors = [self.class standardSectionDescriptors];
	self.tableView.dataSource = self.dataSource;
	self.dataSource.tableView = self.tableView;
#endif
}

#if !TARGET_IPHONE_SIMULATOR

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

#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.applications = nil;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#if !TARGET_IPHONE_SIMULATOR
    if (self.didSelectProcessBlock) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSString *displayIdentifier = [self.dataSource displayIdentifierForIndexPath:indexPath];
        ALApplicationList *applicationList = [ALApplicationList sharedApplicationList];
        pid_t pid = [[applicationList valueForKey:@"pid" forDisplayIdentifier:displayIdentifier] intValue];
        self.didSelectProcessBlock(cell.imageView.image, cell.textLabel.text, pid);
        [self.navigationController popViewControllerAnimated:YES];
    }
#endif
}

@end
