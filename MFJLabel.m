//
//  MFJLabel.m
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

#import "MFJLabel.h"

NSString * const MFJLabelLinkAttributeName        = @"MFJLabelLinkAttributeName";
NSString * const MFJLabelPhoneNumberAttributeName = @"MFJLabelPhoneNumberAttributeName";
NSString * const MFJLabelAddressAttributeName     = @"MFJLabelAddressAttributeName";
NSString * const MFJLabelDateAttributeName        = @"MFJLabelDateAttributeName";

@interface MFJLabel () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSDataDetector *dataDetector;
@property (nonatomic, assign) NSRange linkRange;
@property (nonatomic, weak) NSTimer *timer;

@end

@implementation MFJLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(longPress:)];
        {
            longPress.minimumPressDuration = 0.0;
            longPress.delegate = self;
        }
        [self addGestureRecognizer:longPress];

        self.userInteractionEnabled = YES;
        self.lineBreakMode = NSLineBreakByWordWrapping;
        _linkAttributes = @{
                            NSForegroundColorAttributeName: [UIColor blueColor],
                            NSBackgroundColorAttributeName: [[UIColor blackColor] colorWithAlphaComponent:0.2],
                            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                            NSUnderlineColorAttributeName: [UIColor blueColor],
                            };
        _dataDetectorTypes = MFJDataDetectorTypeDate|MFJDataDetectorTypeAddress|MFJDataDetectorTypeLink|MFJDataDetectorTypePhoneNumber;
        _dataDetector = [[NSDataDetector alloc] initWithTypes:_dataDetectorTypes
                                                        error:NULL];
    }
    return self;
}

- (void)setText:(NSString *)text
{
    [super setText:text];

    self.textStorage = [self textStorageWithDetectedLinksForAttributedString:self.attributedText];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];

    self.textStorage = [self textStorageWithDetectedLinksForAttributedString:attributedText];
}

- (void)setDataDetectorTypes:(MFJDataDetectorType)dataDetectorTypes
{
    _dataDetectorTypes = dataDetectorTypes;

    self.dataDetector = dataDetectorTypes ? [[NSDataDetector alloc] initWithTypes:dataDetectorTypes
                                                                            error:NULL] : nil;

    self.textStorage = [self textStorageWithDetectedLinksForAttributedString:self.attributedText];
}

- (void)setTextColor:(UIColor *)textColor
{
    [super setTextColor:textColor];

    [self.textStorage addAttribute:NSForegroundColorAttributeName
                             value:textColor
                             range:NSMakeRange(0, [self.textStorage length])];

    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];

    [self.textStorage addAttribute:NSFontAttributeName
                             value:font
                             range:NSMakeRange(0, [self.textStorage length])];

    [self setNeedsDisplay];
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    [super setLineBreakMode:lineBreakMode];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    {
        paragraphStyle.lineBreakMode = lineBreakMode;
        paragraphStyle.alignment = self.textAlignment;
    }
    [self.textStorage addAttribute:NSParagraphStyleAttributeName
                             value:paragraphStyle
                             range:NSMakeRange(0, [self.textStorage length])];

    NSLayoutManager *layoutManager = [self.textStorage.layoutManagers firstObject];
    NSTextContainer *textContainer = [layoutManager.textContainers firstObject];
    textContainer.lineBreakMode = lineBreakMode;

    [self setNeedsDisplay];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    {
        paragraphStyle.lineBreakMode = self.lineBreakMode;
        paragraphStyle.alignment = textAlignment;
    }
    [self.textStorage addAttribute:NSParagraphStyleAttributeName
                             value:paragraphStyle
                             range:NSMakeRange(0, [self.textStorage length])];

    [self setNeedsDisplay];
}

- (void)setLinkAttributes:(NSDictionary *)linkAttributes
{
    _linkAttributes = linkAttributes;

    self.textStorage = [self textStorageWithDetectedLinksForAttributedString:self.attributedText];
}

- (void)setTextStorage:(NSTextStorage *)textStorage
{
    _textStorage = textStorage;

    [self.timer invalidate];
    self.linkRange = NSMakeRange(NSNotFound, 0);

    [self setNeedsDisplay];
}

- (void)setLinkRange:(NSRange)linkRange
{
    _linkRange = linkRange;

    [self setNeedsDisplay];
}

- (NSTextStorage *)textStorageWithDetectedLinksForAttributedString:(NSAttributedString *)attributedString
{
    if (attributedString == nil)
    {
        return nil;
    }

    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
    {
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        {
            NSTextContainer *textContainer = [[NSTextContainer alloc] init];
            {
                textContainer.lineFragmentPadding = 0.0;
            }
            [layoutManager addTextContainer:textContainer];
        }
        [textStorage addLayoutManager:layoutManager];

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        {
            paragraphStyle.lineBreakMode = self.lineBreakMode;
            paragraphStyle.alignment = self.textAlignment;
        }
        NSDictionary *attributes = @{
                                     NSParagraphStyleAttributeName: paragraphStyle,
                                     NSFontAttributeName: self.font,
                                     NSForegroundColorAttributeName: self.textColor,
                                     };
        [textStorage addAttributes:attributes
                             range:NSMakeRange(0, [textStorage length])];

        NSArray *matches = [self.dataDetector matchesInString:[textStorage string]
                                                      options:0
                                                        range:NSMakeRange(0, [textStorage length])];
        for (NSTextCheckingResult *match in matches)
        {
            NSMutableDictionary *linkAttributes = [self.linkAttributes ?: @{} mutableCopy];
            {
                switch (match.resultType)
                {
                    case NSTextCheckingTypeLink:
                        linkAttributes[MFJLabelLinkAttributeName] = match.URL;
                        break;
                    case NSTextCheckingTypePhoneNumber:
                        linkAttributes[MFJLabelPhoneNumberAttributeName] = match.phoneNumber;
                        break;
                    case NSTextCheckingTypeAddress:
                        linkAttributes[MFJLabelAddressAttributeName] = match.addressComponents;
                        break;
                    case NSTextCheckingTypeDate:
                        linkAttributes[MFJLabelDateAttributeName] = match.date;
                        break;
                    default:
                        break;
                }
            }
            [textStorage addAttributes:linkAttributes
                                 range:[match range]];
        }
    }
    return textStorage;
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    if (self.preferredMaxLayoutWidth > 0 && bounds.size.width > self.preferredMaxLayoutWidth)
    {
        bounds.size.width = self.preferredMaxLayoutWidth;
    }

    CGRect boundingRect = [self.textStorage boundingRectWithSize:bounds.size
                                                         options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                         context:nil];

    NSLayoutManager *layoutManager = [self.textStorage.layoutManagers firstObject];
    NSTextContainer *textContainer = [layoutManager.textContainers firstObject];

    boundingRect.size.width += textContainer.lineFragmentPadding * 2;

    return CGRectIntegral(boundingRect);
}

- (void)drawTextInRect:(CGRect)rect
{
    rect = [self textRectForBounds:self.bounds
            limitedToNumberOfLines:0];

    NSLayoutManager *layoutManager = [self.textStorage.layoutManagers firstObject];
    NSTextContainer *textContainer = [layoutManager.textContainers firstObject];

    textContainer.size = CGSizeMake(CGRectGetWidth(rect), CGFLOAT_MAX);
    textContainer.lineBreakMode = self.lineBreakMode;

    NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];

    rect.origin.y = CGRectGetMidY(self.bounds) - rect.size.height/2;
    [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:rect.origin];

    if (self.linkRange.location != NSNotFound)
    {
        [layoutManager drawBackgroundForGlyphRange:self.linkRange atPoint:rect.origin];
    }
}

#pragma mark - Link Actions -

- (void)longPress:(UILongPressGestureRecognizer *)sender
{
    if ([sender state] == UIGestureRecognizerStateBegan)
    {
        CGPoint location = [sender locationInView:self];

        NSLayoutManager *layoutManager = [self.textStorage.layoutManagers firstObject];
        NSTextContainer *textContainer = [layoutManager.textContainers firstObject];

        NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:location inTextContainer:textContainer];
        NSUInteger characterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

        NSRange effectiveRange;
        NSDictionary *attributes = [self.textStorage attributesAtIndex:characterIndex
                                                        effectiveRange:&effectiveRange];

        self.linkRange = effectiveRange;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.75
                                                      target:self
                                                    selector:@selector(timerFired:)
                                                    userInfo:attributes
                                                     repeats:NO];
    }
    else if ([sender state] == UIGestureRecognizerStateChanged)
    {
        CGPoint location = [sender locationInView:self];

        NSLayoutManager *layoutManager = [self.textStorage.layoutManagers firstObject];
        NSTextContainer *textContainer = [layoutManager.textContainers firstObject];

        NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:self.linkRange actualCharacterRange:nil];
        CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];

        if (CGRectContainsPoint(rect, location) == NO)
        {
            [self.timer invalidate];

            self.linkRange = NSMakeRange(NSNotFound, 0);
        }
    }
    else if ([sender state] == UIGestureRecognizerStateEnded)
    {
        [self.timer invalidate];

        if (self.linkRange.location != NSNotFound)
        {
            [self shortPress:sender];

            self.linkRange = NSMakeRange(NSNotFound, 0);
        }
    }
}

- (void)shortPress:(UILongPressGestureRecognizer *)sender
{
    NSString *linkText = [self.text substringWithRange:self.linkRange];
    NSDictionary *attributes = [self.textStorage attributesAtIndex:self.linkRange.location
                                                    effectiveRange:NULL];

    [self.delegate label:self
          didTapLinkText:linkText
          withAttributes:attributes];
}

- (void)timerFired:(NSTimer *)timer
{
    NSString *linkText = [self.text substringWithRange:self.linkRange];
    NSDictionary *attributes = [timer userInfo];

    self.linkRange = NSMakeRange(NSNotFound, 0);

    [self.delegate label:self
    didLongPressLinkText:linkText
          withAttributes:attributes];
}

#pragma mark - UIGestureRecognizerDelegate -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([self.textStorage length] == 0)
    {
        return NO;
    }

    CGPoint location = [touch locationInView:self];

    NSLayoutManager *layoutManager = [self.textStorage.layoutManagers firstObject];
    NSTextContainer *textContainer = [layoutManager.textContainers firstObject];

    NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:location inTextContainer:textContainer];
    NSUInteger characterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

    NSRange effectiveRange;
    NSDictionary *attributes = [self.textStorage attributesAtIndex:characterIndex
                                                    effectiveRange:&effectiveRange];

    return (attributes[MFJLabelLinkAttributeName] || attributes[MFJLabelPhoneNumberAttributeName] || attributes[MFJLabelAddressAttributeName] || attributes[MFJLabelDateAttributeName]);
}

@end
