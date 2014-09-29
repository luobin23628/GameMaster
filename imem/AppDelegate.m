//
//  AppDelegate.m
//  GameMaster
//
//  Created by LuoBin on 14-7-4.
//
//

#import "AppDelegate.h"
#import "GMMainViewController.h"
#import "TKKeyboard.h"
#import "MobClick.h"
#import "GMRootOverLayerViewController.h"
#import "GMOverlayWindow.h"
#import "GMListViewController.h"

#define UMENG_APPKEY @"53e5fee6fd98c5e65201cb7c"

@implementation AppDelegate

- (void)umengTrack {
    [MobClick setCrashReportEnabled:YES]; // 如果不需要捕捉异常，注释掉此行
#if __OPTIMIZE__
    [MobClick setLogEnabled:NO];
#else
    [MobClick setLogEnabled:YES];
#endif
    [MobClick setAppVersion:XcodeAppVersion]; //参数为NSString * 类型,自定义app版本信息，如果不设置，默认从CFBundleVersion里取
    
    [MobClick startWithAppkey:UMENG_APPKEY reportPolicy:(ReportPolicy) REALTIME channelId:nil];
    //   reportPolicy为枚举类型,可以为 REALTIME, BATCH,SENDDAILY,SENDWIFIONLY几种
    //   channelId 为NSString * 类型，channelId 为nil或@""时,默认会被被当作@"App Store"渠道
    
    [MobClick checkUpdate];   //自动更新检查, 如果需要自定义更新请使用下面的方法,需要接收一个(NSDictionary *)appInfo的参数
    //    [MobClick checkUpdateWithDelegate:self selector:@selector(updateMethod:)];
    
    [MobClick updateOnlineConfig];  //在线参数配置

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onlineConfigCallBack:) name:UMOnlineConfigDidFinishedNotification object:nil];
}

- (void)onlineConfigCallBack:(NSNotification *)note {
    NSLog(@"online config has fininshed and note = %@", note.userInfo);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self umengTrack];
    NSLog(@"didFinishLaunchingWithOptions");

    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    /*
    GMMainViewController *mainViewController = [[GMMainViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    self.window.rootViewController = nav;
    [nav release];
    [mainViewController release];
    */
    
    GMListViewController *listViewController = [[GMListViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:listViewController];
    self.window.rootViewController = nav;
    [nav release];
    [listViewController release];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
