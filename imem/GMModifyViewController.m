//
//  GMModifyTableViewController.m
//  imem
//
//  Created by luobin on 14-7-19.
//
//

#import "GMModifyViewController.h"
#import "TextFieldTableViewCell.h"
#import "SimplePickerInputTableViewCell.h"
#import "GMMemManagerProxy.h"

@interface GMModifyViewController ()<UITextFieldDelegate, SimplePickerInputTableViewCellDelegate>

@property (nonatomic, assign) uint64_t address;
@property (nonatomic, retain) NSMutableDictionary *result;

@end

@implementation GMModifyViewController

- (id)initWithAddress:(uint64_t)address;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        self.address = address;
        self.title = [NSString stringWithFormat:@"0X%llX", address];
    }
    return self;
}

- (void)dealloc {
    self.result = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(save)] autorelease];
    
    NSDictionary *result = [[GMMemManagerProxy shareInstance] getResult:self.address];
    self.result = [NSMutableDictionary dictionaryWithDictionary:result];
}

- (void)save {
    BOOL ok = [[GMMemManagerProxy shareInstance] modifyMemory:self.result];
    if (ok) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        TKAlert(@"修改失败");
    }
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        static NSString *identifier = @"TextFieldTableViewCell";
        TextFieldTableViewCell *cell = (TextFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[[TextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabelWidth = 120.f;
        }
        cell.textLabel.text = @"名称";
        cell.textField.text = nil;
        return cell;
    } else if (indexPath.row == 1) {
        static NSString *identifier = @"SimplePickerInputTableViewCell";
        SimplePickerInputTableViewCell *cell = (SimplePickerInputTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[[SimplePickerInputTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.values = [NSArray arrayWithObjects:@"修改", @"修改并存储", @"修改并锁定", nil];
            cell.delegate = self;
        }
        cell.textLabel.text = @"操作";
        [cell setValue:@"修改"];
        return cell;
    } else if (indexPath.row == 2) {
        static NSString *identifier = @"TextFieldTableViewCell";
        TextFieldTableViewCell *cell = (TextFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[[TextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabelWidth = 120.f;
            cell.textField.delegate = self;
        }
        cell.textLabel.text = @"目标值";
        cell.textField.text = [NSString stringWithFormat:@"%d", [self.result value]];
        return cell;
    } else {
        static NSString *identifier = @"reuseIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = @"test";
        return cell;
    }
}

#pragma mark -  UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self.result setValue:@([text intValue]) forKey:kResultKeyValue];
    return YES;
}

#pragma mark - SimplePickerInputTableViewCellDelegate
- (void)tableViewCell:(SimplePickerInputTableViewCell *)cell didEndEditingAtIndex:(NSUInteger)index {
    if (index == 0) {
        
    } else if (index == 1) {
//        [self.result setObject:nil forKey:kResultKeyProtection];
    } else if (index == 2) {
        [self.result setObject:@(VM_PROT_READ) forKey:kResultKeyProtection];
    }
}

@end
