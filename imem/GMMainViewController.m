//
//  GMMainViewController.m
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import "GMMainViewController.h"
#import "GMSelectProcessViewController.h"
#import "GMMemManagerProxy.h"
#import "GMModifyViewController.h"
#import "UIView+Sizes.h"
#import "GMStorageViewController.h"

#define CellMAXCount 99

@interface GMMainViewController ()<UISearchBarDelegate, GMKeyboardDelegate>

@property (nonatomic, assign) int pid;
@property (nonatomic, retain) NSArray *results;
@property (nonatomic, assign) UInt64 resultCount;
@property (nonatomic, assign) BOOL isFirst;

@end

@implementation GMMainViewController

- (void)gotoSelectProcess {
    GMSelectProcessViewController *selectProcessViewController = [[GMSelectProcessViewController alloc] init];
    selectProcessViewController.didSelectProcessBlock = ^(int pid) {
        BOOL ok = NO;
        if (pid > 0) {
            self.pid = pid;
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
    [self.navigationController presentViewController:nav animated:YES completion:nil];
    [nav release];
    [selectProcessViewController release];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"选择程序" style:UIBarButtonItemStylePlain target:self action:@selector(gotoSelectProcess)] autorelease];
    }
    return self;
}

- (void)dealloc {
    self.results = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UISearchBar *mySearchBar = [[UISearchBar alloc]
                                initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 45)];
    mySearchBar.delegate = self;
    mySearchBar.showsSearchResultsButton = YES;
    mySearchBar.showsCancelButton = NO;
    mySearchBar.barStyle = UIBarStyleDefault;
    mySearchBar.placeholder = @"输入要搜索的值";
    mySearchBar.keyboardType = UIKeyboardTypeNamePhonePad;
    self.tableView.tableHeaderView = mySearchBar;
    [mySearchBar release];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.keyboardView = [[[GMKeyboard alloc] initWithFrame:CGRectMake(0, 0, 320, 159)] autorelease];
    self.keyboardView.textField = (UITextField *)[mySearchBar descendantOrSelfWithClass:UITextField.class];
    self.keyboardView.delegate = self;
}

#pragma mark - 
- (void)resetKeyDidPressed {
    [[GMMemManagerProxy shareInstance] reset];
    self.results = nil;
    self.resultCount = 0;
    self.isFirst = YES;
    [self.tableView reloadData];
    UISearchBar *searchBar = (UISearchBar *)self.tableView.tableHeaderView;
    searchBar.text = @"";
}

- (void)storageKeyDidPressed {
    
}

- (void)searchKeyDidPressed {
    UISearchBar *searchBar = (UISearchBar *)self.tableView.tableHeaderView;
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
    if (indexPath.row > 0) {
        NSNumber *address = [self.results objectAtIndex:indexPath.row - 1];
        GMModifyViewController *modifyViewController = [[GMModifyViewController alloc] initWithAddress:[address unsignedLongLongValue]];
        [self.navigationController pushViewController:modifyViewController animated:YES];
        [modifyViewController release];
    }
}

@end
