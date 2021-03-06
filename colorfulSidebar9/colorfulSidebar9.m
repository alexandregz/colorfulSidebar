//
//  colorfulSidebar9.m
//  colorfulSidebar9
//
//  Created by Wolfgang Baird
//  Copyright 2016 - 2017 Wolfgang Baird.
//

@import AppKit;
#import "ZKSwizzle.h"

static const char * const activeKey = "wwb_isactive";
static dispatch_once_t ONCE_FI_TSidebarItemCell;
NSInteger macOS;

@interface colorfulSidebar9 : NSObject
@end

static NSDictionary *cfsbIconMappingDict = nil;

struct TFENode {
    struct OpaqueNodeRef *fNodeRef;
};

@interface wb_TImageView : NSImageView
@end

@interface wb_TSidebarItemCell : NSObject
@end

@interface wb_NSImageView : NSControl
@end

@implementation wb_NSImageView

- (void)_setImageView:(id)arg1 {
    if ([[self class] isEqualTo:NSClassFromString(@"FI_TImageView")]) {
        NSObject *aSuper = [self superview];
        if ([[aSuper className] isEqualToString:@"FI_TSidebarItemCell"]) {
            dispatch_once(&ONCE_FI_TSidebarItemCell, ^ { ZKSwizzle(wb_TSidebarItemCell, FI_TSidebarItemCell); });
            SEL setIMG = NSSelectorFromString(@"wb_setImage:");
            if (macOS < 11) {
                [aSuper performSelector:setIMG withObject:aSuper];
            } else {
                SEL aSEL = @selector(subviews);
                if ([aSuper respondsToSelector:aSEL])
                    for (id i in [aSuper performSelector:aSEL])
                        if ([i class] == NSClassFromString(@"TImageView") || [i class] == NSClassFromString(@"FI_TImageView") )
                            [aSuper performSelector:setIMG withObject:i];
            }
        }
    }
    ZKOrig(void, arg1);
}

@end

@implementation wb_TSidebarItemCell

- (void)wb_setImage:(id)itemCell {
    SEL aSEL = @selector(accessibilityAttributeNames);
    if ([self respondsToSelector:aSEL] && [[self performSelector:aSEL] containsObject:NSAccessibilityURLAttribute]) {
        NSURL *aURL = [self accessibilityAttributeValue:NSAccessibilityURLAttribute];
        NSImage *image = nil;
        if ([aURL isFileURL]) {
            NSString *path = [aURL path];
            image = cfsbIconMappingDict[path];
            if (!image) {
                aSEL = @selector(name);
                if ([self respondsToSelector:aSEL]) {
                    image = cfsbIconMappingDict[[self performSelector:aSEL]];
                }
            }
            if (!image) {
                image = [[NSWorkspace sharedWorkspace] iconForFile:path];
            }
        } else {
            image = cfsbIconMappingDict[[aURL absoluteString]];
        }
        if (!image) {
            aSEL = @selector(name);
            if ([self respondsToSelector:aSEL]) {
                NSString* s = [self performSelector:aSEL];
                image = cfsbIconMappingDict[s];
                if ([s isEqualToString:@"iCloud Drive"])
                    image = cfsbIconMappingDict[@"x-applefinder-vnode:iCloud"];
            }
        }
        if (!image) {
            aSEL = @selector(image);
            if ([itemCell respondsToSelector:aSEL]) {
                NSImage *sidebarImage = [itemCell performSelector:aSEL];
                aSEL = NSSelectorFromString(@"sourceImage");
                if ([sidebarImage respondsToSelector:aSEL]) {
                    sidebarImage = [sidebarImage performSelector:aSEL];
                }
                if ([sidebarImage name]) {
                    image = cfsbIconMappingDict[[sidebarImage name]];
                }
                // Tags
                if (!image) {
                    if ([[sidebarImage representations] count] == 1) {
                        image = [itemCell performSelector:@selector(image)];
                    }
                }
            }
        }
        if (!image) {
            Class cls = NSClassFromString(@"FINode");
            if (cls) {
                struct TFENode *node = &ZKHookIvar(self, struct TFENode, "_node");
                SEL nodeFromNode = NSSelectorFromString(@"nodeFromNodeRef:");
                id finode = [cls performSelector:nodeFromNode withObject:(id)node->fNodeRef];
                SEL createAlt = NSSelectorFromString(@"createAlternativeIconRepresentationWithOptions:");
                if ([finode respondsToSelector:createAlt]) {
                    IconRef iconRef = (IconRef)[finode performSelector:createAlt withObject:nil];
                    image = [[[NSImage alloc] initWithIconRef:iconRef] autorelease];
                    ReleaseIconRef(iconRef);
                }
            }
        }
        if (image)
            [itemCell setImage:image];
    }
}

// 10.9 & 10.10
- (void)drawWithFrame:(struct CGRect)arg1 inView:(id)arg2 {
    [self wb_setImage:self];
    ZKOrig(void, arg1, arg2);
}

// 10.11 +
- (_Bool)isHighlighted {
    SEL aSEL = @selector(subviews);
    if ([self respondsToSelector:aSEL])
        for (id i in [self performSelector:aSEL])
            if ([i class] == NSClassFromString(@"TImageView") || [i class] == NSClassFromString(@"FI_TImageView") )
                [self wb_setImage:i];
    return ZKOrig(_Bool);
}

@end

@implementation wb_TImageView

- (void)wb_forceUpdate {
    NSNumber *hasBumped = objc_getAssociatedObject(self, activeKey);
    if (hasBumped == nil) {
        double delayInSeconds = 0.15;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            SEL se = @selector(isHighlighted);
            if ([[self superview] respondsToSelector:se])
                [[self superview] performSelector:se];
            [[self superview] updateLayer];
            NSNumber *hasBumped = [NSNumber numberWithBool:true];
            objc_setAssociatedObject(self, activeKey, hasBumped, OBJC_ASSOCIATION_RETAIN);
        });
    }
}

- (void)_updateImageView {
//    NSLog(@"wb_ %s", __PRETTY_FUNCTION__);
    [self wb_forceUpdate];
    ZKOrig(void);
}

- (void)updateLayer {
//    NSLog(@"wb_ %s", __PRETTY_FUNCTION__);
    [self wb_forceUpdate];
    ZKOrig(void);
}

- (void)layout {
//    NSLog(@"wb_ %s", __PRETTY_FUNCTION__);
    [self wb_forceUpdate];
    ZKOrig(void);
}

@end

@implementation colorfulSidebar9

+ (void)load {
    macOS = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    if (macOS < 9)
        return;
    
    if (!cfsbIconMappingDict) {
        NSLog(@"wb_ Loading colorfulSidebar...");
        [self performSelector:@selector(setUpIconMappingDict)];
        ZKSwizzle(wb_NSImageView, NSImageView);
        if (NSClassFromString(@"TSidebarItemCell")) ZKSwizzle(wb_TSidebarItemCell, TSidebarItemCell);
        if (NSClassFromString(@"FI_TSidebarItemCell")) dispatch_once(&ONCE_FI_TSidebarItemCell, ^ { ZKSwizzle(wb_TSidebarItemCell, FI_TSidebarItemCell); });
        if (NSClassFromString(@"TImageView")) ZKSwizzle(wb_TImageView, TImageView);
        if (NSClassFromString(@"FI_TImageView")) ZKSwizzle(wb_TImageView, FI_TImageView);
        NSLog(@"%@ loaded into %@ on macOS 10.%ld", [self class], [[NSBundle mainBundle] bundleIdentifier], macOS);
    }
    
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.finder"]) {
        NSMenu *go = [[[NSApp mainMenu] itemAtIndex:4] submenu];
        for (NSMenuItem *i in [go itemArray]) {
            NSImage *image = nil;
            NSString *action = NSStringFromSelector([i action]);
            if ([action isEqualToString:@"cmdGoToAllMyFiles:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AllMyFiles.icns"];
            if ([action isEqualToString:@"cmdGoToDocuments:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/Applications/iBooks.app/Contents/Resources/iBooksAppIcon.icns"];
            if ([action isEqualToString:@"cmdGoToDesktop:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/PreferencePanes/Displays.prefPane/Contents/Resources/Displays.icns"];
            if ([action isEqualToString:@"cmdGoToDownloads:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/Installer.app/Contents/Resources/Installer.icns"];
            if ([action isEqualToString:@"cmdGoHome:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/HomeFolderIcon.icns"];
            if ([action isEqualToString:@"cmdGoToUserLibrary:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/Siri.app/Contents/Resources/AppIcon.icns"];
            if ([action isEqualToString:@"cmdGoToComputer:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macpro.icns"];
            if ([action isEqualToString:@"cmdGoToMeetingRoom:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AirDrop.icns"];
            if ([action isEqualToString:@"cmdGoToNetwork:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericNetworkIcon.icns"];
            if ([action isEqualToString:@"cmdGoToICloud:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/iDiskGenericIcon.icns"];
            if ([action isEqualToString:@"cmdGoToApplications:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/Applications/App Store.app/Contents/Resources/AppIcon.icns"];
            if ([action isEqualToString:@"cmdGoToUtilities:"]) image = [[NSImage alloc] initWithContentsOfFile:@"/Applications/Utilities/ColorSync Utility.app/Contents/Resources/ColorSyncUtility.icns"];
            if (image) {
                [image setSize:NSMakeSize(16, 16)];
                [i setImage:image];
            }
        }
    }
}

+ (void)setUpIconMappingDict {
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"icons" ofType:@"plist"];
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion >= 10)
        path = [[NSBundle bundleForClass:self] pathForResource:@"icons10" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) {
        cfsbIconMappingDict = [NSDictionary new];
    } else {
        NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithCapacity:0];
        for (NSString *key in dict) {
            NSImage *image;
            if ([key isAbsolutePath]) {
                image = [[[NSImage alloc] initWithContentsOfFile:key] autorelease];
            } else if ([key length] == 4) {
                OSType code = UTGetOSTypeFromString((CFStringRef)CFBridgingRetain(key));
                image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(code)];
            } else {
                image = [NSImage imageNamed:key];
                if (image && [key rangeOfString:@"NSMediaBrowserMediaType"].length) {
                    image = [[image copy] autorelease];
                    NSSize size = NSMakeSize(32, 32);
                    [image setSize:size];
                    [[[image representations] lastObject] setSize:size];
                }
            }
            if (image) {
                NSArray *arr = dict[key];
                for (key in arr) {
                    if ([key hasPrefix:@"~"]) {
                        key = [key stringByExpandingTildeInPath];
                    }
                    mdict[key] = image;
                }
            }
        }
        cfsbIconMappingDict = [mdict copy];
    }
}

@end
