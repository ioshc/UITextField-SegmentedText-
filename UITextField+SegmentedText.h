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

@property (nonatomic)   NSInteger maxLength;      //max length of text. Default is LONG_MAX
@property (nonatomic)   BOOL repert;              //should repeat the format. Default is NO
@property (nonatomic)   CGFloat segmentSpacing;   //spacing between segment. Default is 10.0f
@property (nonatomic, copy)     NSString *format;   //like "XXX XXXX XXXX" separated by blank space

@end
