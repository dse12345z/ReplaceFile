//
//  ViewController.m
//  ReplaceFile
//
//  Created by daisuke on 2015/12/7.
//  Copyright © 2015年 dse12345z. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak) IBOutlet NSPathControl *fromSourcePathControl;
@property (weak) IBOutlet NSPathControl *toSourcePathControl;

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
    return 100;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"tableViewCell" owner:self];
    result.textField.bezeled = NO;
    result.textField.drawsBackground = NO;
    result.textField.editable = NO;
    result.textField.lineBreakMode = NSLineBreakByWordWrapping;
    result.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    
    if (row == 0) {
        result.textField.stringValue = @"---------- newImages ----------";
        result.imageView.image = nil;
        result.layer.backgroundColor = [[NSColor grayColor] CGColor];
    }
    else if (row == self.freshImages.count + 1) {
        result.textField.stringValue = @"---------- oldImages ----------";
        result.imageView.image = nil;
        result.layer.backgroundColor = [[NSColor grayColor] CGColor];
    }
    
    if (row < self.freshImages.count + 1 && self.freshImages.count && row > 0) {
        NSString *path = self.freshImages[row - 1];
        NSImage *img = [[NSImage alloc] initWithContentsOfFile:path];
        result.imageView.image = img;
        result.textField.stringValue = path;
    }
    else if (self.oldImages.count && row > self.freshImages.count + 1) {
        NSString *path = self.oldImages[(row - 1) - (self.freshImages.count + 1)];
        NSImage *img = [[NSImage alloc] initWithContentsOfFile:path];
        result.imageView.image = img;
        result.textField.stringValue = path;
    }
    return result;
}

#pragma mark - NSTableView Notifications

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableview = notification.object;
    NSString *path = nil;
    if (tableview.selectedRow < self.freshImages.count + 1 && self.freshImages.count && tableview.selectedRow > 0) {
        path = self.freshImages[tableview.selectedRow - 1];
    }
    else if (self.oldImages.count && tableview.selectedRow > self.freshImages.count + 1) {
        path = self.oldImages[(tableview.selectedRow - 1) - (self.freshImages.count + 1)];
    }
    
    if (path) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"取消"];
        [alert addButtonWithTitle:@"確定"];
        [alert setMessageText:@"是否要開啟這個檔案的資料夾"];
        [alert setInformativeText:@"系統訊息"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[self.view window] completionHandler: ^(NSInteger result) {
            BOOL isCopy = result - 1000;
            if (isCopy) {
                [[path stringByDeletingLastPathComponent] openFolder];
            }
        }];
    }
}

#pragma mark - IBAction

- (IBAction)selectOldPathButtonAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self openFolderCompletion: ^(NSURL *url) {
        weakSelf.toSourcePathControl.URL = url;
    }];
}

- (IBAction)selectNewPathButtonAction:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self openFolderCompletion: ^(NSURL *url) {
        weakSelf.fromSourcePathControl.URL = url;
    }];
}

- (IBAction)replaceButtonAction:(id)sender {
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
    self.freshImages = [self folderImages:self.fromSourcePathControl.URL.path];
    self.oldImages = [self folderImages:self.toSourcePathControl.URL.path];
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

- (void)openFolderCompletion:(void (^)(NSURL *url))completion {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    [panel beginSheetModalForWindow:self.view.window completionHandler: ^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = panel.URLs[0];
            completion(url);
        }
    }];
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupInitValues];
}

@end