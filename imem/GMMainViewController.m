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
#import <UI7Kit/UI7Kit.h>

#define CellMAXCount 99

@interface GMMainViewController ()<UISearchBarDelegate, GMKeyboardDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) UITableView *tableView;

@property (nonatomic, assign) int pid;
@property (nonatomic, retain) NSArray *results;
@property (nonatomic, assign) UInt64 resultCount;
@property (nonatomic, assign) BOOL isFirst;
@property (nonatomic, assign) UISearchBar *searchBar;

@end

@implementation GMMainViewController

- (void)gotoSelectProcess {
    GMSelectAppViewController *selectProcessViewController = [[GMSelectAppViewController alloc] init];
    selectProcessViewController.didSelectProcessBlock = ^(UIImage *appIcon, NSString *appName, int pid) {
        BOOL ok = NO;
        if (pid > 0) {
            self.pid = pid;
            GMSelectAppButton * selectAppButton = (GMSelectAppButton *)[self.navigationItem.rightBarButtonItem customView];
            selectAppButton.titleLabel.font = [UIFont systemFontOfSize:14];
            selectAppButton.titleLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
            selectAppButton.image = appIcon;
            selectAppButton.title = [NSString stringWithFormat:@"%@", appName];
            ok = [[GMMemManagerProxy shareInstance] setPid:pid];
        }
        if (!ok) {
            TKAlert(@"选择的程序无法修改，请重新选择！");
        } else {
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
    self.searchBar = nil;
    self.tableView = nil;
    self.results = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.searchBar becomeFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"关于" style:UIBarButtonItemStylePlain target:self action:@selector(abount)] autorelease];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    self.tableView = tableView;
    [self.view addSubview:tableView];
    [tableView release];
    
    UISearchBar *searchBar = [[UISearchBar alloc]
                              initWithFrame:CGRectMake(0.0, [UIDevice currentDevice].isIOS7?64:0, self.view.bounds.size.width, 44)];
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
    
    self.keyboardView = [[[GMKeyboard alloc] initWithFrame:CGRectMake(0, 0, 320, 159)] autorelease];
    self.keyboardView.textField = (UITextField *)[searchBar descendantOrSelfWithClass:UITextField.class];
    self.keyboardView.delegate = self;
    
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(44, 0, 159, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset = edgeInsets;
}

#pragma mark - 
- (void)resetKeyDidPressed {
    [[GMMemManagerProxy shareInstance] reset];
    self.results = nil;
    self.resultCount = 0;
    self.isFirst = YES;
    [self.tableView reloadData];
    self.searchBar.text = @"";
}

- (void)storageKeyDidPressed {
    
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
                    TKAlert(@"查询失败");
                }
            });
        });
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.results?([self.results count] + 1):0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
    // Configure the cell...
    if (indexPath.row == 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = [NSString stringWithFormat:@"共搜索到%llu个结果", self.resultCount];
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        NSNumber *addressObj = [self.results objectAtIndex:indexPath.row - 1];
        unsigned long long address = [addressObj unsignedLongLongValue];
        NSDictionary *result = [[GMMemManagerProxy shareInstance] getResult:address];
        uint64_t value = [result value];
        NSString *text = [NSString stringWithFormat:@"%2ld 0X%llX:%llu", (long)indexPath.row, address, value];
        cell.textLabel.text = text;
    }
    return cell;
}

#pragma mark - Table view data delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row > 0) {
        NSNumber *address = [self.results objectAtIndex:indexPath.row - 1];
        GMModifyViewController *modifyViewController = [[GMModifyViewController alloc] initWithAddress:[address unsignedLongLongValue]];
        [self.navigationController pushViewController:modifyViewController animated:YES];
        [modifyViewController release];
    }
}

#pragma mark - Private 

- (void)abount {
    
}


@end
