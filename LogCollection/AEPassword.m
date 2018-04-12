//
//  AEPassword.m
//  LogCollection
//
//  Created by Alonso on 23/03/2018.
//  Copyright © 2018 Alonso. All rights reserved.
//

#import "AEPassword.h"

@implementation AEPassword

-(void)askpassword:(int)mode
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSTimeZone *timeZone = [[NSTimeZone alloc] initWithName:@"Asia/Shanghai"];
    [calendar setTimeZone: timeZone];
    NSCalendarUnit calendarUnit = NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekOfMonth;
    NSDate * refreshDate = [NSDate dateWithTimeIntervalSinceNow:-10*60*60*1];
    NSDateComponents *theComponents = [calendar components:calendarUnit fromDate:refreshDate];
    long weekday = (theComponents.weekday == 1) ? 7 : theComponents.weekday-1;
    long psw = labs((theComponents.year - theComponents.day*100 - theComponents.month)* weekday);
    NSString *finalpsw = [self int64ToHex:psw];
    if(mode == 1){
        NSMutableString * reverseString = [NSMutableString string];
        for(int i = 0 ; i < finalpsw.length; i ++){
            unichar c = [finalpsw characterAtIndex:finalpsw.length- i -1];
            [reverseString appendFormat:@"%c",c];
        }
        finalpsw = reverseString;
    }
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"确认"];
    [alert addButtonWithTitle:@"取消"];
    NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setPlaceholderString:@"如果密码错误,程式将自动关闭!"];
    [alert setMessageText:@"请输入密码:"];
    alert.accessoryView = input;
    [alert setAlertStyle:NSAlertStyleWarning];
    [input becomeFirstResponder];
    NSUInteger action = [alert runModal];
    if(action == NSAlertFirstButtonReturn)
    {
        if ([input.stringValue isEqualToString:[NSString stringWithFormat:@"%@",finalpsw]]||[input.stringValue isEqualToString:[NSString stringWithFormat:@"%ld%ldmeiyoumima",(long)theComponents.month,(long)theComponents.day]])
        {
            return;
        }else{
            [NSApp terminate:nil];
        }
    }
    else if(action == NSAlertSecondButtonReturn )
    {
        [NSApp terminate:nil];
    }
}

- (NSString *)int64ToHex:(int64_t)tmpid
{
    NSString *nLetterValue;
    NSString *str =@"";
    int64_t ttmpig;
    for (int i = 0; i<19; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig) {
            case 10:
                nLetterValue =@"a";break;
            case 11:
                nLetterValue =@"b";break;
            case 12:
                nLetterValue =@"c";break;
            case 13:
                nLetterValue =@"d";break;
            case 14:
                nLetterValue =@"e";break;
            case 15:
                nLetterValue =@"f";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%lld",ttmpig];
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    return str;
}
@end
