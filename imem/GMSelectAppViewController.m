//
//  GMSelectProcessViewController2TableViewController.m
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import "GMSelectAppViewController.h"
#import <AppList/AppList.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#include <mach-o/dyld.h>
#import "AppUtil.h"

@interface GMSelectAppViewController ()

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSArray *activeApps;

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
    self.activeApps = nil;
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
    [self reloadData];
}

- (void)reloadData {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.activeApps = [AppUtil getApps:YES];
        [self.tableView reloadData];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.activeApps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.indentationLevel = 0;
        cell.indentationWidth = 10.0f;
    }
    NSDictionary *appInfo = [self.activeApps objectAtIndex:indexPath.row];
    cell.textLabel.text = [appInfo objectForKey:@"appName"];
    cell.imageView.image = [appInfo objectForKey:@"appIcon"];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.didSelectProcessBlock) {
        NSDictionary *appInfo = [self.activeApps objectAtIndex:indexPath.row];
        NSString *appName = [appInfo objectForKey:@"appName"];
        UIImage *appIcon = [appInfo objectForKey:@"appIcon"];
        pid_t pid = [[appInfo objectForKey:@"processID"] integerValue];
        self.didSelectProcessBlock(appIcon, appName, pid);
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
