//
//  PTKPaymentField.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#define kPTKViewPlaceholderViewAnimationDuration 0.25

#define kPTKViewCardExpiryFieldStartX 84 + 200
#define kPTKViewCardCVCFieldStartX 177 + 200

#define kPTKViewCardExpiryFieldEndX 84
#define kPTKViewCardCVCFieldEndX 177

static NSString * const kPTKLocalizedStringsTableName = @"PaymentKit";
static NSString * const kPTKOldLocalizedStringsTableName = @"STPaymentLocalizable";
static CGFloat  const kPTKContentLeftInset = 12.0f;

#import "PTKView.h"
#import "PTKTextField.h"

@interface PTKView () <PTKTextFieldDelegate> {
@private
    BOOL _isInitialState;
    BOOL _isValidState;

    NSLayoutConstraint *_numberFieldLeftConstraint;
    NSLayoutConstraint *_numberFieldWidthConstraint;
    NSLayoutConstraint *_expiryFieldLeftConstraint;
}

@property (nonatomic, readonly, assign) UIResponder *firstResponderField;
@property (nonatomic, readonly, assign) PTKTextField *firstInvalidField;
@property (nonatomic, readonly, assign) PTKTextField *nextFirstResponder;

- (void)setup;
- (void)setupPlaceholderView;
- (void)setupCardNumberField;
- (void)setupCardExpiryField;
- (void)setupCardCVCField;

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PTKTextField *)textField;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;

@property (nonatomic) UIView *opaqueOverGradientView;
@property (nonatomic) PTKCardNumber *cardNumber;
@property (nonatomic) PTKCardExpiry *cardExpiry;
@property (nonatomic) PTKCardCVC *cardCVC;
@property (nonatomic) PTKAddressZip *addressZip;
@end

#pragma mark -

@implementation PTKView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    _isInitialState = YES;
    _isValidState = NO;

    self.backgroundColor = [UIColor whiteColor];
    
    self.textFieldFont      = [UIFont systemFontOfSize:17.0f];
    self.textFieldTextColor = [UIColor darkGrayColor];
    self.borderColor        = [UIColor colorWithWhite:0.5f alpha:0.5f];
    
    self.layer.cornerRadius = 5.0f;
    self.layer.borderWidth = 1.0f;
    
    self.innerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.innerView.clipsToBounds = YES;
    self.innerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self setupCardNumberField];
    [self setupCardExpiryField];
    [self setupCardCVCField];

    self.opaqueOverGradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, self.frame.size.height)];
    self.opaqueOverGradientView.backgroundColor = [UIColor whiteColor];
    
    self.opaqueOverGradientView.alpha = 0.8f;
    [self.innerView addSubview:self.opaqueOverGradientView];

    [self addSubview:self.innerView];

    [self setupPlaceholderView];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-40-[innerView]-0-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"innerView": self.innerView}]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[innerView]-0-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"innerView": self.innerView}]];

    [self stateCardNumber];
}


- (void)setupPlaceholderView
{
    self.placeholderView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.placeholderView.backgroundColor = [UIColor clearColor];
    self.placeholderView.image = [UIImage imageNamed:@"placeholder"];
    self.placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self insertSubview:self.placeholderView aboveSubview:self.innerView];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderView
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0f
                                                                       constant:kPTKContentLeftInset];
    
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1.0f
                                                                          constant:0.0f];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:0.0f
                                                                        constant:32.0f];
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.placeholderView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:0.0f
                                                                         constant:20.0f];
    
    [self addConstraints:@[leftConstraint, centerYConstraint, widthConstraint, heightConstraint]];
}

- (void)setupCardNumberField
{
    self.cardNumberField = [[PTKTextField alloc] initWithFrame:CGRectZero];
    self.cardNumberField.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardNumberField.delegate = self;
    self.cardNumberField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_number" defaultValue:@"1234 5678 9012 3456"];
    self.cardNumberField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardNumberField.textColor = self.textFieldTextColor;
    self.cardNumberField.font = self.textFieldFont;

    [self.cardNumberField.layer setMasksToBounds:YES];
    
    [self.innerView addSubview:self.cardNumberField];
    
    _numberFieldLeftConstraint =  [NSLayoutConstraint constraintWithItem:self.cardNumberField
                                                               attribute:NSLayoutAttributeLeft
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.innerView
                                                               attribute:NSLayoutAttributeLeft
                                                              multiplier:1.0f
                                                                constant:kPTKContentLeftInset];
    
    [self.innerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cardNumberField]-0-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:@{@"cardNumberField": self.cardNumberField}]];

    _numberFieldWidthConstraint = [NSLayoutConstraint constraintWithItem:self.cardNumberField
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.innerView
                                                               attribute:NSLayoutAttributeWidth
                                                              multiplier:1.0f
                                                                constant:-kPTKContentLeftInset];
    
    [self.innerView addConstraints:@[_numberFieldLeftConstraint, _numberFieldWidthConstraint]];
}

- (void)setupCardExpiryField
{
    self.cardExpiryField = [[PTKTextField alloc] initWithFrame:CGRectZero];
    self.cardExpiryField.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardExpiryField.delegate = self;
    self.cardExpiryField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_expiry" defaultValue:@"MM/YY"];
    self.cardExpiryField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardExpiryField.textColor = self.textFieldTextColor;
    self.cardExpiryField.font = self.textFieldFont;

    [self.cardExpiryField.layer setMasksToBounds:YES];
    [self.innerView addSubview:self.cardExpiryField];
    
    [self.innerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cardExpiryField]-0-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:@{@"cardExpiryField": self.cardExpiryField}]];

    [self.innerView addConstraint:[NSLayoutConstraint constraintWithItem:self.cardExpiryField
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.innerView
                                                               attribute:NSLayoutAttributeWidth
                                                              multiplier:0.25f
                                                                constant:0.0f]];
    
    _expiryFieldLeftConstraint = [NSLayoutConstraint constraintWithItem:self.cardExpiryField
                                                              attribute:NSLayoutAttributeLeft
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardNumberField
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1.0f
                                                               constant:10.0f];
    
    [self.innerView addConstraint:_expiryFieldLeftConstraint];
}

- (void)setupCardCVCField
{
    self.cardCVCField = [[PTKTextField alloc] initWithFrame:CGRectZero];
    self.cardCVCField.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardCVCField.delegate = self;
    self.cardCVCField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_cvc" defaultValue:@"CVC"];
    self.cardCVCField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardCVCField.textColor = self.textFieldTextColor;
    self.cardCVCField.font = self.textFieldFont;

    [self.cardCVCField.layer setMasksToBounds:YES];
    [self.innerView addSubview:self.cardCVCField];
    
    [self.innerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cardCVCField]-0-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:@{@"cardCVCField": self.cardCVCField}]];
    
    [self.innerView addConstraint:[NSLayoutConstraint constraintWithItem:self.cardCVCField
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.innerView
                                                               attribute:NSLayoutAttributeWidth
                                                              multiplier:0.25f
                                                                constant:0.0f]];

    [self.innerView addConstraint:[NSLayoutConstraint constraintWithItem:self.cardCVCField
                                                               attribute:NSLayoutAttributeLeft
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.cardExpiryField
                                                               attribute:NSLayoutAttributeRight
                                                              multiplier:1.0f
                                                                constant:10.0f]];

}

- (void)setTextFieldFont:(UIFont *)textFieldFont {
    _textFieldFont = textFieldFont;

    self.cardNumberField.font = textFieldFont;
    self.cardExpiryField.font = textFieldFont;
    self.cardCVCField.font    = textFieldFont;
}

- (void)setTextFieldTextColor:(UIColor *)textFieldTextColor {
    _textFieldTextColor = textFieldTextColor;

    self.cardNumberField.textColor = textFieldTextColor;
    self.cardExpiryField.textColor = textFieldTextColor;
    self.cardCVCField.textColor    = textFieldTextColor;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    
    self.layer.borderColor = borderColor.CGColor;
}

// Checks both the old and new localization table (we switched in 3/14 to PaymentKit.strings).
// Leave this in for a long while to preserve compatibility.
+ (NSString *)localizedStringWithKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
    NSString *value = NSLocalizedStringFromTable(key, kPTKLocalizedStringsTableName, nil);
    if (value && ![value isEqualToString:key]) { // key == no value
        return value;
    } else {
        value = NSLocalizedStringFromTable(key, kPTKOldLocalizedStringsTableName, nil);
        if (value && ![value isEqualToString:key]) {
            return value;
        }
    }

    return defaultValue;
}

#pragma mark - Accessors

- (PTKCardNumber *)cardNumber
{
    return [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
}

- (PTKCardExpiry *)cardExpiry
{
    return [PTKCardExpiry cardExpiryWithString:self.cardExpiryField.text];
}

- (PTKCardCVC *)cardCVC
{
    return [PTKCardCVC cardCVCWithString:self.cardCVCField.text];
}

#pragma mark - State

- (void)stateCardNumber
{
    if (!_isInitialState) {
        // Animate left
        _isInitialState = YES;

        [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.opaqueOverGradientView.alpha = 0.7f;
                         } completion:^(BOOL finished) {
        }];
        
        self.cardNumberField.textAlignment = NSTextAlignmentLeft;
        
        [self.innerView removeConstraint:_numberFieldWidthConstraint];
        [self.innerView removeConstraint:_expiryFieldLeftConstraint];
        
        _numberFieldWidthConstraint = [NSLayoutConstraint constraintWithItem:self.cardNumberField
                                                                   attribute:NSLayoutAttributeWidth
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.innerView
                                                                   attribute:NSLayoutAttributeWidth
                                                                  multiplier:1.0f
                                                                    constant:-kPTKContentLeftInset];
        [self.innerView addConstraint:_numberFieldWidthConstraint];
        [self.innerView layoutIfNeeded];
        
        _numberFieldLeftConstraint.constant = kPTKContentLeftInset;
        
        [self.cardNumberField setNeedsUpdateConstraints];
        [self.innerView addConstraint:_expiryFieldLeftConstraint];
        
        [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.7f initialSpringVelocity:0.7f options:0 animations:^{
            [self.innerView setNeedsLayout];
            [self.innerView layoutIfNeeded];
        } completion:nil];
    }

    [self.cardNumberField becomeFirstResponder];
}

- (void)stateMeta
{
    _isInitialState = NO;

    CGSize cardNumberSize;
    CGSize lastGroupSize;
    
    NSDictionary *attributes = @{NSFontAttributeName: self.textFieldFont};
    
    cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
    lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
    
    [UIView animateWithDuration:0.05 delay:0.35 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.opaqueOverGradientView.alpha = 1.0;
                     } completion:^(BOOL finished) {
    }];
    
    [self.innerView removeConstraint:_numberFieldWidthConstraint];
    
    _numberFieldWidthConstraint = [NSLayoutConstraint constraintWithItem:self.cardNumberField
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:0.0f
                                                                constant:cardNumberSize.width + kPTKContentLeftInset];
    [self.innerView addConstraint:_numberFieldWidthConstraint];

    self.cardNumberField.textAlignment = NSTextAlignmentRight;
    [self.innerView layoutIfNeeded];

    _numberFieldLeftConstraint.constant = lastGroupSize.width - cardNumberSize.width;
    
    [self.cardNumberField setNeedsUpdateConstraints];
    [self.innerView addConstraint:_expiryFieldLeftConstraint];
    
    [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.7f initialSpringVelocity:0.7f options:0 animations:^{
        [self.innerView setNeedsLayout];
        [self.innerView layoutIfNeeded];
    } completion:nil];

    [self.cardExpiryField becomeFirstResponder];
}

- (void)stateCardCVC
{
    [self.cardCVCField becomeFirstResponder];
}

- (BOOL)isValid
{
    return [self.cardNumber isValid] && [self.cardExpiry isValid] &&
            [self.cardCVC isValidWithType:self.cardNumber.cardType];
}

- (PTKCard *)card
{
    PTKCard *card = [[PTKCard alloc] init];
    card.number = [self.cardNumber string];
    card.cvc = [self.cardCVC string];
    card.expMonth = [self.cardExpiry month];
    card.expYear = [self.cardExpiry year];

    return card;
}

- (void)setPlaceholderViewImage:(UIImage *)image
{
    if (![self.placeholderView.image isEqual:image]) {
        __block __unsafe_unretained UIView *previousPlaceholderView = self.placeholderView;
        [UIView animateWithDuration:kPTKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.placeholderView.layer.opacity = 0.0;
                             self.placeholderView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2);
                         } completion:^(BOOL finished) {
            [previousPlaceholderView removeFromSuperview];
        }];
        self.placeholderView = nil;

        [self setupPlaceholderView];
        self.placeholderView.image = image;
        self.placeholderView.layer.opacity = 0.0;
        self.placeholderView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
        [self insertSubview:self.placeholderView belowSubview:previousPlaceholderView];
        [UIView animateWithDuration:kPTKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.placeholderView.layer.opacity = 1.0;
                             self.placeholderView.layer.transform = CATransform3DIdentity;
                         } completion:^(BOOL finished) {
        }];
    }
}

- (void)setPlaceholderToCVC
{
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
    PTKCardType cardType = [cardNumber cardType];

    if (cardType == PTKCardTypeAmex) {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc-amex"]];
    } else {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc"]];
    }
}

- (void)setPlaceholderToCardType
{
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
    PTKCardType cardType = [cardNumber cardType];
    NSString *cardTypeName = @"placeholder";

    switch (cardType) {
        case PTKCardTypeAmex:
            cardTypeName = @"amex";
            break;
        case PTKCardTypeDinersClub:
            cardTypeName = @"diners";
            break;
        case PTKCardTypeDiscover:
            cardTypeName = @"discover";
            break;
        case PTKCardTypeJCB:
            cardTypeName = @"jcb";
            break;
        case PTKCardTypeMasterCard:
            cardTypeName = @"mastercard";
            break;
        case PTKCardTypeVisa:
            cardTypeName = @"visa";
            break;
        default:
            break;
    }

    [self setPlaceholderViewImage:[UIImage imageNamed:cardTypeName]];
}

#pragma mark - Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:self.cardCVCField]) {
        [self setPlaceholderToCVC];
    } else {
        [self setPlaceholderToCardType];
    }

    if ([textField isEqual:self.cardNumberField] && !_isInitialState) {
        [self stateCardNumber];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    if ([textField isEqual:self.cardNumberField]) {
        return [self cardNumberFieldShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if ([textField isEqual:self.cardExpiryField]) {
        return [self cardExpiryShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if ([textField isEqual:self.cardCVCField]) {
        return [self cardCVCShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    return YES;
}

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PTKTextField *)textField
{
    if (textField == self.cardCVCField)
        [self.cardExpiryField becomeFirstResponder];
    else if (textField == self.cardExpiryField)
        [self stateCardNumber];
}

- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardNumberField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:resultString];

    if (![cardNumber isPartiallyValid])
        return NO;

    if (replacementString.length > 0) {
        self.cardNumberField.text = [cardNumber formattedStringWithTrail];
    } else {
        self.cardNumberField.text = [cardNumber formattedString];
    }

    [self setPlaceholderToCardType];

    if ([cardNumber isValid]) {
        [self textFieldIsValid:self.cardNumberField];
        [self stateMeta];

    } else if ([cardNumber isValidLength] && ![cardNumber isValidLuhn]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:YES];

    } else if (![cardNumber isValidLength]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:NO];
    }

    return NO;
}

- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardExpiryField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardExpiry *cardExpiry = [PTKCardExpiry cardExpiryWithString:resultString];

    if (![cardExpiry isPartiallyValid]) return NO;

    // Only support shorthand year
    if ([cardExpiry formattedString].length > 5) return NO;

    if (replacementString.length > 0) {
        self.cardExpiryField.text = [cardExpiry formattedStringWithTrail];
    } else {
        self.cardExpiryField.text = [cardExpiry formattedString];
    }

    if ([cardExpiry isValid]) {
        [self textFieldIsValid:self.cardExpiryField];
        [self stateCardCVC];

    } else if ([cardExpiry isValidLength] && ![cardExpiry isValidDate]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:YES];
    } else if (![cardExpiry isValidLength]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:NO];
    }

    return NO;
}

- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardCVCField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardCVC *cardCVC = [PTKCardCVC cardCVCWithString:resultString];
    PTKCardType cardType = [[PTKCardNumber cardNumberWithString:self.cardNumberField.text] cardType];

    // Restrict length
    if (![cardCVC isPartiallyValidWithType:cardType]) return NO;

    // Strip non-digits
    self.cardCVCField.text = [cardCVC string];

    if ([cardCVC isValidWithType:cardType]) {
        [self textFieldIsValid:self.cardCVCField];
    } else {
        [self textFieldIsInvalid:self.cardCVCField withErrors:NO];
    }

    return NO;
}


#pragma mark - Validations

- (void)checkValid
{
    if ([self isValid]) {
        _isValidState = YES;

        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:YES];
        }

    } else if (![self isValid] && _isValidState) {
        _isValidState = NO;

        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:NO];
        }
    }
}

- (void)textFieldIsValid:(UITextField *)textField
{
    textField.textColor = self.textFieldTextColor;
    [self checkValid];
}

- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors
{
    if (errors) {
        textField.textColor = [UIColor colorWithRed:231.0f/255.0f green:76.0f/255.0f blue:60.0f/255.0f alpha:1.0f];
        self.layer.borderColor = [UIColor colorWithRed:231.0f/255.0f green:76.0f/255.0f blue:60.0f/255.0f alpha:1.0f].CGColor;

        CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        CGFloat currentTx = self.transform.tx;
        
        animation.delegate = self;
        animation.duration = 0.5f;
        animation.values = @[ @(currentTx), @(currentTx + 10), @(currentTx-8), @(currentTx + 8), @(currentTx -5), @(currentTx + 5), @(currentTx) ];
        animation.keyTimes = @[ @(0), @(0.225), @(0.425), @(0.6), @(0.75), @(0.875), @(1) ];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.layer addAnimation:animation forKey:@"MXLPaymentKitShakeAnimationKey"];
    } else {
        textField.textColor = self.textFieldTextColor;
        self.layer.borderColor = self.borderColor.CGColor;
    }

    [self checkValid];
}

#pragma mark -
#pragma mark UIResponder
- (UIResponder *)firstResponderField;
{
    NSArray *responders = @[self.cardNumberField, self.cardExpiryField, self.cardCVCField];
    for (UIResponder *responder in responders) {
        if (responder.isFirstResponder) {
            return responder;
        }
    }

    return nil;
}

- (PTKTextField *)firstInvalidField;
{
    if (![[PTKCardNumber cardNumberWithString:self.cardNumberField.text] isValid])
        return self.cardNumberField;
    else if (![[PTKCardExpiry cardExpiryWithString:self.cardExpiryField.text] isValid])
        return self.cardExpiryField;
    else if (![[PTKCardCVC cardCVCWithString:self.cardCVCField.text] isValid])
        return self.cardCVCField;

    return nil;
}

- (PTKTextField *)nextFirstResponder;
{
    if (self.firstInvalidField)
        return self.firstInvalidField;

    return self.cardCVCField;
}

- (BOOL)isFirstResponder;
{
    return self.firstResponderField.isFirstResponder;
}

- (BOOL)canBecomeFirstResponder;
{
    return self.nextFirstResponder.canBecomeFirstResponder;
}

- (BOOL)becomeFirstResponder;
{
    return [self.nextFirstResponder becomeFirstResponder];
}

- (BOOL)canResignFirstResponder;
{
    return self.firstResponderField.canResignFirstResponder;
}

- (BOOL)resignFirstResponder;
{
    [super resignFirstResponder];
    
    return [self.firstResponderField resignFirstResponder];
}

@end
