//
//  GMMainViewController.m
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import "GMMainViewController.h"
#import "GMSelectAppViewController.h"
#import "GMMemManagerProxy.h"
#import "GMModifyViewController.h"
#import "UIView+Sizes.h"
#import "GMStorageViewController.h"
#import "GMSelectAppButton.h"
#import "UIColor+iOS7Colors.h"
#import "SearchDisplayController.h"
#import "GMAssociateViewController.h"
#import "GMStorageViewController.h"
#import <UI7Kit/UI7Kit.h>
#import "TKKeyboard.h"
#import "TKTextFieldAlertView.h"
#import "GMSettingViewController.h"
#import "AppUtil.h"
#import "GPLoadingView.h"

#define CellMAXCount 99
#define TKKeyboardTypeMain (120)
#define TKKeyboardHeight 180

@interface GMMainViewController ()<UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, TKTextFieldAlertViewDelegate>

@property (nonatomic, retain) UITableView *tableView;

@property (nonatomic, assign) int pid;
@property (nonatomic, retain) NSArray *results;
@property (nonatomic, assign) UInt64 resultCount;
@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) dispatch_source_t source;

- (void)resetKeyDidPressed;

- (void)storageKeyDidPressed;

- (void)searchKeyDidPressed;

@end

@implementation GMMainViewController

- (void)gotoSelectProcess {
    GMSelectAppViewController *selectProcessViewController = [[GMSelectAppViewController alloc] init];
    selectProcessViewController.didSelectProcessBlock = ^(UIImage *appIcon, NSString *appName, int pid) {
        BOOL ok = NO;
        if (pid > 0) {
            self.pid = pid;
            ok = [[GMMemManagerProxy shareInstance] setPid:pid];
        }
        if (!ok) {
            TKAlert(@"程序已退出，请重新选择！");
        } else {
            [self updateWithPid:pid appName:appName appIcon:appIcon];
        }
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:selectProcessViewController];
    [self.navigationController pushViewController:selectProcessViewController animated:YES];
    [nav release];
    [selectProcessViewController release];
}

- (void)initKeyboard {
    TKKeyboardConfiguration *configiration = [[TKKeyboardConfiguration alloc] init];
    configiration.keyboardType = TKKeyboardTypeMain;
    configiration.keyboardHeight = TKKeyboardHeight;
    configiration.backgroundColor = [UIColor colorWithWhite:179/255.0 alpha:1];
    
    NSMutableArray *keyItems = [NSMutableArray array];
    for (int i = 1; i < 5; i++) {
        TKKeyItem *keyItem = [[TKKeyItem alloc] initWithInsertText:[NSString stringWithFormat:@"%d", i]];
        [keyItems addObject:keyItem];
        [keyItem release];
    }
    
    MAWeakSelfDeclare();
    TKKeyItem *keyItem;
    
    keyItem = [[TKKeyItem alloc] initWithTitle:@"搜索" action:^(id<TKTextInput> textInput, TKKeyItem *keyItem) {
        MAWeakSelfImportReturn();
        [self searchKeyDidPressed];
    }];
    keyItem.titleFont = [UIFont systemFontOfSize:20];
    [keyItems addObject:keyItem];
    [keyItem release];
    
    for (int i = 5; i < 9; i++) {
        TKKeyItem *keyItem = [[TKKeyItem alloc] initWithInsertText:[NSString stringWithFormat:@"%d", i]];
        [keyItems addObject:keyItem];
        [keyItem release];
    }
    
    keyItem = [[TKKeyItem alloc] initWithTitle:@"重置" action:^(id<TKTextInput> textInput, TKKeyItem *keyItem) {
        MAWeakSelfImportReturn();
        [self resetKeyDidPressed];
    }];
    keyItem.titleFont = [UIFont systemFontOfSize:20];
    [keyItems addObject:keyItem];
    [keyItem release];

    keyItem = [[TKKeyItem alloc] initWithInsertText:@"9"];
    [keyItems addObject:keyItem];
    [keyItem release];
    
    keyItem = [[TKKeyItem alloc] initWithInsertText:@"0"];
    [keyItems addObject:keyItem];
    [keyItem release];
    
    keyItem = [[TKKeyItem alloc] initWithType:TKKeyItemTypeDelete action:^(id<TKTextInput> textInput, TKKeyItem *keyItem) {
        [textInput deleteBackward];
    }];
    keyItem.enablesAutomatically = NO;
    keyItem.enableLongPressRepeat = YES;
    keyItem.backgroundColor = [UIColor colorWithWhite:225/255.0 alpha:1];
    keyItem.highlightBackgroundColor = [UIColor colorWithWhite:251/255.0 alpha:1];
    [keyItems addObject:keyItem];
    [keyItem release];
    
    keyItem = [[TKKeyItem alloc] initWithTitle:@"添加" action:^(id<TKTextInput> textInput, TKKeyItem *keyItem) {
        MAWeakSelfImportReturn();
        [self addKeyDidPressed];
    }];
    keyItem.titleFont = [UIFont systemFontOfSize:20];
    [keyItems addObject:keyItem];
    [keyItem release];
    
    keyItem = [[TKKeyItem alloc] initWithTitle:@"存储" action:^(id<TKTextInput> textInput, TKKeyItem *keyItem) {
        MAWeakSelfImportReturn();
        [self storageKeyDidPressed];
    }];
    keyItem.titleFont = [UIFont systemFontOfSize:20];
    [keyItems addObject:keyItem];
    [keyItem release];
    
    TKGridLayout *layout = [[TKGridLayout alloc] init];
    layout.rowCount = 3;
    layout.columnCount = 5;
    configiration.layout = layout;
    [layout release];
    
    configiration.keyItems = keyItems;
    [[TKKeyboardManager shareInstance] registerKeyboardConfiguration:configiration];
    [configiration release];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(setting)] autorelease];
        [self initKeyboard];
        self.isSearching = NO;
        self.shouldSelectProcess = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopMonitor];
    [self invalidateTimer];
    self.searchBar = nil;
    self.tableView = nil;
    self.results = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self startTimer];
    [self.searchBar becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self invalidateTimer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    self.tableView = tableView;
    [self.view addSubview:tableView];
    [tableView release];
    
    UISearchBar *searchBar = [[UISearchBar alloc]
                              initWithFrame:CGRectMake(0.0, [UIDevice currentDevice].isIOS7?self.navigationController.navigationBar.bottom:0, self.view.bounds.size.width, 44)];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.delegate = self;
    searchBar.showsSearchResultsButton = YES;
    searchBar.showsCancelButton = NO;
    searchBar.barStyle = UIBarStyleDefault;
    if ([UIDevice currentDevice].isIOS7) {
        searchBar.placeholder = @"输入要搜索的值                                          ";
    } else {
        searchBar.placeholder = @"输入要搜索的值";
    }
    searchBar.keyboardType = UIKeyboardTypeNamePhonePad;
    self.searchBar = searchBar;
    [self.view addSubview:searchBar];
    [searchBar release];
    
    UITextField *textField = (UITextField *)[searchBar descendantOrSelfWithClass:UITextField.class];
    textField.keyboardType = TKKeyboardTypeMain;
    
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(44, 0, TKKeyboardHeight, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset = edgeInsets;
    
    [textField becomeFirstResponder];
    [searchBar becomeFirstResponder];

//    [self addSearchDisplayController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    if (self.shouldSelectProcess) {
        GMSelectAppButton * selectAppButton = [[GMSelectAppButton alloc] init];
        selectAppButton.title = @"选择";
        selectAppButton.titleLabel.textColor = [UIColor colorWith8bitRed:0 green:126 blue:245 alpha:255];
        ;
        selectAppButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [selectAppButton addTarget:self action:@selector(gotoSelectProcess) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:selectAppButton] autorelease];
        [selectAppButton release];
        
        int pid = [[GMMemManagerProxy shareInstance] getPid];
        if (pid > 0) {
            self.pid = pid;
            [self updateWithPid:pid];
        }
        
    } else {
        pid_t pid = getpid();
        if (pid != [[GMMemManagerProxy shareInstance] getPid]) {
            [[GMMemManagerProxy shareInstance] reset];
            BOOL ok = [[GMMemManagerProxy shareInstance] setPid:pid];
            if (ok) {
                self.pid = pid;
                [self startMonitorForProcess:self.pid];
                self.results = nil;
                self.isFirst = YES;
            }
        }
    }
}

#pragma mark - KVO

//- (NSArray *)indexPathsForSection:(NSUInteger)section rowIndexSet:(NSIndexSet *)indexSet {
//    NSMutableArray *    indexPaths;
//    NSUInteger          currentIndex;
//    
//    assert(indexSet != nil);
//    
//    indexPaths = [NSMutableArray array];
//    assert(indexPaths != nil);
//    currentIndex = [indexSet firstIndex];
//    while (currentIndex != NSNotFound) {
//        [indexPaths addObject:[NSIndexPath indexPathForRow:currentIndex inSection:section]];
//        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
//    }
//    return indexPaths;
//}
//
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    
//    if (self.isViewLoaded) {
//        NSIndexSet *    indexes;
//        
//        indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
//        assert( (indexes == nil) || [indexes isKindOfClass:[NSIndexSet class]] );
//        
//        assert([change objectForKey:NSKeyValueChangeKindKey] != nil);
//        switch ( [[change objectForKey:NSKeyValueChangeKindKey] intValue] ) {
//            default:
//                assert(NO);
//            case NSKeyValueChangeSetting: {
//                [self.tableView reloadData];
//            } break;
//            case NSKeyValueChangeInsertion: {
//                assert(indexes != nil);
//                [self.tableView insertRowsAtIndexPaths:[self indexPathsForSection:0 rowIndexSet:indexes] withRowAnimation:UITableViewRowAnimationNone];
//                [self.tableView flashScrollIndicators];
//            } break;
//            case NSKeyValueChangeRemoval: {
//                assert(indexes != nil);
//                [self.tableView deleteRowsAtIndexPaths:[self indexPathsForSection:0 rowIndexSet:indexes] withRowAnimation:UITableViewRowAnimationNone];
//                [self.tableView flashScrollIndicators];
//            } break;
//            case NSKeyValueChangeReplacement: {
//                assert(indexes != nil);
//                [self.tableView reloadRowsAtIndexPaths:[self indexPathsForSection:0 rowIndexSet:indexes] withRowAnimation:UITableViewRowAnimationNone];
//            } break;
//        }
//    }
//}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if ([UIDevice currentDevice].isIOS7) {
        self.searchBar.top = self.navigationController.navigationBar.bottom;
    } else {
        self.searchBar.top = 0;
    }
}

#pragma mark - KeyBoard
- (void)resetKeyDidPressed {
    [[GMMemManagerProxy shareInstance] clearSearchData];
    self.results = nil;
    self.resultCount = 0;
    self.isFirst = YES;
    [self.tableView reloadData];
    self.searchBar.text = @"";
}

- (void)addKeyDidPressed {
    MAWeakSelfDeclare();
    TKTextFieldAlertView *textFieldAlertView = [[TKTextFieldAlertView alloc] initWithTitle:@"添加内存地址" placeholder:@"输入内存地址"];
    textFieldAlertView.textField.keyboardType = TKKeyboardTypeUnsignedHexPad;
    textFieldAlertView.delegate = self;
    [textFieldAlertView addButtonWithTitle:@"取消" block:nil];
    [textFieldAlertView addButtonWithTitle:@"确定" block:^{
        MAWeakSelfImportReturn();
        NSString *text = textFieldAlertView.textField.text;
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            TKAlert(@"输入内存地址");
            return;
        } else if (![text hasPrefix:@"0x"] && ![text hasPrefix:@"0X"]) {
            text = [NSString stringWithFormat:@"0x%@", text];
        }
        unsigned long long address = strtoull([text UTF8String], NULL, 0);
        GMMemoryAccessObject *accessObject = [[GMMemManagerProxy shareInstance] getMemoryAccessObject:address];
        if (accessObject) {
            if (self.results == nil) {
                self.results = [NSArray array];
            }
            NSArray *results = [self.results arrayByAddingObject:@(address)];
            self.results = results;
            [self.tableView reloadData];
            
            GMModifyViewController *modifyViewController = [[GMModifyViewController alloc] initWithAddress:address];
            [self.navigationController pushViewController:modifyViewController animated:YES];
            [modifyViewController release];
        } else {
            TKAlert(@"地址不存在");
        }
    }];
    [textFieldAlertView show];
    [textFieldAlertView release];
}

- (void)storageKeyDidPressed {
    GMStorageViewController *storageViewController = [[GMStorageViewController alloc] init];
    [self.navigationController pushViewController:storageViewController animated:YES];
    [storageViewController release];
}

- (void)searchKeyDidPressed {
    UISearchBar *searchBar = self.searchBar;
    if (self.pid <= 0) {
        NSString *message = @"请选择应用";
        TKAlert(message);
    } else if (!searchBar.text.length) {
        
    } else {
        int value = [searchBar.text intValue];
        self.isSearching = YES;
        [self.tableView reloadData];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSArray *results = nil;
            UInt64 resultCount;
            BOOL ok = [[GMMemManagerProxy shareInstance] search:value isFirst:self.isFirst result:&results count:&resultCount];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (ok) {
                    self.resultCount = resultCount;
                    self.results = results;
                    self.isFirst = NO;
                    self.isSearching = NO;
                } else {
                    self.isSearching = NO;
                    TKAlert(@"程序已退出，请重新选择！");
                }
                [self.tableView reloadData];
            });
        });
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.isSearching) {
            return 1;
        } else {
            return self.results&&self.results.count==0?1:0;
        }
    } else {
        return [self.results count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
    // Configure the cell...
    if (indexPath.section == 0) {
        [cell.contentView removeAllSubviews];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (self.isSearching) {
            cell.textLabel.text = nil;
            UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 0, 20, 44)];
            loading.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            [loading startAnimating];
            [cell.contentView addSubview:loading];
            [loading release];
            cell.textLabel.text = @"       搜索中";
            cell.textLabel.font = [UIFont systemFontOfSize:16];
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"共搜索到%llu个结果", self.resultCount];
        }
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        NSNumber *addressObj = [self.results objectAtIndex:indexPath.row];
        unsigned long long address = [addressObj unsignedLongLongValue];
        GMMemoryAccessObject *accessObject = [[GMMemManagerProxy shareInstance] getMemoryAccessObject:address];
        uint64_t value = [accessObject value];
        NSString *text = [NSString stringWithFormat:@"%ld、0X%08llX:%llu", (long)indexPath.row, address, value];
        cell.textLabel.text = text;
    }
    return cell;
}

#pragma mark - Table view data delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section > 0) {
        NSNumber *address = [self.results objectAtIndex:indexPath.row];
        GMModifyViewController *modifyViewController = [[GMModifyViewController alloc] initWithAddress:[address unsignedLongLongValue]];
        [self.navigationController pushViewController:modifyViewController animated:YES];
        [modifyViewController release];
    }
}

#pragma mark - TKTextFieldAlertViewDelegate

- (BOOL)alertView:(TKTextFieldAlertView *)alertView shouldEnableButtonForIndex:(NSUInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *text = alertView.textField.text;
        text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return text.length;
    } else {
        return YES;
    }
}

#pragma mark - Private 

- (NSDictionary *)updateWithPid:(int)pid {
    NSDictionary *appInfo = [AppUtil appInfoForProcessID:pid];
    if (appInfo) {
        NSString *appName = [appInfo objectForKey:@"appName"];
        UIImage *appIcon = [appInfo objectForKey:@"appIcon"];
        [self updateWithPid:pid appName:appName appIcon:appIcon];
    }
    return nil;
}

- (void)updateWithPid:(int)pid appName:(NSString *)appName appIcon:(UIImage *)appIcon{
    GMSelectAppButton * selectAppButton = (GMSelectAppButton *)[self.navigationItem.rightBarButtonItem customView];
    selectAppButton.titleLabel.font = [UIFont systemFontOfSize:14];
    selectAppButton.titleLabel.textColor = [UIColor colorWith8bitRed:0 green:126 blue:245 alpha:255];
    selectAppButton.image = appIcon;
    selectAppButton.title = appName;
    
    [self startMonitorForProcess:pid];
    [[GMMemManagerProxy shareInstance] clearSearchData];
    
    self.pid = pid;
    self.results = nil;
    self.isFirst = YES;
    [self.tableView reloadData];
}

- (void)addSearchDisplayController {
    GMAssociateViewController *associateViewController = [[GMAssociateViewController alloc] init];
    SearchDisplayController *searchDisplayController = [[SearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self searchAssociateViewController:associateViewController];
    searchDisplayController.delegate = associateViewController;
    [searchDisplayController release];
    [associateViewController release];
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification {
    if(self.pid) {
        [self.tableView reloadData];
    }
}

- (void)invalidateTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)startTimer {
    [self invalidateTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(reloadData)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)reloadData {
    if (self.pid && self.results && !self.isSearching) {
        [self.tableView reloadData];
    }
}

- (void)startMonitorForProcess:(int)pid
{
    [self stopMonitor];
    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, pid, DISPATCH_PROC_EXIT, queue);
    self.source = source;
    if (source)
    {
        dispatch_source_set_event_handler(source, ^{
            self.pid = 0;
            [self resetSelectAppButton];
            TKAlert(@"程序已退出，请重新选择！");
            [self resetKeyDidPressed];
            [self stopMonitor];
        });
        dispatch_resume(source);
    }
}

- (void)stopMonitor {
    if (self.source) {
        dispatch_source_cancel(self.source);
        dispatch_release(self.source);
        self.source = nil;
    }
}

- (void)setting {
    GMSettingViewController *settingViewController = [[GMSettingViewController alloc] init];
    [self.navigationController pushViewController:settingViewController animated:YES];
    [settingViewController release];
}

- (void)resetSelectAppButton {
    GMSelectAppButton * selectAppButton = (GMSelectAppButton *)[self.navigationItem.rightBarButtonItem customView];
    selectAppButton.image = nil;
    selectAppButton.title = @"选择";
    selectAppButton.titleLabel.textColor = [UIColor colorWith8bitRed:0 green:126 blue:245 alpha:255];
    selectAppButton.titleLabel.font = [UIFont systemFontOfSize:17];
}

@end
