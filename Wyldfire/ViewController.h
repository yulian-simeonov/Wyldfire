//
//  BrowseViewController.h
//  Wyldfire
//
//  Created by Vlad Seryakov on 9/26/13.
//  Copyright (c) 2013 YulianMobile. All rights reserved.
//

#import "InfoPaneView.h"
#import "MessageCountdownView.h"
#import "UIView+util.h"
#import "UIActionSheet+util.h"
#import "MBProgressHUD.h"
#import "WFMailComposeViewController.h"
#import "Account.h"
#import <MessageUI/MessageUI.h>

typedef void (^GenericBlock)();
typedef void (^SuccessBlock)(id obj);
typedef void (^AccountBlock)(Account *account);
typedef void (^FailureBlock)(NSInteger code);
typedef void (^ErrorBlock)(NSError *error);
typedef void (^StringBlock)(NSString *str);
typedef void (^JSONFailureBlock)(NSInteger code, NSError *error, id json);
typedef void (^ImageSuccessBlock)(UIImage *image, NSString *url);
typedef UIImage* (^ImageProcessBlock)(UIImage *image, NSString *url);
typedef void (^AlertBlock)(UIAlertView *view, NSString *button);

@class WFCore;

// Common view controller
@interface ViewController: UIViewController <UIViewControllerTransitioningDelegate,UIGestureRecognizerDelegate,UIAlertViewDelegate,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate, UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) WFCore *core;
// Name of the current controller
@property (strong, nonatomic) NSString *name;
// How it was brought up: push or set
@property (strong, nonatomic) NSString *mode;
// Who called this controller
@property (strong, nonatomic) NSString *caller;
// What animation to use during transitions
@property (nonatomic) float pushDuration;
@property (nonatomic) float modalDuration;
@property (strong, nonatomic) NSString *pushAnimation;
@property (strong, nonatomic) NSString *modalAnimation;
// Parameters pased to the controller: underscored names are special tokens, all other names are account properties
@property (strong, nonatomic) NSMutableDictionary *params;
// Generic list for table views or other collections
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) NSMutableArray *itemsAll;

@property (strong, nonatomic) IBOutlet UIView *menubar;
@property (nonatomic) BOOL menubarCurrentDisabled;

@property (strong, nonatomic) IBOutlet UIView *toolbar;
@property (strong, nonatomic) IBOutlet UIButton *toolbarBack;
@property (strong, nonatomic) IBOutlet NSString *toolbarBackIcon;
@property (strong, nonatomic) IBOutlet UIButton *toolbarNext;
@property (strong, nonatomic) IBOutlet NSString *toolbarNextIcon;
@property (strong, nonatomic) IBOutlet UILabel *toolbarTitle;
@property (strong, nonatomic) IBOutlet UIColor *toolbarColor;
@property (strong, nonatomic) IBOutlet UIColor *toolbarTextColor;

@property (strong, nonatomic) IBOutlet UIImageView *profileImage;
@property (strong, nonatomic) IBOutlet UILabel *profileName;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UIButton *drawerView;

@property (strong, nonatomic) IBOutlet UITableView *table;
@property (strong, nonatomic) IBOutlet UITextField *tableSearch;
@property (strong, nonatomic) NSString* searchText;
@property (nonatomic, assign) BOOL tableUnselected;
@property (nonatomic, assign) BOOL tableRounded;
@property (nonatomic, assign) BOOL tableCentered;
@property (strong, nonatomic) NSString *tableCell;
@property (nonatomic, assign) NSInteger tableIndent;
@property (nonatomic, assign) NSInteger tableRows;
@property (nonatomic, assign) NSInteger tableSections;

@property (nonatomic, assign) CGRect panRect;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) UIStatusBarStyle barStyle;

- (void)configure;

- (void)addMenubar:(NSString*)current disabled:(NSArray*)disabled;
- (void)setMenubarParams:(NSString*)name params:(NSDictionary*)params;
- (void)setMenubarButton:(NSString*)name enabled:(BOOL)enabled;

- (UITextView*)addEmptyViewWithText:(NSAttributedString*)text;
- (void)addToolbar:(NSString*)title;
- (void)onBack:(id)sender;
- (void)onNext:(id)sender;

- (void)showPrevious;
- (void)showActivity;
- (void)hideActivity;
- (void)showActivity:(BOOL)incr;
- (void)hideActivity:(BOOL)decr;
- (MBProgressHUD*)showBlockingActivity;
- (void)hideBlockingActivity;

- (void)addTable;
- (void)reloadTable;
- (void)restoreTablePosition;
- (void)saveTablePosition;
- (void)queueTableSearch;
- (id)getItem:(NSIndexPath*)indexPath;
- (void)setItem:(NSIndexPath*)indexPath data:(id)data;
- (void)onSearch:(id)sender;
- (NSMutableArray*)filterItems:(NSArray*)items;

- (void)showDrawer;
- (void)closeDrawer;
- (void)prepareDrawerMode:(UIViewController*)owner;
- (void)preparePushMode:(UIViewController*)owner;

- (void)selectTableRow:(int)index animated:(BOOL)animated;
- (void)onTableCell:(UITableViewCell*)cell indexPath:(NSIndexPath*)indexPath;
- (void)onTableSelect:(NSIndexPath *)indexPath selected:(BOOL)selected;
- (void)onImagePicker:(UIImage*)image;

- (void)showImagePickerFromAlbums:(id)sender;
- (void)showImagePickerFromCamera:(id)sender;
- (void)showImagePickerFromLibrary:(id)sender;

- (void)accountUpdated:(NSNotification*)notification;
- (BOOL)isEmpty:(NSString*)name;
- (ViewController*)prevController;
@end

// View controllers
@interface AppSettingsViewController : ViewController
@end

@interface InviteFriendsViewController : ViewController
@end

@interface LinkedAccountsViewController : ViewController
@end

@interface BlackBookViewController : ViewController
@end

@interface ChatViewController : ViewController
@end

@interface InviteContactFriendsViewController : ViewController
@end

@interface InviteFacebookFriendsViewController : ViewController
- (void)showSMStoRecipients:(NSArray*)recipients inviteCode:(NSString *)code;
@end

@interface AlbumViewController : ViewController
@end

@interface MutualFriendsViewController : ViewController
@end

@interface NextViewController : ViewController
@end

@interface LoginViewController : ViewController
@end


@interface ProfileViewController : ViewController
@end

@interface PhotosViewController : ViewController
@end

@interface RegisterFacebookViewController : ViewController
@end

@interface RegisterViewController : ViewController
@end

@interface SettingsViewController : ViewController
@end

@interface SuccessViewController : ViewController
@end

@interface TrendingViewController : ViewController
@end

@interface EventsViewController : ViewController
@end

@interface MessageCell : UITableViewCell
- (void)configure:(id)item forIndex:(NSInteger)index by:(UIViewController*)vc;
@property MessageCountdownView* countdown;
@end

@interface MessagesViewController : ViewController
@property (nonatomic, strong) Account* account;
@end
