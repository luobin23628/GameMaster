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
#import "GMMemManagerProxy.h"

static __attribute__((constructor)) void _logosLocalCtor_3d22e302() {
	@autoreleasepool {
        NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
        if (![bundleIdentifier isEqualToString:@"com.apple.springboard"] &&  [[[GMMemManagerProxy shareInstance] getAppIdentifiers] containsObject:bundleIdentifier]) {
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
                GMRootOverLayerViewController *rootOverLayerViewController = [[GMRootOverLayerViewController alloc] init];
                GMOverlayWindow *window = [GMOverlayWindow defaultWindow];
                window.rootViewController = rootOverLayerViewController;
                window.userInteractionEnabled = YES;
                window.hidden = NO;
                
                pid_t pid = getpid();
                [[GMMemManagerProxy shareInstance] setPid:pid];
            }];
        }
        if (![bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
                if ([[[GMMemManagerProxy shareInstance] getAppIdentifiers] containsObject:bundleIdentifier]) {
                    GMRootOverLayerViewController *rootOverLayerViewController = [[GMRootOverLayerViewController alloc] init];
                    GMOverlayWindow *window = [GMOverlayWindow defaultWindow];
                    window.rootViewController = rootOverLayerViewController;
                    window.userInteractionEnabled = YES;
                    window.hidden = NO;
                    
                    pid_t pid = getpid();
                    if (pid != [[GMMemManagerProxy shareInstance] getPid]) {
                        [[GMMemManagerProxy shareInstance] setPid:pid];
                    }
                } else {
                    [GMOverlayWindow cleanUp];
                    pid_t pid = getpid();
                    if (pid == [[GMMemManagerProxy shareInstance] getPid]) {
                        [[GMMemManagerProxy shareInstance] reset];
                    }
                }
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

- (BOOL)shouldAutorotate {
    return NO;
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
