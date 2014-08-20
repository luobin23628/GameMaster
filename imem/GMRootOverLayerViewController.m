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
    [assistiveTouch showInView:self.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
