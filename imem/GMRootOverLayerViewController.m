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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    
    UITAssistiveTouch *assistiveTouch = [[UITAssistiveTouch alloc] initWithIcon:[UIImage buttonImageWithColor:[UIColor redColor] cornerRadius:0 shadowColor:nil shadowInsets:UIEdgeInsetsZero] highLightIcon:[UIImage imageNamed:@""]];
    MAWeakSelfDeclare();
    assistiveTouch.touchHandle = ^(id pAssistiveTouch) {
        MAWeakSelfImportReturn();
        GMMainViewController *mainViewController = [[GMMainViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mainViewController];
        mainViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
        [self presentViewController:nav animated:YES completion:nil];
        [nav release];
        [mainViewController release];
    };
    [assistiveTouch showInView:self.view];
}

- (void)dismiss {
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
