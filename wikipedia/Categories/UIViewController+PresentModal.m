//  Created by Monte Hurd on 5/28/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+PresentModal.h"
#import "ModalMenuAndContentViewController.h"

@implementation UIViewController (PresentModal)

- (void)performModalSequeWithID: (NSString *)identifier
               transitionStyle: (UIModalTransitionStyle)style
                         block: (void (^)(id))block;
{
    ModalMenuAndContentViewController *modalMenuAndContentVC =
    [NAV.storyboard instantiateViewControllerWithIdentifier:@"ModalMenuAndContentViewController"];

    modalMenuAndContentVC.modalTransitionStyle = style;

    modalMenuAndContentVC.sequeIdentifier = identifier;
    modalMenuAndContentVC.block = block;
    [self presentViewController:modalMenuAndContentVC animated:YES completion:^{}];
}

@end
