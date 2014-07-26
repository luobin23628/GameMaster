//
//  GMSelectAppButton.m
//  imem
//
//  Created by luobin on 14-7-26.
//
//

#import "GMSelectAppButton.h"
#import "UIView+Sizes.h"

@interface GMSelectAppButton()

@property (nonatomic, readwrite, retain) UIImageView *imageView;
@property (nonatomic, readwrite, retain) UILabel *titleLabel;

@end

@implementation GMSelectAppButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGFloat imageHeight = 20;
        CGFloat height = frame.size.height;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, height/2 - imageHeight/2, imageHeight, imageHeight)];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.backgroundColor = [UIColor clearColor];
        self.imageView = imageView;
        [self addSubview:imageView];
        [imageView release];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.right + 5, imageView.top, 65, imageHeight)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
        self.titleLabel = titleLabel;
        [self addSubview:titleLabel];
        [titleLabel release];
    }
    return self;
}

- (void)dealloc {
    self.imageView = nil;
    self.titleLabel = nil;
    [super dealloc];
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self layoutSubviews];
}

- (NSString *)title {
    return self.titleLabel.text;
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    [self layoutSubviews];
}

- (UIImage *)image {
    return self.imageView.image;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return size;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat x;
    if (self.image) {
        self.imageView.hidden = NO;
        x = self.imageView.right;
    } else {
        self.imageView.hidden = YES;
        x = 0;
    }
    
    CGSize size = [self.titleLabel sizeThatFits:CGSizeMake(80, 15)];
    CGRect frame = self.titleLabel.frame;
    frame.origin.x = x + 5;
    frame.size.width = size.width;
    self.titleLabel.frame = frame;
    
    CGRect bounds = self.bounds;
    bounds.size.width = CGRectGetMaxX(frame);
    self.bounds = bounds;
    
    if (self.isHighlighted) {
        self.titleLabel.textColor = [self.titleLabel.textColor colorWithAlphaComponent:0.3];
    } else {
        self.titleLabel.textColor = [self.titleLabel.textColor colorWithAlphaComponent:1];
    }
}

@end
