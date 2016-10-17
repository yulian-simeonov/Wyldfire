//Yulian Simeonov Prior Code Library

#import <UIKit/UIKit.h>
#import "KFOZoomView.h"

@interface InspectViewController : UIViewController

@property (nonatomic, strong) KFOImageZoomView* zoomView;

@property (nonatomic, strong) UIImage* image;

- (id)initWithImage:(UIImage*)image;

@end
