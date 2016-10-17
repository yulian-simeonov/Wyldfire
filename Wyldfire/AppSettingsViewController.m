//
//  AppSettingsViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/12/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "WFMailComposeViewController.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "UIDevice-Hardware.h"

@interface AppSettingsViewController ()<MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@end

@implementation AppSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.items = [@[ @{ @"name": @"",
                        @"data": @[ @{ @"name": @"Linked Accounts",
                                       @"type": @"view",
                                       @"view": @"LinkedAccounts" },
                                    @{ @"name": @"Notifications",
                                       @"type": @"switch",
                                       @"config": @"settingEnabledNotifications" },
                                    @{ @"name": @"Vibration on Chat",
                                       @"type": @"switch",
                                       @"config": @"settingVibrateForChat" },
                                    ]
                        },
                     @{ @"name": @"Matching Preferences",
                        @"data": @[ @{ @"name": @"Interested in Women",
                                       @"type": @"switch",
                                       @"config": @"settingInterestedInWomen" },
                                    @{ @"name": @"Interested in Men",
                                       @"type": @"switch",
                                       @"config": @"settingInterestedInMen" }/*,
                                    @{ @"name": @"Matchable",
                                       @"type": @"switch",
                                       @"config": @"settingMatchable" }*/
                                    ]
                        },
                     @{ @"name": @"Search Preferences",
                        @"data": @[ @{ @"name": @"Search Radius",
                                       @"type": @"view",
                                       @"view": @"SearchRadius" },
                                    @{ @"name": @"Age Range",
                                       @"type": @"view",
                                       @"view": @"AgeRange" },
                                    @{ @"name": @"Trending Radius",
                                       @"type": @"view",
                                       @"view": @"TrendingRadius" }
                                    ]
                        },
                     @{ @"name": @"General",
                        @"data": @[ @{ @"name": @"Contact Us",
                                       @"type": @"view",
                                       @"view": @"ContactUs" },
                                    @{ @"name": @"Rate App",
                                       @"type": @"view",
                                       @"view": @"Rate" }
                                    ]
                        },
                     @{ @"name": @"Legal",
                        @"data": @[ @{ @"name": @"Privacy Policy",
                                       @"type": @"view",
                                       @"view": @"PrivacyPolicy" },
                                    @{ @"name": @"Terms of Service",
                                       @"type": @"view",
                                       @"view": @"TermsOfService" }
                                    ]
                        },
                     @{ @"name": @"Account",
                        @"data": @[ @{ @"name": @"Log Out",
                                       @"type": @"view",
                                       @"view": @"Logout" },
                                    @{ @"name": @"Delete Account",
                                       @"type": @"view",
                                       @"view": @"Delete" }
                                    ]
                        }] mutableCopy];
    self.tableSections = self.items.count;
    self.tableUnselected = YES;
    [self addTable];
    self.table.backgroundColor = GRAY_8;
    
    self.panRect = CGRectMake(0, 0, 30, self.view.frame.size.height);
    
    [self addToolbar:@"Settings"];

    [self subscribeToNotifications];
}

- (void)onView:(NSDictionary*)item
{
   // NSDictionary *item = objc_getAssociatedObject(sender.view, @"item");
    if ([item[@"type"] isEqualToString:@"view"]) {
        
        if ([item[@"view"] isEqualToString:@"PrivacyPolicy"]) {
            WebViewViewController* vc = [WebViewViewController initWithDelegate:nil completionHandler:nil];
            [vc start:[NSURLRequest requestWithURL:[NSURL URLWithString:PRIVACY_POLICY_URL]] completionHandler:nil];
            [self presentViewController:vc animated:YES completion:nil];
        } else if ([item[@"view"] isEqualToString:@"TermsOfService"]) {
            WebViewViewController* vc = [WebViewViewController initWithDelegate:nil completionHandler:nil];
            [vc start:[NSURLRequest requestWithURL:[NSURL URLWithString:TERMS_OF_SERVICE_URL]] completionHandler:nil];
            [self presentViewController:vc animated:YES completion:nil];
        } else if ([item[@"view"] isEqualToString:@"ContactUs"]) {
            [self showContactUs];
        } else if ([item[@"view"] isEqualToString:@"Rate"]) {
            [self rateApp];
        } else if ([item[@"view"] isEqualToString:@"Logout"]) {
            [WFCore showAlert:@"Log Out" text:@"Are you sure you want to log out?" delegate:self cancelButtonText:@"Cancel" otherButtonTitles:@[@"OK"] tag:LOGOUT_ALERT];
        } else if ([item[@"view"] isEqualToString:@"Delete"]) {
            [WFCore showAlert:@"Delete Account" text:@"Are you sure you want to delete your account? All of your stats and matches will be lost." delegate:self cancelButtonText:@"Cancel" otherButtonTitles:@[@"OK"] tag:DELETE_ACCOUNT_ALERT];
        } else {
            [WFCore showViewController:self name:item[@"view"] mode:@"push" params:nil];
        }
    }
    
    [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    if (alertView.tag == DELETE_ACCOUNT_ALERT) {
        if (buttonIndex == 1) {
            [self deleteAccount];
        }
    } else if (alertView.tag == LOGOUT_ALERT) {
        if (buttonIndex == 1) {
            [self logout];
        }
    }
}

- (void)deleteAccount
{
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    [[APIClient sharedClient] deleteAccount:^{
        [hud removeFromSuperview];
        [WFCore showViewController:self name:@"AppTourViewController" mode:nil params:nil];
    } failure:^{
        [hud removeFromSuperview];
        [WFCore showAlert:@"Cannot Delete" msg:@"Please ensure you are connected to the Internet." delegate:nil confirmHandler:nil];
    }];
}

- (void)logout
{
    [GVUserDefaults standardUserDefaults].email = nil;
    [[APIClient sharedClient].session closeAndClearTokenInformation];
    [[APIClient sharedClient] checkFacebookStatus:nil];
    
    [WFCore showViewController:self name:@"AppTourViewController" mode:nil params:nil];
}

- (void)showContactUs
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Contact Us" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Get Help", @"Give Feedback", @"Make Suggestion"/*, @"Submit Event"*/, nil];
    action.tag = ACTIONSHEET_CONTACTUS;
    action.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [action showInView:self.view];
    [action styleWithTintColor:WYLD_RED];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ACTIONSHEET_CONTACTUS) {
        NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([action isEqualToString:@"Get Help"]) {
            [self showHelp];
        } else if ([action isEqualToString:@"Give Feedback"]){
            [self showEmail];
        } else if ([action isEqualToString:@"Make Suggestion"]){
            [self showSuggestion];
        /*} else if ([action isEqualToString:@"Submit Event"]){
            [self showEvent];*/
        }
    } else {
        NSLog(@"Code up the other actions");
    }
}

- (void)showEvent
{
    [self sendEmailWithSubject:@"Event Submission" recipient:@"events@wyldfireapp.com" body:@"Thanks for submitting an event. Please provide a link and a brief description of your event. We will consider including it in our weekly member updates."];
}

- (void)showEmail
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    
    NSString* body = [NSString stringWithFormat:@"\n\n\n\n---\nWyldfire %@\n%@ (iOS %@)\nCellular Data via %@\n%@",
                      build,
                      [[UIDevice currentDevice] platform],
                      [[UIDevice currentDevice] systemVersion],
                      [telephonyInfo.currentRadioAccessTechnology stringByReplacingOccurrencesOfString:@"CTRadioAccessTechnology" withString:@""],
                      [NSString stringWithFormat:@"WiFi %@", [APIClient sharedClient].connectedViaWifi ? @"Available" : @"Unavailable"]];
    
    [self sendEmailWithSubject:@"Wyldfire Feedback" recipient:@"feedback@wyldfireapp.com" body:body];
}

- (void)showHelp
{
    //Added by Yurii on 06/16/14
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *build = infoDictionary[(NSString*)kCFBundleVersionKey];
    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
    
    NSString* body = [NSString stringWithFormat:@"\n\n\n\n---\nWyldfire %@\n%@ (iOS %@)\nCellular Data via %@\n%@",
                      build,
                      [[UIDevice currentDevice] platform],
                      [[UIDevice currentDevice] systemVersion],
                      [telephonyInfo.currentRadioAccessTechnology stringByReplacingOccurrencesOfString:@"CTRadioAccessTechnology" withString:@""],
                      [NSString stringWithFormat:@"WiFi %@", [APIClient sharedClient].connectedViaWifi ? @"Available" : @"Unavailable"]];
    [self sendEmailWithSubject:@"Get Help" recipient:@"support@wyldfireapp.com" body:body];
}

- (void)showSuggestion
{
    [self sendEmailWithSubject:@"Make Suggestion" recipient:@"ideas@wyldfireapp.com" body:@""];
}

- (void)sendEmailWithSubject:(NSString*)subject recipient:(NSString*)recipient body:(NSString*)body
{
    WFMailComposeViewController *mailViewController = [[WFMailComposeViewController alloc] init];
    mailViewController.navigationBar.tintColor = [UIColor blackColor];
    mailViewController.navigationBar.barTintColor = [UIColor blackColor];//WYLD_RED;
    //mailViewController.navigationBar.translucent = NO;
    mailViewController.mailComposeDelegate = self;
    mailViewController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    [mailViewController setSubject:subject];
    [mailViewController setMessageBody:body isHTML:NO];
    [mailViewController setToRecipients:@[recipient]];
    
    [[mailViewController navigationBar] setTintColor:[UIColor blackColor]];
    [self.navigationController presentViewController:mailViewController animated:YES completion:^{
        
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)rateApp
{
    NSString* formatString = @"itms-apps://itunes.apple.com/app/id%@";
    NSString* url = [NSString stringWithFormat:formatString, @"876751876"];
    
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
}


- (IBAction)onButton:(UIButton*)sender
{
}

- (IBAction)onSwitch:(UISwitch*)sender
{
    NSDictionary *item = objc_getAssociatedObject(sender, @"item");
    
    NSString* settingName = item[@"config"];
    BOOL settingValue = sender.isOn;
    
    if ([settingName isEqualToString:@"settingMatchable"] && settingValue == FALSE) {
        [WFCore showAlert:@"Matchable" text:@"Turning off matchable means you can browse other users but cannot be matched with them." delegate:self cancelButtonText:@"OK" otherButtonTitles:nil tag:MATCHABLE_ALERT];
    }
    
    [[GVUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:settingValue] forKey:settingName];
    
    NSDictionary* localSettingNameToRemote = @{@"settingEnabledNotifications"  : @"notifications0",
                                               @"settingVibrateForChat"        : @"vibrations0",
                                               @"settingMatchable"             : @"matchable0",
                                               @"settingInterestedInMen"       : @"men0",
                                               @"settingInterestedInWomen"     : @"women0"};

    [[APIClient sharedClient] updateAccountField:localSettingNameToRemote[settingName]
                                           value:[NSNumber numberWithBool:settingValue]
                                          notify:YES
                                         success:nil
                                         failure:nil];
    
    // check whether both of men and women are turned off
    NSString *otherName = @"";
    NSIndexPath *otherPath = nil;
    
    if ([settingName isEqualToString:@"settingInterestedInWomen"]) {
        otherName = @"settingInterestedInMen";
        otherPath = [NSIndexPath indexPathForRow:1 inSection:1];
    } else if ([settingName isEqualToString:@"settingInterestedInMen"]) {
        otherName = @"settingInterestedInWomen";
        otherPath = [NSIndexPath indexPathForRow:0 inSection:1];
    }
    
    if ([otherName length] > 0 && !settingValue) {
        BOOL otherVal = [(NSNumber*)[[GVUserDefaults standardUserDefaults] valueForKey:otherName] boolValue];
        if (!otherVal) {
            [[GVUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:otherName];
            [[APIClient sharedClient] updateAccountField:localSettingNameToRemote[otherName]
                                                   value:[NSNumber numberWithBool:YES]
                                                  notify:YES
                                                 success:nil
                                                 failure:nil];
            
            // [self.table reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            UITableViewCell *otherCell = [self.table cellForRowAtIndexPath:otherPath];
            UISwitch *otherSwitch = (UISwitch *)otherCell.accessoryView;
            [otherSwitch setOn:YES animated:YES];
        }
    }
}

- (IBAction)onSlider:(UISlider*)sender
{
    NSDictionary *item = objc_getAssociatedObject(sender, @"item");
    self.core.account[[NSString stringWithFormat:@"%@0", item[@"config"]]] = [NSNumber numberWithDouble:sender.value];
}

- (IBAction)onRange:(RangeSlider*)sender
{
    NSDictionary *item = objc_getAssociatedObject(sender, @"item");
    self.core.account[[NSString stringWithFormat:@"%@0", item[@"config"]]] = @[ [NSNumber numberWithDouble:sender.value0], [NSNumber numberWithDouble:sender.value1] ];
    UILabel *label = objc_getAssociatedObject(sender, @"minLabel");
    label.text = [NSString stringWithFormat:@"%0.f", sender.value0];
    label = objc_getAssociatedObject(sender, @"maxLabel");
    label.text = [NSString stringWithFormat:@"%0.f", sender.value1];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *rows = self.items[indexPath.section][@"data"];
    NSDictionary *item = rows[indexPath.row];
    
     if ([item[@"type"] isEqualToString:@"view"]) {
         [self onView:item];
     }
}

- (void)onTableCell:(UITableViewCell*)cell indexPath:(NSIndexPath*)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSArray *rows = self.items[indexPath.section][@"data"];
    NSDictionary *item = rows[indexPath.row];
    
    //Label Styling
    cell.textLabel.font = [UIFont fontWithName:MAIN_FONT size:17];
    cell.textLabel.textColor = [UIColor blackColor];

    
    if ([item[@"type"] isEqualToString:@"view"]) {
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.text = item[@"name"];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        //objc_setAssociatedObject(cell, @"item", item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        //[cell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onView:)]];
    }
    if ([item[@"type"] isEqualToString:@"switch"]) {
        cell.textLabel.text = item[@"name"];
        
        UISwitch *button = [[UISwitch alloc] init];
        button.onTintColor = WYLD_RED;
        objc_setAssociatedObject(button, @"item", item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        button.on = [(NSNumber*)[[GVUserDefaults standardUserDefaults] valueForKey:item[@"config"]] boolValue];
        [button addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = button;
    }
    if ([item[@"type"] isEqualToString:@"slider"]) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, self.table.rowHeight/2)];
        label.text = item[@"name"];
        label.textColor = [UIColor grayColor];
        label.textAlignment = NSTextAlignmentCenter;
        [cell addSubview:label];
        
        UILabel *min = [[UILabel alloc] initWithFrame:CGRectMake(0, self.table.rowHeight/2, 50, self.table.rowHeight)];
        min.text = item[@"min"];
        min.textColor = [UIColor grayColor];
        min.textAlignment = NSTextAlignmentCenter;
        [cell addSubview:min];
        
        UILabel *max = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width - 50, self.table.rowHeight/2, 50, self.table.rowHeight)];
        max.text = item[@"max"];
        max.textColor = [UIColor grayColor];
        max.textAlignment = NSTextAlignmentCenter;
        [cell addSubview:max];
        
        UISlider *button = [[UISlider alloc] initWithFrame:CGRectMake(50, self.table.rowHeight/2, cell.frame.size.width - 100, self.table.rowHeight)];
        objc_setAssociatedObject(button, @"item", item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        button.value = [self.core num:[NSString stringWithFormat:@"%@0", item[@"config"]]];
        button.minimumValue = [item[@"min"] integerValue];
        button.maximumValue = [item[@"max"] integerValue];
        [button addTarget:self action:@selector(onSlider:) forControlEvents:UIControlEventValueChanged];
        [cell addSubview:button];
    }
    if ([item[@"type"] isEqualToString:@"range"]) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, self.table.rowHeight/2)];
        label.text = item[@"name"];
        label.textColor = [UIColor grayColor];
        label.textAlignment = NSTextAlignmentCenter;
        [cell addSubview:label];
        
        UILabel *min = [[UILabel alloc] initWithFrame:CGRectMake(0, self.table.rowHeight/2, 50, self.table.rowHeight)];
        min.text = item[@"min"];
        min.textColor = [UIColor grayColor];
        min.textAlignment = NSTextAlignmentCenter;
        [cell addSubview:min];
        
        UILabel *max = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width - 50, self.table.rowHeight/2, 50, self.table.rowHeight)];
        max.text = item[@"max"];
        max.textColor = [UIColor grayColor];
        max.textAlignment = NSTextAlignmentCenter;
        [cell addSubview:max];
        
        RangeSlider *button = [[RangeSlider alloc] initWithFrame:CGRectMake(50, self.table.rowHeight/2, cell.frame.size.width - 100, self.table.rowHeight)];
        objc_setAssociatedObject(button, @"item", item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        NSArray *val = [self.core list:[NSString stringWithFormat:@"%@0", item[@"config"]]];
        button.minValue = [item[@"min"] intValue];
        button.maxValue = [item[@"max"] intValue];
        button.minRange = 5;
        button.value0 = val.count > 0 ? [val[0] intValue] : button.minValue;
        button.value1 = val.count > 1 ? [val[1] intValue] : button.minValue + button.minRange;
        [button addTarget:self action:@selector(onRange:) forControlEvents:UIControlEventValueChanged];
        objc_setAssociatedObject(button, @"minLabel", min, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(button, @"maxLabel", max, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [cell addSubview:button];
    }
    if ([item[@"type"] isEqualToString:@"button"]) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectInset(cell.frame, 5, 5)];
        objc_setAssociatedObject(button, @"item", item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [button setImage:[UIImage imageNamed:item[@"icon"]] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(onButton:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = button;
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *rows = self.items[section][@"data"];
    return rows.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.items[section][@"name"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0 : 46;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
    UIView* vHeader = [[UIView alloc] init];
    vHeader.backgroundColor = GRAY_8;
    vHeader.frame = CGRectMake(0, 0, 320, height);
    UILabel* label = [[UILabel alloc] init];
    
    label.font = [UIFont fontWithName:MAIN_FONT size:14];
    [label setTextColor:SETTINGS_HEADER_TEXT_COLOR];
    label.frame = CGRectMake(16,  height - 24,
                             320 - 16,
                             18);
    [vHeader addSubview:label];
    
    label.text = [[self tableView:tableView titleForHeaderInSection:section] uppercaseString];
    
    return vHeader;
}

#pragma mark Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resize:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}

- (void)resize:(NSNotification*)notification
{
    CGRect frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
    self.table.frame = frame;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
