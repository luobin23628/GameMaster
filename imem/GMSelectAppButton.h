//
//  GMSelectAppButton.h
//  imem
//
//  Created by luobin on 14-7-26.
//
//

#import <UIKit/UIKit.h>

@interface GMSelectAppButton : UIControl

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) UIImage *image;

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UILabel *titleLabel;

@end
