//
//  GMSettingViewController.m
//  imem
//
//  Created by luobin on 14-8-9.
//
//

#import "GMSettingViewController.h"

@interface GMSettingViewController ()

@end

@implementation GMSettingViewController

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
}

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];
	BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoConnect"];
	self.hiddenKeys = enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil];
}

#pragma mark -
#pragma mark IASKAppSettingsViewControllerDelegate protocol
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    [self dismissModalViewControllerAnimated:YES];
	
	// your code here to reconfigure the app for changed settings
}

// optional delegate method for handling mail sending result
- (void)settingsViewController:(id<IASKViewController>)settingsViewController mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    if ( error != nil ) {
        // handle error here
    }
    
    if ( result == MFMailComposeResultSent ) {
        // your code here to handle this result
    }
    else if ( result == MFMailComposeResultCancelled ) {
        // ...
    }
    else if ( result == MFMailComposeResultSaved ) {
        // ...
    }
    else if ( result == MFMailComposeResultFailed ) {
        // ...
    }
}
- (CGFloat)settingsViewController:(id<IASKViewController>)settingsViewController
                        tableView:(UITableView *)tableView
        heightForHeaderForSection:(NSInteger)section {
    NSString* key = [settingsViewController.settingsReader keyForSection:section];
	if ([key isEqualToString:@"IASKLogo"]) {
		return [UIImage imageNamed:@"Icon.png"].size.height + 25;
	} else if ([key isEqualToString:@"IASKCustomHeaderStyle"]) {
		return 55.f;
    }
	return 0;
}

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewController
                         tableView:(UITableView *)tableView
           viewForHeaderForSection:(NSInteger)section {
    NSString* key = [settingsViewController.settingsReader keyForSection:section];
	if ([key isEqualToString:@"IASKLogo"]) {
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon.png"]];
		imageView.contentMode = UIViewContentModeCenter;
		return imageView;
	} else if ([key isEqualToString:@"IASKCustomHeaderStyle"]) {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor redColor];
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        label.numberOfLines = 0;
        label.font = [UIFont boldSystemFontOfSize:16.f];
        
        //figure out the title from settingsbundle
        label.text = [settingsViewController.settingsReader titleForSection:section];
        
        return label;
    }
	return nil;
}

- (CGFloat)tableView:(UITableView*)tableView heightForSpecifier:(IASKSpecifier*)specifier {
	if ([specifier.key isEqualToString:@"customCell"]) {
		return 44*3;
	}
	return 0;
}

//- (UITableViewCell*)tableView:(UITableView*)tableView cellForSpecifier:(IASKSpecifier*)specifier {
//	CustomViewCell *cell = (CustomViewCell*)[tableView dequeueReusableCellWithIdentifier:specifier.key];
//	
//	if (!cell) {
//		cell = (CustomViewCell*)[[[NSBundle mainBundle] loadNibNamed:@"CustomViewCell"
//															   owner:self
//															 options:nil] objectAtIndex:0];
//	}
//	cell.textView.text= [[NSUserDefaults standardUserDefaults] objectForKey:specifier.key] != nil ?
//    [[NSUserDefaults standardUserDefaults] objectForKey:specifier.key] : [specifier defaultStringValue];
//	cell.textView.delegate = self;
//	[cell setNeedsLayout];
//	return cell;
//}

#pragma mark kIASKAppSettingChanged notification
- (void)settingDidChange:(NSNotification*)notification {
	if ([notification.object isEqual:@"AutoConnect"]) {
//		IASKAppSettingsViewController *activeController = self.tabBarController.selectedIndex ? self.tabAppSettingsViewController : self.appSettingsViewController;
//		BOOL enabled = (BOOL)[[notification.userInfo objectForKey:@"AutoConnect"] intValue];
//		[activeController setHiddenKeys:enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil] animated:YES];
	}
}

#pragma mark UITextViewDelegate (for CustomViewCell)
- (void)textViewDidChange:(UITextView *)textView {
    [[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:@"customCell"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged object:@"customCell"];
}

#pragma mark -
- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
	if ([specifier.key isEqualToString:@"ButtonDemoAction1"]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Demo Action 1 called" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	} else if ([specifier.key isEqualToString:@"ButtonDemoAction2"]) {
		NSString *newTitle = [[[NSUserDefaults standardUserDefaults] objectForKey:specifier.key] isEqualToString:@"Logout"] ? @"Login" : @"Logout";
		[[NSUserDefaults standardUserDefaults] setObject:newTitle forKey:specifier.key];
	}
}

@end
