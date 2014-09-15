//
//  GMSelectProcessViewController2TableViewController.h
//  GameMaster
//
//  Created by luobin on 14-7-5.
//
//

#import <UIKit/UIKit.h>

@interface GMListViewController : UITableViewController

@property (nonatomic, copy) void(^didSelectProcessBlock)(UIImage *appIcon, NSString *appName, int pid);

@end
