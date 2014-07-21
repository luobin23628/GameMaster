//
//  IntegerInputTableViewCell.m
//  InputTest
//
//  Created by Tom Fewster on 18/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TextFieldTableViewCell.h"

#define xSpacing 10.f

@implementation TextFieldTableViewCell

@synthesize textField, textLabelWidth, editEnabled;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle // note that it's forced to use UITableViewCellStyleSubtitle
					reuseIdentifier:reuseIdentifier]) {
        
		self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        textField = [[UITextField alloc] initWithFrame:CGRectZero];
		textField.clearsOnBeginEditing = NO;
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		textField.font = [UIFont systemFontOfSize:15.0f];
		self.textLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
		[self.contentView addSubview:textField];
        
		self.contentView.backgroundColor  = [UIColor clearColor];
		self.textLabel.font = [UIFont systemFontOfSize:15.0f];
		self.textLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        
		self.editEnabled = YES;
	}
    return self;
}

- (UIView *)inputAccessoryView {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return nil;
	} else {
		if (!inputAccessoryView) {
			inputAccessoryView = [[UIToolbar alloc] init];
			inputAccessoryView.barStyle = UIBarStyleBlackTranslucent;
			inputAccessoryView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
			[inputAccessoryView sizeToFit];
			CGRect frame = inputAccessoryView.frame;
			frame.size.height = 44.0f;
			inputAccessoryView.frame = frame;
			
			UIBarButtonItem *doneBtn =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
			UIBarButtonItem *flexibleSpaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
			
			NSArray *array = [NSArray arrayWithObjects:flexibleSpaceLeft, doneBtn, nil];
            [flexibleSpaceLeft release];
            [doneBtn release];
			[inputAccessoryView setItems:array];
		}
		return inputAccessoryView;
	}
}

- (void)done:(id)sender {
    [self.textField resignFirstResponder];
	[self resignFirstResponder];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (textLabelWidth) {
		CGRect textLabelFrame = self.textLabel.frame;
		textLabelFrame.size.width = textLabelWidth;
		self.textLabel.frame = textLabelFrame;
		self.textLabel.adjustsFontSizeToFitWidth = YES;
	}
	if (self.textLabel.text) {
		textField.frame = CGRectMake(CGRectGetMaxX(self.textLabel.frame) + xSpacing, 0,
									 self.contentView.frame.size.width - CGRectGetMaxX(self.textLabel.frame) - (xSpacing * 2),
									 self.contentView.frame.size.height);
	} else {
		textField.frame = CGRectMake(xSpacing, 0, self.contentView.frame.size.width - (xSpacing * 2), self.contentView.frame.size.height);
	}
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
	if (!editEnabled){
		self.textField.enabled = editing;
	}
}

- (void)dealloc {
    [inputAccessoryView release];
	[textField release];
    [super dealloc];
}

@end
