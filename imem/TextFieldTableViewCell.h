//
//  IntegerInputTableViewCell.h
//  InputTest
//
//  Created by Tom Fewster on 18/10/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextFieldTableViewCell : UITableViewCell {
    UIToolbar *inputAccessoryView;
}

@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, assign) int textLabelWidth;
@property (nonatomic, assign) BOOL editEnabled;

@end
