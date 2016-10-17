#import <UIKit/UIKit.h>

#import <KiipSDK/KiipSDK.h>

#import "BrowseCardView.h"
#import "MatchPopupNotification.h"
#import "ChatPopupNotification.h"
#import "ContactPopupNotification.h"
#import "KiipPopupNotification.h"
#import "LocationServicesViewController.h"
#import "NoInternetViewController.h"

@interface BrowseViewController : ViewController <CardDelegateProtocol, UIAlertViewDelegate>

@property (strong, atomic) NSMutableArray *jsonItems;

@end