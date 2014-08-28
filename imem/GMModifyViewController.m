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
#import "TKKeyboard.h"
#import "GMMemoryAccessObject.h"

@interface GMModifyViewController ()<UITextFieldDelegate, SimplePickerInputTableViewCellDelegate>

@property (nonatomic, assign) uint64_t address;
@property (nonatomic, retain) GMMemoryAccessObject *accessObject;

@end

@implementation GMModifyViewController

- (id)initWithAddress:(uint64_t)address;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        self.address = address;
        self.title = [NSString stringWithFormat:@"0X%08llX", address];
        self.defaultOptType = GMOptTypeEdit;
    }
    return self;
}

- (void)dealloc {
    self.didModifyBlock = nil;
    self.accessObject = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(save)] autorelease];
    
    self.accessObject = [[GMMemManagerProxy shareInstance] getMemoryAccessObject:self.address];
    self.accessObject.optType = self.defaultOptType;
}

- (void)save {
    BOOL ok = [[GMMemManagerProxy shareInstance] modifyMemory:self.accessObject];
    if (ok) {
        if (self.didModifyBlock) {
            self.didModifyBlock(self.accessObject);
        }
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
            cell.textField.clearButtonMode = UITextFieldViewModeAlways;
            cell.textField.textAlignment = NSTextAlignmentRight;
        }
        cell.textLabelWidth = 80.f;
        cell.textLabel.text = @"名称";
        cell.textField.text = nil;
        return cell;
    } else if (indexPath.row == 1) {
        static NSString *identifier = @"SimplePickerInputTableViewCell";
        SimplePickerInputTableViewCell *cell = (SimplePickerInputTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        NSArray *array = [NSArray arrayWithObjects:@"修改", @"修改并存储", @"修改并锁定", nil];
        if (!cell) {
            cell = [[[SimplePickerInputTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.values = array;
            cell.delegate = self;
        }
        cell.value = [array objectAtIndex:self.defaultOptType];
        if (self.defaultOptType != GMOptTypeEdit) {
            cell.userInteractionEnabled = NO;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        cell.textLabel.text = @"操作";
        return cell;
    } else if (indexPath.row == 2) {
        static NSString *identifier = @"TextFieldTableViewCell";
        TextFieldTableViewCell *cell = (TextFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[[TextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textField.delegate = self;
            cell.textField.textAlignment = NSTextAlignmentRight;
            cell.textField.clearButtonMode = UITextFieldViewModeAlways;
            cell.textField.keyboardType = TKKeyboardTypeUIntegerPad;
        }
        cell.textLabelWidth = 150.f;
        NSString *region;
        if (self.accessObject.valueType == GMValueTypeInt16) {
            region = [NSString stringWithFormat:@"(0-%u)", UINT16_MAX];
        } else if (self.accessObject.valueType == GMValueTypeInt32) {
            region = [NSString stringWithFormat:@"(0-%u)", UINT32_MAX];
        } else if (self.accessObject.valueType == GMValueTypeInt64) {
            region = [NSString stringWithFormat:@"(0-%llu)", UINT64_MAX];
        } else if (self.accessObject.valueType == GMValueTypeFloat) {
            region = [NSString stringWithFormat:@"(0-%.f)", CGFLOAT_MAX];
        } else {
            region = @"";
        }
        cell.textLabel.text = [NSString stringWithFormat:@"目标值%@", region];
        cell.textField.text = [NSString stringWithFormat:@"%lld", [self.accessObject value]];
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
    [self.accessObject setValue:[text intValue]];
    return YES;
}

#pragma mark - SimplePickerInputTableViewCellDelegate
- (void)tableViewCell:(SimplePickerInputTableViewCell *)cell didEndEditingAtIndex:(NSUInteger)index {
    [self.accessObject setOptType:index];
}

@end
