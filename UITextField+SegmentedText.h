//
//  UITextField+SegmentedText.h
//  SegmentedText
//
//  Created by eden on 2018/3/21.
//  Copyright © 2018年 SegmentedText. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const keyEDHSTUITextFieldFormatMobile;  //mobile number. eg. 180 0000 0000
extern NSString *const keyEDHSTUITextFieldFormatBankCardNumber;  //bank card number. eg. XXXX XXXX XXXX XXXX XXX

@interface UITextField (SegmentedText)

@property (nonatomic) NSInteger maxLength;      //Max length of text. Default is LONG_MAX
@property (nonatomic) BOOL repert;              //Should repeat the format. Default is NO
@property (nonatomic) CGFloat segmentSpacing;   //Spacing between segment. Default is 10.0f
@property (nonatomic, copy) NSString *format;   //Like "XXX XXXX XXXX" separated by blank space


/**
 Replaces the value of the text property and displayed segmented

 @param text The text will be displayed segmented.
 */
- (void)edh_setSegmentedText:(NSString *)text;

@end
