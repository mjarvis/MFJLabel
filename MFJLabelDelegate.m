//
//  MFJLabelDelegate.m
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

#import "MFJLabelDelegate.h"

@interface MFJLabelDelegateActionSheet : UIActionSheet <UIActionSheetDelegate>

@property (nonatomic, strong) NSMutableDictionary *actions;

- (void)addButtonWithTitle:(NSString *)title action:(void(^)())block;

@end

#pragma mark -

@implementation MFJLabelDelegate

- (void)label:(MFJLabel *)label didTapLinkText:(NSString *)linkText withAttributes:(NSDictionary *)attributes
{
    if (attributes[MFJLabelLinkAttributeName])
    {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:attributes[MFJLabelLinkAttributeName]
                                                   resolvingAgainstBaseURL:YES];
        if ([components.scheme isEqualToString:@"mailto"])
        {
            MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
            {
                controller.mailComposeDelegate = self;
                [controller setToRecipients:@[components.path]];
            }
            [label.window.rootViewController presentViewController:controller
                                                          animated:YES
                                                        completion:NULL];
        }
        else
        {
            [[UIApplication sharedApplication] openURL:attributes[MFJLabelLinkAttributeName]];
        }
    }
    else if (attributes[MFJLabelPhoneNumberAttributeName])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:attributes[MFJLabelPhoneNumberAttributeName]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"Call", nil), nil];
        [alertView show];
    }
    else if (attributes[MFJLabelAddressAttributeName])
    {
        NSURLComponents *components = [[NSURLComponents alloc] initWithString:@"http://maps.apple.com/"];
        {
            components.query = [[NSString alloc] initWithFormat:@"q=%@", linkText];
        }
        [[UIApplication sharedApplication] openURL:[components URL]];
    }
    else if (attributes[MFJLabelDateAttributeName])
    {
        [self label:label didLongPressLinkText:linkText withAttributes:attributes];
    }
}

- (void)label:(MFJLabel *)label didLongPressLinkText:(NSString *)linkText withAttributes:(NSDictionary *)attributes
{
    MFJLabelDelegateActionSheet *actionSheet = [[MFJLabelDelegateActionSheet alloc] init];
    {
        if (attributes[MFJLabelLinkAttributeName])
        {
            NSURLComponents *components = [[NSURLComponents alloc] initWithURL:attributes[MFJLabelLinkAttributeName]
                                                       resolvingAgainstBaseURL:YES];
            if ([components.scheme isEqualToString:@"mailto"])
            {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"New Message", nil)
                                         action:^{
                                             MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
                                             {
                                                 controller.mailComposeDelegate = self;
                                                 [controller setToRecipients:@[components.path]];
                                             }
                                             [label.window.rootViewController presentViewController:controller
                                                                                           animated:YES
                                                                                         completion:NULL];
                                         }];
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Add to Contacts", nil)
                                         action:^{

                                             ABUnknownPersonViewController *controller = [[ABUnknownPersonViewController alloc] init];
                                             {
                                                 ABRecordRef person = ABPersonCreate();
                                                 {
                                                     ABMutableMultiValueRef email = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                                                     {
                                                         ABMultiValueAddValueAndLabel(email, (__bridge CFTypeRef)(components.path), NULL, NULL);
                                                     }
                                                     ABRecordSetValue(person, kABPersonEmailProperty, email, NULL);
                                                     CFRelease(email);
                                                 }
                                                 controller.displayedPerson = person;
                                                 CFRelease(person);

                                                 controller.unknownPersonViewDelegate = self;
                                                 controller.allowsAddingToAddressBook = YES;
                                                 controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                                                                                 style:UIBarButtonItemStylePlain
                                                                                                                                target:self
                                                                                                                                action:@selector(unknownPersonViewControllerShouldCancel:)];
                                             }
                                             [label.window.rootViewController presentViewController:[[UINavigationController alloc] initWithRootViewController:controller]
                                                                                           animated:YES
                                                                                         completion:NULL];
                                         }];
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy", nil)
                                         action:^{

                                             [UIPasteboard generalPasteboard].string = linkText;
                                         }];
            }
            else
            {
                NSURL *URL = attributes[MFJLabelLinkAttributeName];

                [actionSheet addButtonWithTitle:NSLocalizedString(@"Open", nil)
                                         action:^{

                                             [[UIApplication sharedApplication] openURL:URL];
                                         }];
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Add to Reading List", nil)
                                         action:^{

                                             SSReadingList *readingList = [SSReadingList defaultReadingList];

                                             [readingList addReadingListItemWithURL:URL
                                                                              title:nil
                                                                        previewText:nil
                                                                              error:NULL];
                                         }];
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy", nil)
                                         action:^{

                                             [UIPasteboard generalPasteboard].URL = URL;
                                         }];
            }
        }
        else if (attributes[MFJLabelPhoneNumberAttributeName])
        {
            NSString *phoneNumber = attributes[MFJLabelPhoneNumberAttributeName];

            // - Call <person from address book>
            NSString *format = NSLocalizedString(@"Call %@", nil);
            NSString *call = [[NSString alloc] initWithFormat:format, phoneNumber];

            [actionSheet addButtonWithTitle:call
                                     action:^{

                                         NSURLComponents *components = [[NSURLComponents alloc] init];
                                         {
                                             components.scheme = @"tel";
                                             components.host = phoneNumber;
                                         }
                                         [[UIApplication sharedApplication] openURL:[components URL]];
                                     }];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Send Message", nil)
                                     action:^{

                                         NSURLComponents *components = [[NSURLComponents alloc] init];
                                         {
                                             components.scheme = @"sms";
                                             components.host = phoneNumber;
                                         }
                                         [[UIApplication sharedApplication] openURL:[components URL]];
                                     }];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add to Contacts", nil)
                                     action:^{

                                         ABUnknownPersonViewController *controller = [[ABUnknownPersonViewController alloc] init];
                                         {
                                             ABRecordRef person = ABPersonCreate();
                                             {
                                                 ABMutableMultiValueRef phone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                                                 {
                                                     ABMultiValueAddValueAndLabel(phone, (__bridge CFTypeRef)(phoneNumber), NULL, NULL);
                                                 }
                                                 ABRecordSetValue(person, kABPersonPhoneProperty, phone, NULL);

                                                 CFRelease(phone);
                                             }
                                             controller.displayedPerson = person;
                                             CFRelease(person);

                                             controller.unknownPersonViewDelegate = self;
                                             controller.allowsAddingToAddressBook = YES;
                                             controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                                                                             style:UIBarButtonItemStylePlain
                                                                                                                            target:self
                                                                                                                            action:@selector(unknownPersonViewControllerShouldCancel:)];
                                         }
                                         [label.window.rootViewController presentViewController:[[UINavigationController alloc] initWithRootViewController:controller]
                                                                                       animated:YES
                                                                                     completion:NULL];
                                     }];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy", nil)
                                     action:^{

                                         [UIPasteboard generalPasteboard].string = linkText;
                                     }];
        }
        else if (attributes[MFJLabelAddressAttributeName])
        {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Maps", nil)
                                     action:^{

                                         NSURLComponents *components = [[NSURLComponents alloc] initWithString:@"http://maps.apple.com/"];
                                         {
                                             components.query = [[NSString alloc] initWithFormat:@"q=%@", linkText];
                                         }
                                         [[UIApplication sharedApplication] openURL:[components URL]];
                                     }];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add to Contacts", nil)
                                     action:^{

                                         NSDictionary *addressDictionary = attributes[MFJLabelAddressAttributeName];

                                         ABUnknownPersonViewController *controller = [[ABUnknownPersonViewController alloc] init];
                                         {
                                             ABRecordRef person = ABPersonCreate();
                                             {
                                                 if (addressDictionary[NSTextCheckingJobTitleKey])
                                                     ABRecordSetValue(person, kABPersonJobTitleProperty, (__bridge CFTypeRef)(addressDictionary[NSTextCheckingJobTitleKey]), NULL);

                                                 if (addressDictionary[NSTextCheckingOrganizationKey])
                                                     ABRecordSetValue(person, kABPersonOrganizationProperty, (__bridge CFTypeRef)(addressDictionary[NSTextCheckingOrganizationKey]), NULL);

                                                 if (addressDictionary[NSTextCheckingNameKey])
                                                     ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)(addressDictionary[NSTextCheckingNameKey]), NULL);

                                                 ABMutableMultiValueRef addresses = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
                                                 {
                                                     CFMutableDictionaryRef address = CFDictionaryCreateMutable(NULL, 6, NULL, NULL);
                                                     {
                                                         if (addressDictionary[NSTextCheckingCityKey])
                                                             CFDictionarySetValue(address, kABPersonAddressCityKey, (__bridge const void *)(addressDictionary[NSTextCheckingCityKey]));

                                                         if (addressDictionary[NSTextCheckingCountryKey])
                                                             CFDictionarySetValue(address, kABPersonAddressCountryKey, (__bridge const void *)(addressDictionary[NSTextCheckingCountryKey]));

                                                         if (addressDictionary[NSTextCheckingStreetKey])
                                                             CFDictionarySetValue(address, kABPersonAddressStreetKey, (__bridge const void *)(addressDictionary[NSTextCheckingStreetKey]));

                                                         if (addressDictionary[NSTextCheckingStateKey])
                                                             CFDictionarySetValue(address, kABPersonAddressStateKey, (__bridge const void *)(addressDictionary[NSTextCheckingStateKey]));

                                                         if (addressDictionary[NSTextCheckingZIPKey])
                                                             CFDictionarySetValue(address, kABPersonAddressZIPKey, (__bridge const void *)(addressDictionary[NSTextCheckingZIPKey]));

                                                     }
                                                     ABMultiValueAddValueAndLabel(addresses, address, NULL, NULL);
                                                     CFRelease(address);
                                                 }
                                                 ABRecordSetValue(person, kABPersonAddressProperty, addresses, NULL);

                                                 CFRelease(addresses);
                                             }
                                             controller.displayedPerson = person;
                                             CFRelease(person);

                                             controller.unknownPersonViewDelegate = self;
                                             controller.allowsAddingToAddressBook = YES;
                                             controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                                                                             style:UIBarButtonItemStylePlain
                                                                                                                            target:self
                                                                                                                            action:@selector(unknownPersonViewControllerShouldCancel:)];
                                         }
                                         [label.window.rootViewController presentViewController:[[UINavigationController alloc] initWithRootViewController:controller]
                                                                                       animated:YES
                                                                                     completion:NULL];
                                     }];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy", nil)
                                     action:^{

                                         [UIPasteboard generalPasteboard].string = linkText;
                                     }];
        }
        else if (attributes[MFJLabelDateAttributeName])
        {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Create Event", nil)
                                     action:^{

                                         EKEventEditViewController *controller = [[EKEventEditViewController alloc] init];
                                         {
                                             controller.editViewDelegate = self;
                                         }
                                         [label.window.rootViewController presentViewController:controller
                                                                                       animated:YES
                                                                                     completion:NULL];
                                     }];
//            // "calshow" is an undocumented scheme. We don't know how to specify a date.
//            [actionSheet addButtonWithTitle:NSLocalizedString(@"Show in Calendar", nil)
//                                     action:^{
//
//                                         NSURLComponents *components = [[NSURLComponents alloc] init];
//                                         {
//                                             components.scheme = @"calshow";
//                                         }
//                                         [[UIApplication sharedApplication] openURL:[components URL]];
//                                     }];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Copy", nil)
                                     action:^{

                                         [UIPasteboard generalPasteboard].string = linkText;
                                     }];
        }

        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];

        actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
    }
    [actionSheet showFromRect:label.frame
                       inView:label.superview
                     animated:YES];
}

#pragma mark - Alerts & Modals

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        return;
    }

    NSURLComponents *components = [[NSURLComponents alloc] init];
    {
        components.scheme = @"tel";
        components.host = alertView.message;
    }
    [[UIApplication sharedApplication] openURL:[components URL]];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES
                                   completion:NULL];
}

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    [controller dismissViewControllerAnimated:YES
                                   completion:NULL];
}

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownCardViewController didResolveToPerson:(ABRecordRef)person
{
    // This will prompt a warning in console, but visually does the right animation.
    [unknownCardViewController.presentingViewController dismissViewControllerAnimated:YES
                                                                           completion:NULL];
}

- (void)unknownPersonViewControllerShouldCancel:(UIBarButtonItem *)sender
{
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES
                                                                                       completion:NULL];
}

@end

#pragma mark -

@implementation MFJLabelDelegateActionSheet

- (void)addButtonWithTitle:(NSString *)title
                    action:(void(^)())block
{
    [self addButtonWithTitle:title];

    self.actions[title] = block;
}

- (NSMutableDictionary *)actions
{
    if (_actions == nil)
    {
        _actions = [[NSMutableDictionary alloc] init];
    }
    return _actions;
}

- (void)showFromRect:(CGRect)rect
              inView:(UIView *)view
            animated:(BOOL)animated
{
    self.delegate = self;

    [super showFromRect:rect
                 inView:view
               animated:animated];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        return;
    }

    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];

    void(^action)() = self.actions[title];

    action();
}

@end
