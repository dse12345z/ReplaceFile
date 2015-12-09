//
//  NSString+NSString_ReplaceFile.m
//  ReplaceFile
//
//  Created by daisuke on 2015/12/9.
//  Copyright © 2015年 dse12345z. All rights reserved.
//

#import "NSString+NSString_ReplaceFile.h"

@implementation NSString (NSString_ReplaceFile)

- (void)openFolder {
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithUniqueName];
    [pasteboard setString:self forType:NSStringPboardType];
    NSPerformService(@"Finder/Open", pasteboard);
}

- (void)copyString {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:@[self]];
}

@end
