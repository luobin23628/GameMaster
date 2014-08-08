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

#define CellMAXCount 99
#define TKKeyboardTypeMain (120)


@interface GMMainViewController ()<UISearchBarDelegate, GMKeyboardDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) UITableView *tableView;

@property (nonatomic, assign) int pid;
@property (nonatomic, retain) NSArray *results;
@property (nonatomic, assign) UInt64 resultCount;
@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) dispatch_source_t source;

@end

@implementation GMMainViewController

+(void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [GMMainViewController initKeyboard];
    });
}

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
            GMSelectAppButton * selectAppButton = (GMSelectAppButton *)[self.navigationItem.rightBarButtonItem customView];
            selectAppButton.titleLabel.font = [UIFont systemFontOfSize:14];
            selectAppButton.titleLabel.textColor = [UI7Color defaultTintColor];
            selectAppButton.image = appIcon;
            selectAppButton.title = [NSString stringWithFormat:@"%@", appName];
            
            [self startMonitorForProcess:pid];
            
            self.results = nil;
            self.isFirst = YES;
            [self.tableView reloadData];
        }
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:selectProcessViewController];
    [self.navigationController pushViewController:selectProcessViewController animated:YES];
    [nav release];
    [selectProcessViewController release];
}

+ (void)initKeyboard {
    TKKeyboardConfiguration *configiration = [[TKKeyboardConfiguration alloc] init];
    configiration.keyboardType = TKKeyboardTypeMain;
    configiration.keyboardHeight = 216;
    configiration.backgroundColor = [UIColor colorWithWhite:179/255.0 alpha:1];
    
    NSMutableArray *keyItems = [NSMutableArray array];
    for (int i = 1; i < 5; i++) {
        TKKeyItem *keyItem = [[TKKeyItem alloc] initWithInsertText:[NSString stringWithFormat:@"%d", i]];
        [keyItems addObject:keyItem];
        [keyItem release];
    }
    
    TKKeyItem *keyItem;
    
    keyItem = [[TKKeyItem alloc] initWithTitle:@"重  置" action:^(id<TKTextInput> textInput, TKKeyItem *keyItem) {
        
    }];
    [keyItems addObject:keyItem];
    [keyItem release];
    
    for (int i = 5; i < 9; i++) {
        TKKeyItem *keyItem = [[TKKeyItem alloc] initWithInsertText:[NSString stringWithFormat:@"%d", i]];
        [keyItems addObject:keyItem];
        [keyItem release];
    }
    
    keyItem = [[TKKeyItem alloc] initWithTitle:@"搜  索" action:^(id<TKTextInput> textInput, TKKeyItem *keyItem) {
        
    }];
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
    
    TKFlowLayout *layout = [[TKFlowLayout alloc] initWithSizeForIndexBlock:^CGSize(NSUInteger index, TKFlowLayout *layout, UIView *container) {
        int row = 3, column = 5;
        
        CGFloat innerWidth = (container.frame.size.width - layout.padding*2  - (column - 1) *layout.spacing);
        CGFloat innerHeight = (container.frame.size.height - layout.padding*2 - (row - 1) *layout.spacing);
        CGFloat width = innerWidth/column;
        CGFloat height = innerHeight/row;
        if (index == 9) {
            return CGSizeMake(width, height * 2);
        } else {
            return CGSizeMake(width, height);
        }
        
    }];
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
        GMSelectAppButton * selectAppButton = [[GMSelectAppButton alloc] init];
        selectAppButton.title = @"选择";
        selectAppButton.titleLabel.textColor = [UI7Color defaultTintColor];
        ;
        selectAppButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [selectAppButton addTarget:self action:@selector(gotoSelectProcess) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:selectAppButton] autorelease];
        [selectAppButton release];
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self invalidateTimer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"关于" style:UIBarButtonItemStylePlain target:self action:@selector(abount)] autorelease];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    self.tableView = tableView;
    [self.view addSubview:tableView];
    [tableView release];
    
    UISearchBar *searchBar = [[UISearchBar alloc]
                              initWithFrame:CGRectMake(0.0, [UIDevice currentDevice].isIOS7?64:0, self.view.bounds.size.width, 44)];
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
    
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(44, 0, 159, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset = edgeInsets;
    
    [searchBar becomeFirstResponder];
//    [self addSearchDisplayController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
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

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.searchBar.top = self.navigationController.navigationBar.bottom;
}

#pragma mark - KeyBoard
- (void)resetKeyDidPressed {
    [[GMMemManagerProxy shareInstance] reset];
    self.results = nil;
    self.resultCount = 0;
    self.isFirst = YES;
    [self.tableView reloadData];
    self.searchBar.text = @"";
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSArray *results = nil;
            UInt64 resultCount;
            BOOL ok = [[GMMemManagerProxy shareInstance] search:value isFirst:self.isFirst result:&results count:&resultCount];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (ok) {
                    self.resultCount = resultCount;
                    self.results = results;
                    self.isFirst = NO;
                    [self.tableView reloadData];
                } else {
                    TKAlert(@"程序已退出，请重新选择！");
                }
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
        return self.results?1:0;
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = [NSString stringWithFormat:@"共搜索到%llu个结果", self.resultCount];
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

#pragma mark - Private 

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
    if (self.pid && self.results) {
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

- (void)abount {

}

- (void)resetSelectAppButton {
    GMSelectAppButton * selectAppButton = (GMSelectAppButton *)[self.navigationItem.rightBarButtonItem customView];
    selectAppButton.image = nil;
    selectAppButton.title = @"选择";
    selectAppButton.titleLabel.textColor = [UI7Color defaultTintColor];
    selectAppButton.titleLabel.font = [UIFont systemFontOfSize:17];
}

@end
