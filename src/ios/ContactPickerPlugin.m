#import "ContactPickerPlugin.h"
#import "libPhoneNumber-iOS/NBPhoneNumberUtil.h"

@implementation ContactPickerPlugin {
    CNContactPickerViewController* _contactPickerController;
    CNContactFormatter* _contactFormatter;
    NBPhoneNumberUtil* _phoneUtil;
}

- (void)pluginInitialize {
    _phoneUtil = [[NBPhoneNumberUtil alloc] init];
    _contactFormatter = [[CNContactFormatter alloc] init];
}

- (void)requestContact:(CDVInvokedUrlCommand *)command {
    if (_contactPickerController) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsString:@"Only single contact request is allowed"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    } else {
        _contactPickerController = [[CNContactPickerViewController alloc] init];
        _contactPickerController.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
        _contactPickerController.predicateForEnablingContact = [NSPredicate predicateWithFormat:@"phoneNumbers.@count >= 1"];
        _contactPickerController.delegate = self;

        [self.getTopPresentedViewController presentViewController:_contactPickerController animated:YES completion:nil];

        self.contactCallbackId = command.callbackId;

        NSDictionary* settings = [command.arguments objectAtIndex:0];
        self.lastCountry = settings[@"country"] ? settings[@"country"] : @"BY";
    }
}

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(nonnull CNContactProperty *)contactProperty {
    if (self.contactCallbackId) {
        NSString* displayName = [_contactFormatter stringFromContact:contactProperty.contact];
        NSString* phoneNumber = [contactProperty.value valueForKey:@"digits"];
        phoneNumber = [self getNormalizedPhoneNumber:phoneNumber];
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"displayName": displayName, @"phoneNumber": phoneNumber}];
        [self.commandDelegate sendPluginResult:result callbackId:self.contactCallbackId];
        self.contactCallbackId = nil;
    }

    _contactPickerController = nil;
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
    if (self.contactCallbackId) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:nil];
        [self.commandDelegate sendPluginResult:result callbackId:self.contactCallbackId];
        self.contactCallbackId = nil;
    }

    _contactPickerController = nil;
}

-(NSString *)getNormalizedPhoneNumber:(NSString*) phoneNumberString {
    NSError *err = nil;
    NBPhoneNumber *parsedNumber = [_phoneUtil parse:phoneNumberString
                                      defaultRegion:self.lastCountry error:&err];
    if (!err) {
        NSString *phoneNumberNormalized = [_phoneUtil format:parsedNumber
                                                numberFormat:NBEPhoneNumberFormatE164 error:&err];
        if (!err) {
            phoneNumberString = phoneNumberNormalized;
        }
    }

    return phoneNumberString;
}

-(UIViewController *)getTopPresentedViewController {
    UIViewController *presentingViewController = self.viewController;
    while(presentingViewController.presentedViewController != nil && ![presentingViewController.presentedViewController isBeingDismissed])
    {
        presentingViewController = presentingViewController.presentedViewController;
    }
    return presentingViewController;
}

@end
