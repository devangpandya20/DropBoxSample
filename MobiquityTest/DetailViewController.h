//
//  DetailViewController.h
//  MobiquityTest
//
//  Created by Devang Pandya on 21/03/15.
//  Copyright (c) 2015 Devang Pandya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
@interface DetailViewController : UIViewController<DBRestClientDelegate>

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) DBMetadata *currentMetadata;

@property (nonatomic, strong) IBOutlet UIImageView *photoImgview;

@end

