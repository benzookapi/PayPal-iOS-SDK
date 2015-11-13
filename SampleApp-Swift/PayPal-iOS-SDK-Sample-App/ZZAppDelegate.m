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
  [PayPalMobile initializeWithClientIdsForEnvironments:@{PayPalEnvironmentProduction : @"AURnLmTIrSf7B8cCdOnj7epoFK2gM2zosJgTeILZQz4_HXy-F8e3Zb-Ysws9Rl5ysL82jUxzXD24iCFr",
                                                         PayPalEnvironmentSandbox : @"AZE755WCwmQata01pA9JCtpBgjNsqvUg8UOQ3LEghuJVFFGGP3auKYYPYkWKXBOSu5_ZbKzyYII9wGYV"}];
  return YES;
}

@end
