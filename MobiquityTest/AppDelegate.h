//
//  AppDelegate.h
//  MobiquityTest
//
//  Created by Devang Pandya on 21/03/15.
//  Copyright (c) 2015 Devang Pandya. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;

@interface AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *currentCity;

@end

