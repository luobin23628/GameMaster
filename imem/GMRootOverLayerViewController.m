//
//  GMRootOverLayerViewController.m
//  imem
//
//  Created by LuoBin on 14-8-18.
//
//

#import "GMRootOverLayerViewController.h"
#import "UITAssistiveTouch.h"
#import "UIImage+Color.h"
#import "GMMainViewController.h"
#import "GMOverlayWindow.h"

static __attribute__((constructor)) void _logosLocalCtor_3d22e302() {
	@autoreleasepool {
        if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.ea.fifa14.bv"]
            || [[NSBundle mainBundle].bundleIdentifier hasPrefix:@"com.luobin"]) {
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
                GMRootOverLayerViewController *rootOverLayerViewController = [[GMRootOverLayerViewController alloc] init];
                GMOverlayWindow *window = [GMOverlayWindow defaultWindow];
//                [window addSubview:rootOverLayerViewController.view];
                window.rootViewController = rootOverLayerViewController;
//                [rootOverLayerViewController release];
//                [window setAutorotates:YES];
                window.userInteractionEnabled = YES;
                window.hidden = NO;
            }];
        }
    }
}


@interface NavigationController : UINavigationController

@end

@implementation NavigationController

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end


@interface GMRootOverLayerViewController ()

@end

@implementation GMRootOverLayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)shouldAutorotate {
    return YES;
}

//- (NSUInteger)supportedInterfaceOrientations {
//    return UIInterfaceOrientationMaskPortrait;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    
    UITAssistiveTouch *assistiveTouch = [[UITAssistiveTouch alloc] initWithIcon:[UIImage buttonImageWithColor:[UIColor redColor] cornerRadius:0 shadowColor:nil shadowInsets:UIEdgeInsetsZero] highLightIcon:[UIImage imageNamed:@""]];
    __block id selfObj = self;
    assistiveTouch.touchHandle = ^(id pAssistiveTouch) {
        [[GMOverlayWindow defaultWindow] makeKeyAndVisible];
        static UINavigationController *nav = nil;
        if (!nav) {
            GMMainViewController *mainViewController = [[GMMainViewController alloc] init];
            mainViewController.shouldSelectProcess = NO;
            nav = [[UINavigationController alloc] initWithRootViewController:mainViewController];
            mainViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:selfObj action:@selector(dismiss)];
            [mainViewController release];
        }
        [selfObj presentViewController:nav animated:YES completion:nil];
    };
    [assistiveTouch showInView:self.view];
}

- (void)dismiss {
    [[GMOverlayWindow defaultWindow] resignKeyWindow];
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
