//
//  PTKPaymentField.h
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PTKCard.h"
#import "PTKCardNumber.h"
#import "PTKCardExpiry.h"
#import "PTKCardCVC.h"
#import "PTKAddressZip.h"
#import "PTKUSAddressZip.h"

typedef NS_ENUM(NSUInteger, PTKState) {
    PTKStateCardNumber,
    PTKStateExpiryDate,
    PTKStateCVC
};

@class PTKView, PTKTextField;

@protocol PTKViewDelegate <NSObject>
@optional
- (void)paymentView:(PTKView *)paymentView withCard:(PTKCard *)card isValid:(BOOL)valid;
@end

@interface PTKView : UIView

- (void)transitionToState:(PTKState)state;
- (void)transitionToState:(PTKState)state becomeFirstResponder:(BOOL)shouldBecomeFirstResponder;

- (BOOL)isValid;

@property (nonatomic, readonly) UIView *opaqueOverGradientView;
@property (nonatomic, readonly) PTKCardNumber *cardNumber;
@property (nonatomic, readonly) PTKCardExpiry *cardExpiry;
@property (nonatomic, readonly) PTKCardCVC *cardCVC;
@property (nonatomic, readonly) PTKAddressZip *addressZip;

@property IBOutlet UIView *innerView;
@property IBOutlet UIView *clipView;
@property IBOutlet PTKTextField *cardNumberField;
@property IBOutlet PTKTextField *cardExpiryField;
@property IBOutlet PTKTextField *cardCVCField;
@property IBOutlet UIImageView *placeholderView;
@property (nonatomic, weak) id <PTKViewDelegate> delegate;
@property (readonly) PTKCard *card;

/**
 *  A UIFont property to set the font for the `cardNumberField`, `cardExpiryField`, `cardCVCField` text fields.
 */
@property (strong, nonatomic, readwrite) UIFont *textFieldFont;

/**
 *  A UIColor property to set the text color for the `cardNumberField`, `cardExpiryField`, `cardCVCField` text fields.
 */
@property (strong, nonatomic, readwrite) UIColor *textFieldTextColor;

/**
 *  A UIColor property to set the border of the view.
 */
@property (strong, nonatomic, readwrite) UIColor *borderColor;

@end
