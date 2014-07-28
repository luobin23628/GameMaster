//
//  SimplePickerInputTableViewCell.m
//  PickerCellDemo
//
//  Created by Tom Fewster on 10/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SimplePickerInputTableViewCell.h"

@implementation SimplePickerInputTableViewCell

@synthesize delegate;
@synthesize value;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
		self.picker.delegate = self;
		self.picker.dataSource = self;
        self.picker.backgroundColor = [UIColor colorWithWhite:251/255.0 alpha:1];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
		self.picker.delegate = self;
		self.picker.dataSource = self;
        self.picker.backgroundColor = [UIColor colorWithWhite:251/255.0 alpha:1];
    }
    return self;
}

- (void)dealloc {
    self.values = nil;
    [value release];
    value = nil;
    [super dealloc];
}

- (void)setValue:(NSString *)v {
	value = v;
	self.detailTextLabel.text = value;
	[self.picker selectRow:[self.values indexOfObject:value] inComponent:0 animated:YES];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [self.values count];
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [self.values objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
	return 44.0f;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
	return 300.0f; //pickerView.bounds.size.width - 20.0f;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	self.value = [self.values objectAtIndex:row];
    self.detailTextLabel.text = self.value;
    self.detailTextLabel.textColor = [UIColor blackColor];
    
	if (delegate && [delegate respondsToSelector:@selector(tableViewCell:didEndEditingAtIndex:)]) {
		[delegate tableViewCell:self didEndEditingAtIndex:row];
	}
}

@end
