//
//  ZZAppDelegate.m
//  PayPal-iOS-SDK-Sample-App
//
//  Copyright (c) 2014, PayPal
//  All rights reserved.
//

#import "ZZAppDelegate.h"
#import "PayPalMobile.h"

@implementation ZZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

//#warning "Enter your credentials"
  [PayPalMobile initializeWithClientIdsForEnvironments:@{PayPalEnvironmentProduction : @"XXXXXXXXXXX",
                                                         PayPalEnvironmentSandbox : @"Acz3G7kG9afqvZF7PJNw-hZvw_F9INQPnZGnSVbclnydHjpK53GxFkW67Wf76FbR8ZzbW_RB3Rznnckq"}];
  return YES;
}

@end
