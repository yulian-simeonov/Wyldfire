//
//  MessagesViewController.m
//  Wyldfire
//
//  Created by Vlad Seryakov on 11/19/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "MessageCountdownView.h"
#import "UIActionSheet+util.h"
#import "InspectViewController.h"
#import "UIPlaceHolderTextView.h"

@interface MessagesViewController () <UIActionSheetDelegate,UIScrollViewDelegate, UITextViewDelegate>
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *entryHeightConstraint;
@property (nonatomic, weak) IBOutlet UIPlaceHolderTextView *textView;
@property (nonatomic, weak) IBOutlet UIView *keyboardView;
@property (nonatomic) int countDownNumber;
@property (strong, nonatomic) IBOutlet UITableView *table;

@property (nonatomic, strong) NSMutableDictionary* cells;
@property (nonatomic, strong) UILabel* remainingLabel;

//Avatar Icon
@property (strong, nonatomic) UIImageView *circle;
@property (strong, nonatomic) UIImageView *icon;

@property (nonatomic) BOOL sharedContact;
@property (nonatomic) BOOL shownMessageLimit;

//Image sending
@property (nonatomic, strong) UIImageView* selectedImageView;

//After sharing
@property (nonatomic, strong) UILabel* remainingTitle;

//Image Cache for performance
@property (atomic, strong) NSMutableDictionary* imageCache;
@end

@implementation MessagesViewController {
    CGPoint _top;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![GVUserDefaults standardUserDefaults].firstChat) {
        [GVUserDefaults standardUserDefaults].firstChat = TRUE;
        [WFCore showAlert:@"Chat Limits" text:@"If they choose to chat, you have 20 messages with each match to charm them. Share your contact to unlock unlimited messaging...if they don’t burn you, that is." delegate:nil cancelButtonText:@"OK" otherButtonTitles:nil tag:CHAT_ENTER_ALERT];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _imageCache = [NSMutableDictionary new];
    Account* account = self.account = self.params[@"account"];
    self.sharedContact = [self haveShared];
    
    _cells = [NSMutableDictionary new];
    
    int countdownNumber = 20 - account.messageCount;
    self.countDownNumber = countdownNumber;
    NSString* title = [NSString stringWithFormat:@"%i Messages Remaining", countdownNumber];
    self.toolbarNextIcon = @"";
    self.toolbarColor = GRAY_8;
    [self addToolbar:account.alias];
    self.title = account.alias;
    [self.toolbar addSubview:self.toolbarNext];
    [self.toolbarBack removeTarget:self action:@selector(onBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolbarBack addTarget:self action:@selector(pressedBack) forControlEvents:UIControlEventTouchUpInside];
    [self setupAvatar];
    
    self.textView.delegate = self;
    self.textView.layer.cornerRadius = 5.f;
    self.textView.layer.borderWidth = 1.f;
    self.textView.layer.borderColor = [UIColor colorWithRed:200/255.f green:200/255.f blue:205/255.f alpha:1.f].CGColor;
    self.textView.contentInset = UIEdgeInsetsMake(-4, 0, 0, 0);
    
    CGRect frame = self.toolbarTitle.frame;
    self.toolbarTitle.frame = CGRectMake(frame.origin.x,
                                         frame.origin.y - 5,
                                         frame.size.width,
                                         frame.size.height);
    
    CGRect labelRect = CGRectMake(frame.origin.x,
                                  frame.origin.y + 25,
                                  frame.size.width,
                                  12);
    
    if (!self.sharedContact) {
        UILabel* label = [UILabel labelInRect:labelRect withText:title color:GRAY_1 fontSize:10];
        self.remainingTitle = label;
        [self.toolbarTitle.superview addSubview:label];
        self.remainingLabel = label;
    }
    self.toolbar.clipsToBounds = NO;
    
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.backgroundColor = [UIColor whiteColor];
    self.table.layer.cornerRadius = 0;
    self.table.layer.shadowOpacity = 0;
    self.table.showsVerticalScrollIndicator = NO;
    self.table.showsHorizontalScrollIndicator = NO;
    //self.table.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
//    tapGesture.cancelsTouchesInView = NO;
//    [self.table addGestureRecognizer:tapGesture];
    
//    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
//    swipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
//    [self.keyboardView addGestureRecognizer:swipeGesture];
    
    [self loadMessages];

    [self subscribeToNotifications];

    int numRows = (int)[self.table numberOfRowsInSection:0];
    if (numRows > 0) {
        [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numRows-1 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
    }
}

-(void)textViewDidChange:(UITextView *)textView
{
    CGFloat updateHeight = textView.contentSize.height - 7;
    
    if (self.selectedImageView && updateHeight < self.selectedImageView.bottom) updateHeight = self.selectedImageView.bottom;
    
    if (updateHeight > 150) updateHeight = 150;
    
    self.entryHeightConstraint.constant = updateHeight;

    [self.view layoutSubviews];
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    //Deleting an empty field
    if (textView.text.length == 0 && text.length == 0) {
        [self resetTextView];
    }
    
    return YES;
}

- (void)pressedBack
{
    if (self.itemsAll.count == 0 && self.params[@"fromMatches"]) {
        NSString* text = [NSString stringWithFormat:@"Send %@ a message within 72 hours or this chat will be removed.", self.account.alias];
        [WFCore showAlert:@"Keep the conversation going" text:text delegate:self cancelButtonText:@"OK" otherButtonTitles:nil tag:CHAT_NO_ACTION_ALERT];
    } else {
        [self onBack:nil];
    }
}

- (void)setupAvatar
{
    CGFloat totalWidth = 30;
//    self.circle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_eclipse2"]];
//    self.circle.contentMode = UIViewContentModeScaleAspectFill;
//    self.circle.frame = CGRectMake(self.toolbarNext.frame.origin.x,
//                                   30,
//                                   totalWidth+2,
//                                   totalWidth+2);
//    [self.view addSubview:self.circle];
    //self.circle.transform = CGAffineTransformMakeRotation(M_PI);
    
    float circleWidth = totalWidth;//CGRectGetWidth(self.circle.frame);
    float circleHeight = totalWidth;//CGRectGetHeight(self.circle.frame);
    
    UIImageView* icon = [[UIImageView alloc] initWithFrame:CGRectMake(570 / 2 - 2,
                                                                      25,
                                                                      circleWidth,
                                                                      circleHeight)];
    //icon.center = self.circle.center;
    icon.contentMode = UIViewContentModeScaleAspectFill;
    icon.layer.cornerRadius = CGRectGetWidth(icon.frame) / 2;
    icon.layer.masksToBounds = YES;
    
    [self.view addSubview:icon];
    self.icon = icon;
    
    if (self.account.avatarPhoto != nil) {
        self.icon.image = self.account.avatarPhoto;
    } else {
        [[APIClient sharedClient] getAccountImageOfType:1 account:self.account.accountID
        success:^(UIImage *image, NSString *url) {
            [self.account setImage:image forType:1];
            [DBAccount createOrUpdateDBAccountWithAccountID:self.account.accountID account:self.account];
            self.icon.image = self.account.avatarPhoto;
        } failure:^(NSInteger code) {
            
        }];
    }
}

- (void)loadMessages
{
    NSArray* messages = [Message messagesForAccountID:self.account.accountID];
    
    if (!self.sharedContact) {
        if (messages.count >= 20) {
            for (int i = 19; i < messages.count; i++)
            {
                Message* message = (Message*)messages[i];
                message.unread = [NSNumber numberWithBool:NO];
                [message save];
            }
            messages = [messages subarrayWithRange:NSMakeRange(0, 20)];
            
            if (!self.shownMessageLimit) {
                self.shownMessageLimit = YES;
                [WFCore showAlert:@"Message Limit Reached" text:[NSString stringWithFormat:@"You have run out of messages. Would you like to share your contact info with %@ to remove the limit?", self.account.alias]
                         delegate:self cancelButtonText:@"No" otherButtonTitles:@[@"Share Contact"] tag:CHAT_MALE_SHARE_ALERT];
            }
        }
    }
    
    self.itemsAll = [messages mutableCopy];
    
    //Precache images from Datas
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0), ^(void) {
        for (Message* item in self.itemsAll) {
            if (item.image) {
                id key = item.created;
                UIImage * img = self.imageCache[key];
                if (!img) {
                    img = [item uiImage];
                    self.imageCache[key] = img;
                }
            }
        }
    });
    
    [self reloadTable];
}

- (IBAction)pickPhoto:(id)sender
{
    if (self.selectedImageView == nil) {
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Pick a Picture" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"From Albums",@"From Photo Library",@"From Camera",nil];
        action.tag = ACTIONSHEET_PICK_PHOTO;
        action.actionSheetStyle = UIActionSheetStyleBlackOpaque;
        [action showInView:self.view];
    }
}

- (void)onNext:(id)sender
{
    UIActionSheet *action;
    DBAccount* account = [DBAccount retrieveDBAccountForAccountID:self.account.accountID];
    
    if ([account.sentShareTo boolValue]) {
        action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Profile",@"Burn",@"Report",nil];
    } else {
        action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Profile",@"Share Contact",@"Burn",@"Report",nil];
    }
    action.tag = ACTIONSHEET_DECISIONS;
    action.tintColor = WYLD_RED;
    action.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [action showInView:self.view];
    [action styleWithTintColor:WYLD_RED];
}

- (IBAction)send
{
    // for accepting auto correction
    static UITextField *dummyFld = nil;
    if (dummyFld == nil) {
        dummyFld = [[UITextField alloc] init];
    }
    [self.view addSubview:dummyFld];
    [dummyFld becomeFirstResponder];
    [self.textView becomeFirstResponder];
    [dummyFld resignFirstResponder];
    
    if (!self.sharedContact) {
        if ([self.table numberOfRowsInSection:0] > 19) return;
    }
    
    // Retrieve items to send
    NSString* text;
    if (self.textView.text && self.textView.text.length > 0) {
        text = self.textView.text;
        // [self.textView resignFirstResponder];
    }
    UIImage* image = self.selectedImageView.image;
    
    // Clear items from entry field
    [self resetTextView];
    
    if ((text == nil) && (image == nil)) {
        return; // Nothing to send
    }
    
    //Create local message
    Message* currentMessage = [Message createMessageWithSenderAccountID:self.account.accountID
                                                                  mtime:self.now
                                                                   text:text
                                                                  image:image
                                                                   sent:YES
                                                                 notify:YES];
    
    //Send message to server, TODO: handle errors
    [[APIClient sharedClient] putMessageImage:image text:text toID:currentMessage.senderAccountID success:nil failure:nil];
    
    [self reloadTable];
    int numRows = (int)[self.table numberOfRowsInSection:0];
    if (numRows > 0) {
        [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numRows-1 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
    }

}

- (long long)now
{
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

- (void)resetTextView
{
    self.textView.placeholder = @"Message";
    [self.selectedImageView removeFromSuperview];
    self.selectedImageView = nil;
    self.textView.textContainer.exclusionPaths = @[];
    self.textView.text = nil;
    
    self.entryHeightConstraint.constant = 30;
}

- (void)onImagePicker:(UIImage *)image
{
    if (!self.sharedContact) {
        if ([self.table numberOfRowsInSection:0] > 19) return;
    }
    
    UIImageView* imgView = [[UIImageView alloc] initWithImage:image];
    
    CGFloat maxDimension = MAX(imgView.size.width, imgView.size.height);
    
    CGFloat desiredMax = 100;
    imgView.frame = CGRectMake(5,
                               5,
                               imgView.size.width / maxDimension * desiredMax,
                               imgView.size.height / maxDimension * desiredMax);
    [self.textView addSubview:imgView];
    
    self.selectedImageView = imgView;
    self.textView.placeholder = nil;
    [self textViewDidChange:self.textView];
    
    UIBezierPath *exclusionPath = [UIBezierPath    bezierPathWithRect:CGRectMake(0,
                                                                                 0,
                                                                                imgView.right,
                                                                                imgView.bottom)];
    
    self.textView.textContainer.exclusionPaths = @[exclusionPath];
}

- (void) reloadTable
{
    CGPoint oldOffset = self.table.contentOffset;
    [super reloadTable];
    
    self.remainingLabel.text = [NSString stringWithFormat:@"%i Messages Remaining", 20 - (int)[self.table numberOfRowsInSection:0]];
    
    if (self.items.count > 0) {
        int numRows = (int)[self.table numberOfRowsInSection:0];
        if (numRows > 0) {
            NSIndexPath *lastPath = [NSIndexPath indexPathForRow:numRows- 1 inSection:0];
            NSArray *visibleCells = [self.table indexPathsForVisibleRows];
            for (NSIndexPath *visibleItem in visibleCells) {
                if ([visibleItem compare:lastPath] == NSOrderedSame) {
                    [self.table scrollToRowAtIndexPath:lastPath
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
                    break;
                }
            }
        }
    }
    
    if (!self.sharedContact) {
        if (self.items.count >= 20) {
            self.keyboardView.alpha = 0.0;
        } else {
            self.keyboardView.alpha = 1.0;
        }
    } else {
        self.keyboardView.alpha = 1.0;
    }
    [self.table setContentOffset:oldOffset animated:NO];
}

- (void)keyboardDidShow:(NSNotification*)notification
{
    CGSize keyboardSize = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.bottomConstraint.constant = keyboardSize.height;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
    
    int numRows = (int)[self.table numberOfRowsInSection:0];
    if (numRows > 0) {
        [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numRows-1 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
    }
}

- (void)keyboardDidHide:(NSNotification*)notification
{
    self.bottomConstraint.constant = 0.0f;
    [self.view layoutIfNeeded];
}

- (void)hideKeyboard:(UITapGestureRecognizer*)recognizer
{
    [self.textView resignFirstResponder];
}

- (MessageCell*)getCell:(NSInteger)index cache:(BOOL)cache
{
    Message *item = self.items[index];
    
    NSString* key = [NSString stringWithFormat:@"%i", (int)index];
    
    MessageCell *cell = self.cells[key];
    if (!cell) {
        cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.tableCell];
        cell.frame = CGRectMake(0, 0, MIN(self.table.frame.size.width, cell.frame.size.width), self.table.rowHeight);
        [cell configure:item forIndex:index by:self];
        self.cells[key] = cell;
    }
    
    //Not sure what this is for but I'll leave it here for now -- Danny
    // Remove from the item list so we dont fill memory with cell we dont need
    if (!cache) {
        [self.cells removeObjectForKey:key];
    }
    return cell;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (actionSheet.tag == ACTIONSHEET_PICK_PHOTO) {
        if ([WFCore matchString:@"Albums" string:action]) {
            [self showImagePickerFromAlbums:self];
        }
        if ([WFCore matchString:@"Library" string:action]) {
            [self showImagePickerFromLibrary:self];
        }
        if ([WFCore matchString:@"Camera" string:action]) {
            [self showImagePickerFromCamera:self];
        }
    } else if (actionSheet.tag == ACTIONSHEET_DECISIONS) {
        
        if ([action isEqualToString:@"Share Contact"]) {
            NSString* text = [NSString stringWithFormat:@"Are you sure you want to share your contact with %@? This will add your info to their %@.",
                              self.account.alias,  @"Notebook"];
            
            [WFCore showAlert:@"Share Contact" text:text delegate:self cancelButtonText:@"Cancel" otherButtonTitles:@[@"OK"] tag:CHAT_MALE_SHARE_ALERT];

           
        } else if ([action isEqualToString:@"View Profile"]) {
            [WFCore showViewController:self
                                  name:@"Match"
                                  mode:@"push"
                                params:@{@"account" : self.account,
                                         @"profileview" : @(YES),
                                         @"isFromChat" : @(YES)}];  //Added by Yurii on 06/16/14
        } else if ([action isEqualToString:@"Burn"]) {
            [WFCore showAlert:@"Burn" text:[NSString stringWithFormat:@"Are you sure you want to burn %@? This will remove them from your network and cannot be undone.", self.account.alias] delegate:self cancelButtonText:@"Cancel" otherButtonTitles:@[@"OK"] tag:CHAT_BURN_ALERT];
        } else if ([action isEqualToString:@"Report"]) {
            [WFCore showAlert:@"Report User" text:@"Wyldfire takes reporting very seriously. This account will be immediately suspended until we can review. If you make a false report, we may disable your account." delegate:self cancelButtonText:@"Cancel" otherButtonTitles:@[@"Report"] tag:CHAT_REPORT_ALERT];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    if (alertView.tag == CHAT_BURN_ALERT) {
        if (buttonIndex == 1) {
            [self burnUser];
        }
    } else if (alertView.tag == CHAT_REPORT_ALERT) {
        if (buttonIndex == 1) {
            [self reportUser];
        }
    } else if (alertView.tag == CHAT_MALE_SHARE_ALERT) {
        if (buttonIndex == 1) {
            [self shareContact];
        }
    } else if (alertView.tag == CHAT_NO_ACTION_ALERT) {
        [self onBack:nil];
    }
}

- (void)shareContact
{
    [[APIClient sharedClient] shareContactInfoWithAccount:self.account
                                                  success:nil failure:nil];
    DBAccount* account = [DBAccount retrieveDBAccountForAccountID:self.account.accountID];
    account.sentShareTo = [NSNumber numberWithBool:YES];
    [account save];
    
    [WFCore saveMoment:KIIP_REWARD_MOMENT_SHARED_CONTACT
              onlyOnce:YES
               topText:@"Givin' Digits"
            bottomText:@"You just shared your contact and made someone's day!"
                inNavC:self.navigationController];
    
    self.sharedContact = YES;
    self.remainingLabel.alpha = 0.0;
    
    [self reloadTable];
}

- (BOOL)haveShared
{
    DBAccount* account = [DBAccount retrieveDBAccountForAccountID:self.account.accountID];
    return [account.sentShareTo boolValue] || [account.inBlackbook boolValue];
}

- (void)reportUser
{
    [[APIClient sharedClient] reportUser:self.account success:nil failure:nil];
    [self makeUserDeadToMe];
}

- (void)burnUser
{
    [[APIClient sharedClient] burnUser:self.account success:nil failure:nil];
    [self makeUserDeadToMe];
}

- (void)makeUserDeadToMe
{
    DBAccount* dbAccount = [DBAccount retrieveDBAccountForAccountID:self.account.accountID];
    dbAccount.showInMatches = [NSNumber numberWithBool:NO];
    dbAccount.inChat = [NSNumber numberWithBool:NO];
    dbAccount.burned = [NSNumber numberWithBool:YES];
    [dbAccount save];
    
    if (self.params[@"singleMatch"]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
//    BounceAnimation *bounce = [[BounceAnimation alloc] initWithKeyPath:@"position.y" start:nil stop:nil];
//    bounce.fromValue = [NSNumber numberWithFloat:cell.center.y - 25];
//    bounce.toValue = [NSNumber numberWithFloat:cell.center.y];
//    bounce.shaking = YES;
//    bounce.duration = 1.25;
//    bounce.bounces = 5;
//    [bounce configure:cell];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageCell* cell = (MessageCell*)[self getCell:indexPath.row cache:NO];
    if (self.sharedContact) cell.countdown.alpha = 0.0;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageCell *cell = [self getCell:indexPath.row cache:YES];
    return cell.frame.size.height;
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _top = scrollView.contentOffset;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < _top.y) [self hideKeyboard:nil];
}

#pragma mark - UIGestureRecognizer delegate methods

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
    // Let keyboard swipe recognizer hide the keyboard
    if (recognizer == self.panGesture && [touch view] == self.keyboardView) return NO;
    return YES;
}

#pragma mark Notifications

- (void)subscribeToNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessages) name:NOTIFICATION_UPDATED_MESSAGES object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessages) name:NOTIFICATION_NEW_CONTACT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@interface MessageCell ()
@property (nonatomic, weak) UIViewController* vc;
@property (nonatomic) BOOL sent;
@end

@implementation MessageCell

- (void)configure:(id)untypedItem forIndex:(NSInteger)index by:(MessagesViewController*)vc
{
    self.vc = vc;
    Message* item = (Message*)untypedItem;
    item.unread = [NSNumber numberWithBool:NO];
    [CoreData save];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    BOOL sent = [item.sent boolValue];
    self.sent = sent;
    int y = 0, padding = 20;
    int contentInset = vc.sharedContact ? 8 : 32;
    
    //MTIME
    UILabel *mtime = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 20)];
    mtime.font = [UIFont fontWithName:MAIN_FONT size:11];
    mtime.textColor = [UIColor grayColor];
    mtime.textAlignment = NSTextAlignmentCenter;
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:[item.mtime longLongValue] / 1000];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    
    //http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
    [fmt setDateFormat:@"EEE, MMM d, h:mm a"];
    
    mtime.text = [fmt stringFromDate:now];
    [self.contentView addSubview:mtime];
    y = 15;
    mtime.layer.shouldRasterize = YES;
    
    //IMAGE
    UIImageView *imageView;
    if (item.image) {
        id key = item.created;
        UIImage * img = vc.imageCache[key];
        if (!img) img = [item uiImage];
        vc.imageCache[key] = img;
        
        //Setup imageView
        imageView = [[UIImageView alloc] initWithImage:img];
        imageView.tag = 1337;
        imageView.layer.masksToBounds = YES;
        imageView.layer.cornerRadius = 8;
        imageView.layer.borderWidth = 0;
        imageView.layer.shouldRasterize = YES;
        imageView.layer.borderColor = [UIColor clearColor].CGColor;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        //Sizing
        CGSize size = imageView.frame.size;
        if (size.width > 2 * self.frame.size.width / 3) {
            size.height /= size.width / (self.frame.size.width/2);
            size.width = 2 * self.frame.size.width / 3;
        }
        imageView.frame = CGRectMake(sent ? self.frame.size.width - size.width - padding / 2 - contentInset
                                      : padding / 2 + contentInset,
                                 padding/2,
                                 size.width,
                                 size.height);
        imageView.center = CGPointMake(imageView.center.x, y + imageView.frame.size.height/2 + padding/2);
        [self.contentView addSubview:imageView];
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, y + imageView.frame.size.height + padding);
        y += self.frame.size.height;
        if (item.text) y -= padding;
        
        UIButton* tap = [[UIButton alloc] initWithFrame:imageView.bounds];
        imageView.userInteractionEnabled = YES;
        [imageView addSubview:tap];
        imageView.centerX += (sent ? 4 : -4);
        [tap addTarget:self action:@selector(imageTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    UITextView *text;
    if (item.text) {
        text = [[UITextView alloc] init];
        //text.lineBreakMode = NSLineBreakByWordWrapping;
        text.text = item.text;
       // text.preferredMaxLayoutWidth = self.frame.size.width*0.75;
        //text.numberOfLines = 0;
        text.font = FONT_MAIN(17);
        text.backgroundColor = [UIColor clearColor];
        text.selectable = YES;
        text.editable = NO;
        text.dataDetectorTypes = UIDataDetectorTypeAll;
        text.scrollEnabled = NO;
        //text.layer.shouldRasterize = YES;
        
        text.textColor = sent ? [UIColor whiteColor] : [UIColor blackColor];
        UIImage *image = sent ? [[UIImage imageNamed:@"msg0"] resizableImageWithCapInsets:UIEdgeInsetsMake(12, 12, 13, 20)] :
        [[UIImage imageNamed:@"msg1"] resizableImageWithCapInsets:UIEdgeInsetsMake(12, 20, 13, 12)];
        UIImageView *bg = [[UIImageView alloc] initWithImage:image];
        text.frame = CGRectMake(0, 0, self.frame.size.width * 0.65, 10000);
                                //Frame calculations
        [text sizeToFit];
        CGRect rect = CGRectMake(0, 0, text.width, text.height);
        
        text.frame = CGRectMake(sent ? self.frame.size.width - rect.size.width - 15 - contentInset
                                     : 15 + contentInset,
                                padding/2,
                                rect.size.width,
                                rect.size.height);
        text.center = CGPointMake(text.center.x, y + text.frame.size.height/2 + padding/2);
        bg.frame = CGRectMake(0, 0, text.frame.size.width + padding, text.frame.size.height - padding / 4.f);
        bg.center = CGPointMake(text.center.x + (sent ? 4 : -4), text.center.y + 1);
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, y + bg.frame.size.height + padding);
        
        
        self.contentView.clipsToBounds = YES;
        [self.contentView addSubview:bg];
        [self.contentView addSubview:text];
    }
    
    float maxContentY = MAX(CGRectGetMaxY(imageView.frame),
                            CGRectGetMaxY(text.frame));
    CGRect countDownRect = CGRectMake((!sent ? 5
                                             : CGRectGetWidth(self.frame) - contentInset),
                                      maxContentY - 26 + 5,
                                      26,
                                      26);
    
    MessageCountdownView* countdown = [[MessageCountdownView alloc] initWithFrame:countDownRect
                                                                             sent:sent
                                                                           number:20 - (int)index];
    [self.contentView addSubview:countdown];
    self.countdown = countdown;
}

- (void)imageTapped:(UIButton*)button
{
    UIImageView* imgView = (UIImageView*)button.superview;
    
    InspectViewController* vc = [[InspectViewController alloc] initWithImage:imgView.image];
    
    vc.title = [NSString stringWithFormat:@"%@'s Photo", self.vc.title];
    if (self.sent) {
        vc.title = [NSString stringWithFormat:@"Sent Photo"];
    }
    
    [self.vc.navigationController pushViewController:vc animated:YES];
}

@end
