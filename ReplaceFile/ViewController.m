//
//  ViewController.m
//  ReplaceFile
//
//  Created by daisuke on 2015/12/7.
//  Copyright © 2015年 dse12345z. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak) IBOutlet NSTextField *oldFolderTextField;
@property (weak) IBOutlet NSTextField *folderTextField;
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) NSMutableArray *freshImages;
@property (strong) NSMutableArray *oldImages;

@end

@implementation ViewController

#pragma mark - NSTableView delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSInteger freshCount = self.freshImages.count ? self.freshImages.count + 1 : 0;
    NSInteger oldCount = self.oldImages.count ? self.oldImages.count + 1 : 0;
    return freshCount + oldCount;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 30;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    
    NSTextField *result = [tableView makeViewWithIdentifier:@"tableView" owner:self];
    if (result == nil) {
        result = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, 30)];
        result.bezeled = NO;
        result.drawsBackground = NO;
        result.editable = NO;
    }
    if (row == 0) {
        result.stringValue = @"---------- newImages ----------";
    }
    else if (row == self.freshImages.count + 1) {
        result.stringValue = @"---------- oldImages ----------";
    }
    
    if (row < self.freshImages.count + 1 && self.freshImages.count && row > 0) {
        result.stringValue = self.freshImages[row - 1];
    }
    else if (self.oldImages.count && row > self.freshImages.count + 1) {
        result.stringValue = self.oldImages[(row - 1) - (self.freshImages.count + 1)];
    }
    return result;
}

#pragma mark - IBAction

- (IBAction)selectOldPathButtonAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self openFolderCompletion: ^(NSString *path) {
        [weakSelf.oldFolderTextField setStringValue:path];
    }];
}

- (IBAction)selectNewPathButtonAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self openFolderCompletion: ^(NSString *path) {
        [weakSelf.folderTextField setStringValue:path];
    }];
}

- (IBAction)replaceButtonAction:(id)sender {
    //    NSLog(@"\n");
    //    NSLog(@"----- Start -----");
    [self replaceImages];
}

#pragma mark - private instance method

#pragma mark * init

- (void)setupInitValues {
    self.freshImages = [NSMutableArray new];
    self.oldImages = [NSMutableArray new];
}

#pragma mark * misc

- (void)replaceImages {
    [self.freshImages removeAllObjects];
    [self.oldImages removeAllObjects];
    self.freshImages = [self folderImages:[self.folderTextField stringValue]];
    self.oldImages = [self folderImages:[self.oldFolderTextField stringValue]];
    NSMutableArray *newReplaced = [NSMutableArray new];
    NSMutableArray *folderAdded = [NSMutableArray new];
    
    for (int index = 0; index < self.freshImages.count; index++) {
        NSString *newPath = self.freshImages[index];
        for (int index2 = 0; index2 < self.oldImages.count; index2++) {
            NSString *oldPath = self.oldImages[index2];
            if ([newPath.lastPathComponent isEqualToString:oldPath.lastPathComponent]) {
                [folderAdded addObject:oldPath];
                [newReplaced addObject:newPath];
                [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
                [[NSFileManager defaultManager] copyItemAtPath:newPath toPath:oldPath error:nil];
            }
        }
    }
    
    [self.oldImages removeObjectsInArray:folderAdded];
    [self.freshImages removeObjectsInArray:newReplaced];
    [self.tableView reloadData];
    //        if (self.freshImages.count) {
    //            NSLog(@"newImages :%@", self.freshImages);
    //        }
    //        if (self.oldImages.count) {
    //            NSLog(@"oldImages :%@", self.oldImages);
    //        }
    //        NSLog(@"----- End -----");
}

- (NSMutableArray *)folderImages:(NSString *)path {
    NSArray *newDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSMutableArray *images = [NSMutableArray new];
    
    for (NSString *file in newDirectoryContents) {
        NSString *newImgFilePath = [path stringByAppendingPathComponent:file];
        if ([file hasSuffix:@".png"]) {
            [images addObject:newImgFilePath];
        }
        else if (![file hasSuffix:@"."]) {
            [images addObjectsFromArray:[self folderImages:[path stringByAppendingPathComponent:file]]];
        }
    }
    return images;
}

- (void)openFolderCompletion:(void (^)(NSString *path))completion {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    [panel beginSheetModalForWindow:self.view.window completionHandler: ^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = panel.URLs[0];
            NSString *path = [[url absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            completion(path);
        }
    }];
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupInitValues];
}

@end