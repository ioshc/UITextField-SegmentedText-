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

- (void)setRepert:(BOOL)repert {
    objc_setAssociatedObject(self,
                             &keyEDHSTUITextFieldRepeat,
                             @(repert),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)repert {
    NSNumber *repeat = objc_getAssociatedObject(self, &keyEDHSTUITextFieldRepeat);
    if (!repeat) {
        return NO;
    }
    return [repeat boolValue];
}

- (void)setSegmentSpacing:(CGFloat)segmentSpacing {
    objc_setAssociatedObject(self,
                             &keyEDHSTUITextFieldSegementSpacing,
                             @(segmentSpacing),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)segmentSpacing {
    NSNumber *width = objc_getAssociatedObject(self, &keyEDHSTUITextFieldSegementSpacing);
    if (!width) {
        return 10.0f;
    }
    return [width floatValue];
}

- (void)setFormat:(NSString *)format {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(edh_handleTextDidChangeNotification:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:self];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(edh_handleDidEndEditingNotification:)
                                                     name:UITextFieldTextDidEndEditingNotification
                                                   object:self];
    });

    objc_setAssociatedObject(self,
                             &keyEDHSTUITextFieldFormat,
                             format, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)format {
    return objc_getAssociatedObject(self, &keyEDHSTUITextFieldFormat);
}

#pragma mark - Handle Notification

- (void)edh_handleTextDidChangeNotification:(NSNotification *)notification {

    if (notification.object != self) {
        return;
    }

    //Execute format in next runloop. Make sure other object modify the text of this textField
    dispatch_async(dispatch_get_main_queue(), ^{
        [self p_formatString];
    });
}

- (void)edh_handleDidEndEditingNotification:(NSNotification *)notification {

    if (notification.object != self) {
        return;
    }

    /*  When user finish inputting, if typingAttributes contains Kern attribute, systerm will
        save the Kern attribute into defaultTextAttributes and the defaultTextAttributes will
        apply to all text.
        eg. User want "XXX XXXX XXXX", user inputted "XXX XXXX |('|' is the cursor)", then finish
            inputting, the text will change to "X X X X X X X", user input again, the text just like
            "X X X ......" forever
        So we need to remove the Kern attribute and format the text.
    */
    NSMutableDictionary *dict = [self.defaultTextAttributes mutableCopy];
    [dict removeObjectForKey:NSKernAttributeName];
    self.defaultTextAttributes = dict;

    [self p_formatString];
}

#pragma mark - Kern Implementation

- (void)p_formatString {

    if (self.format.length == 0) return;

    //add global attributes
    NSDictionary *globalAttributes = @{NSForegroundColorAttributeName: self.textColor,
                                       NSFontAttributeName: self.font
                                       };
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:self.text
                                                                                attributes:globalAttributes];

    //divide segments
    NSArray *segments = [self.format componentsSeparatedByString:@" "];

    //calc the length of each format loop
    NSInteger oneLoopTextLength = [self.format stringByReplacingOccurrencesOfString:@" " withString:@""].length;

    //calc the loop count
    NSInteger loopCount = 1;
    if (self.repert) {
        loopCount = ceil(self.text.length / (double)oneLoopTextLength);
    }

    //build kern attribute
    NSDictionary *kernAttribute = @{NSKernAttributeName : @(self.segmentSpacing)};

    //add kern attribute for each format loop
    for (int i = 0 ; i < loopCount; i++) {

        NSInteger segmentLocation = 0 + i * oneLoopTextLength;
        //add kern attribute for each segment
        for (NSString *segment in segments) {

            if (segment.length == 0) return;

            segmentLocation += segment.length;
            if (self.text.length > segmentLocation - 1) {
                [attrStr addAttributes:kernAttribute range:NSMakeRange(segmentLocation - 1, 1)];
            }
        }
    }

    self.attributedText = attrStr;
}

@end
