#import "UITextField+done.h"

@implementation UITextField (done)


- (void)addDoneAccessory
{
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(10, 0, 310, 45)];
    //toolbar.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *toolbarDone = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(resignFirstResponder)];
    
    toolbar.items = [NSArray arrayWithObjects:spacer, toolbarDone, nil];
    
    [self setInputAccessoryView:toolbar];
}

@end
