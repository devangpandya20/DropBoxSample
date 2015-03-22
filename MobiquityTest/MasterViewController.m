//
//  MasterViewController.m
//  MobiquityTest
//
//  Created by Devang Pandya on 21/03/15.
//  Copyright (c) 2015 Devang Pandya. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import <MBProgressHUD.h>
#import "AppDelegate.h"
@interface MasterViewController ()

@property NSMutableArray *objects;
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) DBMetadata *appRootMetadata;
@property (nonatomic, strong) DBMetadata *selectedMetadata;
@property (nonatomic, strong) DBAccountInfo *userAccountInfo;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    if ([[DBSession sharedSession] isLinked])
    {
        //Initialize Rest client with shared session
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
        
        [self.restClient loadAccountInfo];
        [self.restClient loadMetadata:@"/"];
    }
    else{
        [[DBSession sharedSession] linkFromController:self];
    }
    
    
    self.progressHUD = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    self.progressHUD.labelText = @"Fetching Dropbox content";
    
}
-(void)viewDidAppear:(BOOL)animated{
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.edgesForExtendedLayout = UIRectEdgeNone;
    picker.hidesBottomBarWhenPushed = YES;
    picker.allowsEditing = NO;
    [self presentViewController:picker animated:YES completion:nil];
    
}
#pragma mark - Image picker method

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //    self.photoImgview.image = [info valueForKey:UIImagePickerControllerOriginalImage];
    //    NSLog(@"info:%@",info);
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *filename = @"Image.png";
    if (appDelegate.currentCity) {
        filename = [NSString stringWithFormat:@"%@.png",appDelegate.currentCity];
    }
    NSData *imgData = [[NSData alloc] initWithData:UIImagePNGRepresentation([info valueForKey:UIImagePickerControllerOriginalImage])];
    
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:filename];
    //    NSLog(@"local:%@",localPath);
    [imgData writeToFile:localPath atomically:YES];
    
    // Upload file to Dropbox
    NSString *destDir = @"/";

    self.progressHUD = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
    self.progressHUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
    self.progressHUD.labelText = @"Uploading...";
    [self.progressHUD show:YES];

    [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        DetailViewController *photoDetailVC = (DetailViewController *)[segue destinationViewController];
        photoDetailVC.currentMetadata = self.selectedMetadata;

    }
}

#pragma mark - Table View
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.userAccountInfo) {
        return 40;
    }
    return 0;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%@",self.userAccountInfo.displayName];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    if ([[self.objects objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]]) {
        [cell.textLabel setText:@"Folder is empty!"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell.imageView setHidden:YES];
    }
    else
    {
        DBMetadata *currentData = [self.objects objectAtIndex:indexPath.row];
        [cell.textLabel setText:currentData.filename];
        [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        [cell.imageView setHidden:NO];
        cell.imageView.image = [UIImage imageNamed:currentData.icon];
    }
    
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15]];
    [cell.imageView.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [cell.imageView.layer setBorderWidth:0.5f];
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![[self.objects objectAtIndex:indexPath.row] isKindOfClass:[NSNull class]])
    {
        self.selectedMetadata = [self.objects objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"showDetail" sender:self];
    }
}

#pragma mark - Dropbox Delegate

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    self.appRootMetadata = metadata;
    self.objects = [NSMutableArray arrayWithArray:metadata.contents];
    if (![[metadata contents] count])
    {
        [self.objects addObject:[NSNull null]];
    }
    [self.tableView reloadData];
    [self.progressHUD hide:YES];
}
- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError*)error
{
    NSLog(@"Error loading metadata: %@", error);
    self.objects = [NSMutableArray arrayWithObject:[NSNull null]];
    [self.tableView reloadData];
    [self.progressHUD hide:YES];
    
}

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info
{
    self.userAccountInfo = info;
    NSLog(@"Account Info: %@", info.displayName);
}
- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    NSLog(@"Error loading Account Info: %@", error);
}


- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath
{
    self.progressHUD.progress=progress;
}
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata
{
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    self.progressHUD.labelText = @"Refreshing Content";

    [self.restClient loadMetadata:@"/"];

    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}
- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
    NSLog(@"File upload failed with error: %@", error);
}


@end
