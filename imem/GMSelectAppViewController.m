//
//  GMSelectProcessViewController2TableViewController.m
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import "GMSelectAppViewController.h"
#import <AppList/AppList.h>
#import <SpringBoard/SBApplication.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#include <mach-o/dyld.h>

@interface GMSelectAppViewController ()

@property (nonatomic, retain) NSDictionary *applications;
@property (nonatomic, retain) ALApplicationTableDataSource *dataSource;
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
    
    self.activeApps = [self getActiveApps];    
}

#pragma mark - Private

- (NSArray*) getActiveApps
{
    unsigned pathSize = MAXPATHLEN;
    char path[pathSize];
    _NSGetExecutablePath(path, &pathSize);
    path[pathSize] = '\0';
    
    void *sbserv = dlopen(path, RTLD_LAZY);
    
    CFStringRef (*SBSCopyLocalizedApplicationNameForDisplayIdentifier)(CFStringRef displayIdentifier) = dlsym(sbserv, "SBSCopyLocalizedApplicationNameForDisplayIdentifier");
    
    CFDataRef (*SBSCopyIconImagePNGDataForDisplayIdentifier)(CFStringRef displayIdentifier) = dlsym(sbserv, "SBSCopyIconImagePNGDataForDisplayIdentifier");
    
    CFStringRef (*SBSCopyDisplayIdentifierForProcessID)(pid_t PID) = dlsym(sbserv, "SBSCopyDisplayIdentifierForProcessID");
    
    CFStringRef (*SBSCopyFrontmostApplicationDisplayIdentifier)() =
    dlsym(sbserv, "SBSCopyFrontmostApplicationDisplayIdentifier");
    
    dlclose(sbserv);
    
    NSString *frontmostApp = (NSString *)SBSCopyFrontmostApplicationDisplayIdentifier();
    
    //get list of all apps from kernel
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    
    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    
    do {
        size += size / 10;
        newprocess = realloc(process, size);
        if (!newprocess){
            
            if (process){
                free(process);
            }
            return nil;
        }
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
        
    } while (st == -1 && errno == ENOMEM);
    if (st == 0){
        if (size % sizeof(struct kinfo_proc) == 0){
            int nprocess = size / sizeof(struct kinfo_proc);
            
            if (nprocess){
                
                NSMutableArray * array = [[NSMutableArray alloc] init];
                
                for (int i = nprocess - 1; i >= 0; i--){
                    
                    int ruid = process[i].kp_eproc.e_pcred.p_ruid;
                    NSString * processID = [[NSString alloc] initWithFormat:@"%d", process[i].kp_proc.p_pid];
                    NSString * processName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
                    NSString * proc_CPU = [[NSString alloc] initWithFormat:@"%d", process[i].kp_proc.p_pctcpu];
                    NSString * proc_useTiem = [[NSString alloc] initWithFormat:@"%s",asctime(localtime(&(process[i].kp_proc.p_un.__p_starttime.tv_sec)))];
                    NSString * appId = (NSString *)SBSCopyDisplayIdentifierForProcessID(process[i].kp_proc.p_pid);
                    if (appId == nil) {
                        continue;
                    }
                    
                    NSString *appName = (NSString *)SBSCopyLocalizedApplicationNameForDisplayIdentifier((CFStringRef)appId);
                    CFDataRef appIconData = SBSCopyIconImagePNGDataForDisplayIdentifier((CFStringRef)appId);
                    UIImage *appIcon = [UIImage imageWithData:(NSData *)appIconData scale:[UIScreen mainScreen].scale];
                    
                    BOOL systemProcess = YES;
                    if (ruid == 501)
                        systemProcess = NO;
                    
                    if (systemProcess == NO)
                    {
                        if ([appId isEqualToString:@""]) {
                            //final check.if no appid this is not springboard app
                            NSLog(@"(potentially system)Found process with PID:%@ name %@,isSystem:%d",processID,processName,systemProcess);
                        } else {
                            
                            BOOL isFrontmost = [frontmostApp isEqualToString:appId];
                            
                            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                            [dic setObject:processID forKey:@"ProcessID"];
                            [dic setObject:processName forKey:@"ProcessName"];
                            [dic setObject:proc_CPU forKey:@"ProcessCPU"];
                            [dic setObject:proc_useTiem forKey:@"ProcessUseTime"];
                            [dic setObject:appId forKey:@"appID"];
                            [dic setObject:appName forKey:@"appName"];
                            [dic setObject:appIcon forKey:@"appIcon"];
                            [dic setObject:@(isFrontmost) forKey:@"isFrontmost"];
                            
                            [array addObject:dic];
                        }
                    }
                }
                
                free(process);
                return array;
            }
        }
    }
    return nil;
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification {
    [self reloadData];
}

- (void)reloadData {
#if !TARGET_IPHONE_SIMULATOR
//    self.dataSource = [[[ALApplicationTableDataSource alloc] init] autorelease];
//    self.dataSource.sectionDescriptors = [self.class standardSectionDescriptors];
//	self.tableView.dataSource = self.dataSource;
//	self.dataSource.tableView = self.tableView;
#endif
}

#if !TARGET_IPHONE_SIMULATOR

//+ (NSArray *)standardSectionDescriptors
//{
//	NSNumber *iconSize = [NSNumber numberWithUnsignedInteger:ALApplicationIconSizeSmall];
//	return [NSArray arrayWithObjects:
//            [NSDictionary dictionaryWithObjectsAndKeys:
//             @"System Applications", ALSectionDescriptorTitleKey,
//             @"(isSystemApplication = TRUE) AND (pid > 0)", ALSectionDescriptorPredicateKey,
//             @"UITableViewCell", ALSectionDescriptorCellClassNameKey,
//             iconSize, ALSectionDescriptorIconSizeKey,
//             (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
//             nil],
//            [NSDictionary dictionaryWithObjectsAndKeys:
//             @"User Applications", ALSectionDescriptorTitleKey,
//             @"(isSystemApplication = FALSE) AND (pid > 0)", ALSectionDescriptorPredicateKey,
//             @"UITableViewCell", ALSectionDescriptorCellClassNameKey,
//             iconSize, ALSectionDescriptorIconSizeKey,
//             (id)kCFBooleanTrue, ALSectionDescriptorSuppressHiddenAppsKey,
//             nil],
//            nil];
//}

#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.applications = nil;
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
