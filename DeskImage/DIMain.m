//
//  DIMain.m
//  DeskImage
//
//  Created by Wingston Sharon on 03/07/13.
//  Copyright (c) 2013 Wingston Sharon. All rights reserved.
//

#import "DIMain.h"

@implementation DIMain

+ (NSData *) ProcessImage:(NSString *)filePath{
    NSImage *tempImage = [[NSImage alloc] initWithContentsOfFile:filePath];
    [tempImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
    
    NSRect myRect = NSMakeRect(0,420, tempImage.size.width, 220);
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBFillColor (context, 0.23,0.23,0.23, .4);
    CGContextFillRect (context, CGRectMake (myRect.origin.x, myRect.origin.y, myRect.size.width,myRect.size.height));
    [tempImage unlockFocus];
    return [DIMain PNGRepresentationOfImage:tempImage];
}

+ (NSData *) PNGRepresentationOfImage:(NSImage *) image {
    // Create a bitmap representation from the current image
    
    [image lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [image unlockFocus];
    
    return [bitmapRep representationUsingType:NSPNGFileType properties:Nil];
}

+ (NSImage*) desktopAsImage {
    // Can not use old "NSWorspace desktopImageURLForScreen + NSImage initWithContents" trick
    // because app is sandboxed and has no access to FS. WD-rpw 04-21-2012
//    
//    NSURL* desktopImageFile = [[NSWorkspace sharedWorkspace] desktopImageURLForScreen: [NSScreen mainScreen]];
//    return [[NSImage alloc] initWithContentsOfURL: desktopImageFile];
    
    CFMutableArrayRef windowIDs = CFArrayCreateMutable(NULL, 0, NULL);
    CFArrayRef allWindowIDs = CGWindowListCreate(kCGWindowListOptionOnScreenBelowWindow, kCGDesktopIconWindowLevel);
    
    if (allWindowIDs)
    {
        
        
        CFArrayRef windowDescs = CGWindowListCreateDescriptionFromArray(allWindowIDs);
        for (CFIndex idx=0; idx<CFArrayGetCount(windowDescs); idx++)
        {
            CFDictionaryRef dict = CFArrayGetValueAtIndex(windowDescs, idx);
            CFStringRef ownerName = CFDictionaryGetValue(dict, kCGWindowOwnerName);
            //            NSLog(@"owner name = %@", ownerName);
            if (CFStringCompare(ownerName, CFSTR("Dock"), 0) == kCFCompareEqualTo)
            {
                // the Dock level has the dock and the desktop picture
                CGRect windowBounds;
                CGRectMakeWithDictionaryRepresentation(
                                                                      (CFDictionaryRef)(CFDictionaryGetValue(dict, kCGWindowBounds)),
                                                                      &windowBounds);
                
                NSRect screenBounds = [NSScreen mainScreen].frame;
                CFNumberRef windowLayer = CFDictionaryGetValue(dict, kCGWindowLayer);
                
                //CFDictionaryGetValue(dict, kCGWindowBounds)
                //                NSLog(@"window bounds %f, %f, matches screen bounds? %d, on level %@",
                //                      windowBounds.size.width,
                //                      windowBounds.size.height,
                //                      CGRectEqualToRect(windowBounds, screenBounds),
                //                      windowLayer
                //                      );
                
                NSNumber* ourDesiredLevelNumber = [NSNumber numberWithInt: kCGDesktopWindowLevel - 1];  // Desktop Window level must mean "icons" ??? WD-rpw 04-22-2012
                if ( CGRectEqualToRect(windowBounds, screenBounds) && [ourDesiredLevelNumber isEqualToNumber: (__bridge NSNumber *)(windowLayer)] )
                    CFArrayAppendValue(windowIDs, CFArrayGetValueAtIndex(allWindowIDs, idx));
            }
            
        }
        CFRelease(windowDescs);
        CFRelease(allWindowIDs);
    }
    
    CGImageRef cgImage = CGWindowListCreateImageFromArray( [NSScreen mainScreen].frame, windowIDs, kCGWindowImageDefault);
    
    // Create a bitmap rep from the image...
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    // Create an NSImage and add the bitmap rep to it...
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    //[bitmapRep release];
    
    return image;
}

+ (void) test{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"In another class!"];
    [alert runModal];
}

@end
