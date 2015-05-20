//
//  MFJLabel.h
//
//  Copyright (c) 2013 Malcolm Jarvis (github.com/mjarvis). All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>

@protocol MFJLabelDelegate;

extern NSString * const MFJLabelLinkAttributeName;
extern NSString * const MFJLabelPhoneNumberAttributeName;
extern NSString * const MFJLabelAddressAttributeName;
extern NSString * const MFJLabelDateAttributeName;

typedef NS_OPTIONS(uint64_t, MFJDataDetectorType)
{
    MFJDataDetectorTypeDate                 = NSTextCheckingTypeDate,
    MFJDataDetectorTypeAddress              = NSTextCheckingTypeAddress,
    MFJDataDetectorTypeLink                 = NSTextCheckingTypeLink,
    MFJDataDetectorTypePhoneNumber          = NSTextCheckingTypePhoneNumber,
};

/**
 *  MFJLabel is a UILabel subclass that adds support for automatically converting links to clickable items.
 *  Use `- (CGSize)sizeThatFits:(CGSize)size` to find the bounding size for the text if needed.
 *  Note: numberOfLines is not currently supported, and is assumed 0.
 */
@interface MFJLabel : UILabel

@property (nonatomic, weak) id <MFJLabelDelegate> delegate;

/**
 *  The drawn textStorage. Set internally when setting the text or attributedText properties.
 */
@property (nonatomic, copy) NSTextStorage *textStorage;

/**
 * The orginal attributed string set on the label. Apple manipulates the attributed string on the label and we end up loosing attributes when setting `textColor` and `font` on the label.
 */

@property (nonatomic, copy) NSAttributedString *originalAttributedString;
/**
 *  Available NSTextCheckingType values are defined in MFJDataDetectorType.
 *  Defaults to all available types.
 */
@property (nonatomic, assign) MFJDataDetectorType dataDetectorTypes;

/**
 *  Attributes appled to detected links. Available keys can be found in <UIKit/NSAttributedString.h>
 *  NSBackgroundColorAttributeName is used for a link's highlighted state.
 *  Defaults to blue and underlined, with a grey highlight.
 */
@property (nonatomic, strong) NSDictionary *linkAttributes;

/**
 *  Used internally to create the text storage used to render the text. Can be used externally to pre-cache the text with detected links, as NSDataDetector can be slow for longer text.
 *
 *  @param attributedString An NSAttributedString containing the text to detect links in.
 *
 *  @return NSTextStorage with added attributes for detected links.
 */
- (NSTextStorage *)textStorageWithDetectedLinksForAttributedString:(NSAttributedString *)attributedString;

@end

@protocol MFJLabelDelegate <NSObject>

/**
 *  Called when the user touches and releases quickly on a detected link. Usually used for a primary action.
 *
 *  @param label      The MFJLabel instance that received the touch
 *  @param linkText   The displayed text for the link at the tap point
 *  @param attributes NSAttributedString attributes for the link at the tap point. See the constants at the top of this file for NSTextCheckingResult component accessor keys.
 */
- (void)label:(MFJLabel *)label didTapLinkText:(NSString *)linkText withAttributes:(NSDictionary *)attributes;

/**
 *  Called when the user touches holds on a detected link. Usually used for a secondary action such as displaying an action sheet or menu controller with multiple user choices.
 *
 *  @param label      The MFJLabel instance that received the touch
 *  @param linkText   The displayed text for the link at the hold point
 *  @param attributes NSAttributedString attributes for the link at the hold point. See the constants at the top of this file for NSTextCheckingResult component accessor keys.
 */
- (void)label:(MFJLabel *)label didLongPressLinkText:(NSString *)linkText withAttributes:(NSDictionary *)attributes;

@end
