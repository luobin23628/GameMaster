//
//  GMKeyboard.m
//  imem
//
//  Created by luobin on 14-7-20.
//
//

#import "GMKeyboard.h"
#import "GMGridLinesTexturedView.h"

@interface GMKeyboard()

@property (nonatomic,assign) id<UITextInput> textInputDelegate;
@property (nonatomic,assign) GMGridLinesTexturedView *texturedView;

@end;

@implementation GMKeyboard

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.texturedView = [[[GMGridLinesTexturedView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)] autorelease];
        self.texturedView.backgroundColor = [UIColor colorWithWhite:251/255.0 alpha:1];
        [self addSubview:self.texturedView];
        
        CGFloat y = 0;
        [self addSubview:[self addNumericKeyWithTitle:@"1" frame:CGRectMake(0, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addNumericKeyWithTitle:@"2" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH , y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addNumericKeyWithTitle:@"3" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 2, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addNumericKeyWithTitle:@"4" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 3, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addStringKeyWithTitle:@"搜索" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 4, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        
        y = KEYBOARD_NUMERIC_KEY_HEIGHT * 1;
        [self addSubview:[self addNumericKeyWithTitle:@"5" frame:CGRectMake(0, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addNumericKeyWithTitle:@"6" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addNumericKeyWithTitle:@"7" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 2, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addNumericKeyWithTitle:@"8" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 3, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addStringKeyWithTitle:@"重置" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 4, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        
        y = KEYBOARD_NUMERIC_KEY_HEIGHT * 2;
        [self addSubview:[self addNumericKeyWithTitle:@"." frame:CGRectMake(0, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addNumericKeyWithTitle:@"9" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addNumericKeyWithTitle:@"0" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 2, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addBackspaceKeyWithFrame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 3, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
        [self addSubview:[self addStringKeyWithTitle:@"存储" frame:CGRectMake(KEYBOARD_NUMERIC_KEY_WIDTH * 4, y, KEYBOARD_NUMERIC_KEY_WIDTH, KEYBOARD_NUMERIC_KEY_HEIGHT)]];
    }
    
    return self;
}

- (void)dealloc {
    self.texturedView = nil;
    [super dealloc];
}

- (UIButton *)addStringKeyWithTitle:(NSString *)title frame:(CGRect)frame {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    [button setTitle:title forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:20.0]];
    
    [button setTitleColor:[UIColor colorWithWhite:24/255.0 alpha:1] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:24/255.0 alpha:1] forState:UIControlStateHighlighted];
    [button setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    [button.titleLabel setShadowOffset:CGSizeMake(0, -0.5)];
    
    [button addTarget:self action:@selector(pressStringKey:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)pressStringKey:(UIButton *)button {
    NSString *keyText = button.titleLabel.text;
    int key = 0;
    if ([@"重置" isEqualToString:keyText]) {
        key = 11;
    } else if ([@"存储" isEqualToString:keyText]) {
        key = 12;
    } else if ([@"搜索" isEqualToString:keyText]) {
        key = 13;
    }
    switch (key) {
        case 11:
            if ([self.delegate respondsToSelector:@selector(resetKeyDidPressed)]) {
                [self.delegate resetKeyDidPressed];
            }
            break;
        case 12:
            if ([self.delegate respondsToSelector:@selector(storageKeyDidPressed)]) {
                [self.delegate storageKeyDidPressed];
            }
            break;
        case 13:
            if ([self.delegate respondsToSelector:@selector(searchKeyDidPressed)]) {
                [self.delegate searchKeyDidPressed];
            }
            break;
        default:
            break;
    }
}

- (UIButton *)addNumericKeyWithTitle:(NSString *)title frame:(CGRect)frame {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    [button setTitle:title forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:24.0]];
    
    [button setTitleColor:[UIColor colorWithWhite:24/255.0 alpha:1] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:24/255.0 alpha:1] forState:UIControlStateHighlighted];
    [button setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    [button.titleLabel setShadowOffset:CGSizeMake(0, -0.5)];
    
    [button addTarget:self action:@selector(pressNumericKey:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (UIButton *)addBackspaceKeyWithFrame:(CGRect)frame {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    UIImage *image = [UIImage imageNamed:@"KeyboardNumericBackspace"];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(pressBackspaceKey) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)setTextField:(UITextField *)textField {
    _textField = textField;
    _textField.inputView = self;
    self.textInputDelegate = _textField;
}

- (void)pressNumericKey:(UIButton *)button {
    NSString *keyText = button.titleLabel.text;
    int key = -1;
    
    if ([@"." isEqualToString:keyText]) {
        key = 10;
    } else {
        key = [keyText intValue];
    }
    
    NSRange dot = [_textField.text rangeOfString:@"."];
    
    switch (key) {
        case 10:
            if (dot.location == NSNotFound && _textField.text.length == 0) {
                [self.textInputDelegate insertText:@"0."];
            } else if (dot.location == NSNotFound) {
                [self.textInputDelegate insertText:@"."];
            }
            break;
        default:
            if (kMaxNumber <= [[NSString stringWithFormat:@"%@%d", _textField.text, key] doubleValue]) {
                _textField.text = [NSString stringWithFormat:@"%d", kMaxNumber];
            } else if ([@"0.00" isEqualToString:_textField.text]) {
                _textField.text = [NSString stringWithFormat:@"%d", key];
            } else if (dot.location == NSNotFound || _textField.text.length <= dot.location + 2) {
                [self.textInputDelegate insertText:[NSString stringWithFormat:@"%d", key]];
            }
            if ([self.delegate respondsToSelector:@selector(numericKeyDidPressed:)]) {
                [self.delegate numericKeyDidPressed:key];
            }
            break;
    }
}

- (void)pressBackspaceKey {
    if ([@"0." isEqualToString:_textField.text]) {
        _textField.text = @"";
        
        return;
    } else {
        [self.textInputDelegate deleteBackward];
    }
    if ([self.delegate respondsToSelector:@selector(backspaceKeyDidPressed)]) {
        [self.delegate backspaceKeyDidPressed];
    }
}

@end

