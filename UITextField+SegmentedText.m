//
//  UITextField+SegmentedText.m
//  SegmentedText
//
//  Created by eden on 2018/3/21.
//  Copyright © 2018年 SegmentedText. All rights reserved.
//

#import "UITextField+SegmentedText.h"
#import <objc/runtime.h>

NSString *const keyEDHSTUITextFieldFormatMobile = @"XXX XXXX XXXX";
NSString *const keyEDHSTUITextFieldFormatBankCardNumber = @"XXXX XXXX XXXX XXXX XXX";

static char keyEDHSTUITextFieldMaxLength;
static char keyEDHSTUITextFieldRepeat;
static char keyEDHSTUITextFieldFormat;
static char keyEDHSTUITextFieldSegementSpacing;

@implementation UITextField (SegmentedText)

#pragma mark - Swizzle Dealloc

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self.class, NSSelectorFromString(@"dealloc")),
                                   class_getInstanceMethod(self.class, @selector(edh_swizzledDealloc)));
}

- (void)edh_swizzledDealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self edh_swizzledDealloc];
}

#pragma mark - Accessors

- (void)setMaxLength:(NSInteger)maxLength {
    [self p_setValue:@(maxLength) forPropertyKey:&keyEDHSTUITextFieldMaxLength];
}

- (NSInteger)maxLength {
    NSNumber *maxLength = [self p_valueForPropertyKey:&keyEDHSTUITextFieldMaxLength];
    if (!maxLength) {
        return LONG_MAX;
    }
    return [maxLength integerValue];
}

- (void)setRepert:(BOOL)repert {
    [self p_setValue:@(repert) forPropertyKey:&keyEDHSTUITextFieldRepeat];
}

- (BOOL)repert {
    NSNumber *repeat = [self p_valueForPropertyKey:&keyEDHSTUITextFieldRepeat];
    if (!repeat) {
        return NO;
    }
    return [repeat boolValue];
}

- (void)setSegmentSpacing:(CGFloat)segmentSpacing {
    [self p_setValue:@(segmentSpacing) forPropertyKey:&keyEDHSTUITextFieldSegementSpacing];
}

- (CGFloat)segmentSpacing {
    NSNumber *width = [self p_valueForPropertyKey:&keyEDHSTUITextFieldSegementSpacing];
    if (!width) {
        return 10.0f;
    }
    return [width floatValue];
}

- (void)setFormat:(NSString *)format {

    //register notification when user set format first time
    if (self.format == nil) {
        [self p_registerNotification];
    }

    [self p_setValue:format forPropertyKey:&keyEDHSTUITextFieldFormat];
}

- (NSString *)format {
    return [self p_valueForPropertyKey:&keyEDHSTUITextFieldFormat];
}

#pragma mark - Public

- (void)edh_setSegmentedText:(NSString *)text {
    self.text = text;
    [self p_addKernToText];
}

#pragma mark - Runtime

- (void)p_setValue:(id)value forPropertyKey:(const void *)propertyKey {
    objc_setAssociatedObject(self,
                             propertyKey,
                             value,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)p_valueForPropertyKey:(const void *)propertyKey {
    return objc_getAssociatedObject(self, propertyKey);
}

#pragma mark - Handle Notification

- (void)p_registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(edh_handleTextDidChangeNotification:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self];
}

- (void)edh_handleTextDidChangeNotification:(NSNotification *)notification {

    if (notification.object != self) {
        return;
    }

    [self p_addKernToText];
}

#pragma mark - Kern Implementation

- (void)p_addKernToText {

    if (self.format.length == 0) return;

    NSString *originalText = self.text;

    //limit the text length 
    if (originalText.length > self.maxLength) {
        originalText = [originalText substringToIndex:self.maxLength];
    }

    //add global attributes
    NSDictionary *globalAttributes = @{NSForegroundColorAttributeName: self.textColor,
                                       NSFontAttributeName: self.font
                                       };
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:originalText
                                                                                attributes:globalAttributes];

    //divide segments
    NSArray *segments = [self.format componentsSeparatedByString:@" "];

    //calc the length of each format loop
    NSInteger oneLoopTextLength = [self.format stringByReplacingOccurrencesOfString:@" " withString:@""].length;

    //calc the loop count
    NSInteger loopCount = 1;
    if (self.repert) {
        loopCount = ceil(originalText.length / (double)oneLoopTextLength);
    }

    //build kern attribute
    NSDictionary *kernAttribute = @{NSKernAttributeName : @(self.segmentSpacing)};

    //add kern attribute for each format loop
    for (int i = 0 ; i < loopCount; i++) {

        NSInteger indexOfCharWhichBeSpacingWithPrevOne = 0 + i * oneLoopTextLength;
        //add kern attribute for each segment
        for (NSString *segment in segments) {

            if (segment.length == 0) break;

            //find the idx of char which will be adding space (begin with 1)
            indexOfCharWhichBeSpacingWithPrevOne += segment.length;

            //dont add spacing to the last char
            if (indexOfCharWhichBeSpacingWithPrevOne == self.maxLength) break;

            //just when the total length bigger than the idx of char which need to add spacing.
            if (originalText.length > indexOfCharWhichBeSpacingWithPrevOne) {
                NSInteger location = indexOfCharWhichBeSpacingWithPrevOne - 1;
                [attrStr addAttributes:kernAttribute range:NSMakeRange(location, 1)];
            }
        }
    }

    self.attributedText = attrStr;
}

@end
