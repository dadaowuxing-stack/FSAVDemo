//
//  FSViewController.m
//  FSAVDemo
//
//  Created by fengshuo liu on 2022/5/27.
//

#import "FSViewController.h"
#import <Masonry/Masonry.h>>

@interface FSSectionItem<ObjectType> : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray *items;

- (instancetype)initWithTitle:(nullable id)title items:(nullable NSArray<ObjectType> *)items;

@end

@implementation FSSectionItem

- (instancetype)initWithTitle:(nullable id)title items:(nullable NSArray *)items {
    self = [super init];
    if (self) {
        self.title = title;
        self.items = items;
    }
    return self;;
}

@end

@interface FSItem : NSObject

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle path:(NSString *)path;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *subTitle;
@property (nonatomic, strong, readonly) NSString *path;

@end

@implementation FSItem

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle path:(NSString *)path {
    self = [super init];
    if ( !self ) return nil;
    _title = title;
    _subTitle = subTitle;
    _path = path;
    
    return self;
}

@end

static NSString * const FSMainTableCellIdentifier = @"FSMainTableCellIdentifier";

@interface FSViewController () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic, copy) NSArray *dataSource;
@end

@implementation FSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self _configData];
    
    [self _setupUI];
}

- (void)_setupUI {
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.title = @"AVDemos";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
}

- (void)_configData {
    NSMutableArray<FSSectionItem<FSItem *> *> *mulData = [NSMutableArray array];
    
    [mulData addObject:[[FSSectionItem alloc] initWithTitle:@"Audio Demos" items:[self _audioItems]]];
    
    [mulData addObject:[[FSSectionItem alloc] initWithTitle:@"Video Demos" items:[self _videoItems]]];
    
    self.dataSource = mulData.copy;
}

- (NSArray *)_audioItems {
    return @[
        [[FSItem alloc] initWithTitle:@"Audio Capture" subTitle:@"音频采集" path:@"FSAudioCaptureVC"],
        [[FSItem alloc] initWithTitle:@"Audio Encoder" subTitle:@"音频编码" path:@"FSAudioEncoderVC"],
        [[FSItem alloc] initWithTitle:@"Audio Muxer" subTitle:@"音频封装" path:@"FSAudioMuxerVC"],
    ];
}

- (NSArray *)_videoItems {
    return @[
        [[FSItem alloc] initWithTitle:@"Video Capture" subTitle:@"视频采集" path:@"FSVideoCaptureVC"],
        [[FSItem alloc] initWithTitle:@"Video Encoder" subTitle:@"视频编码" path:@"FSVideoEncoderVC"],
        [[FSItem alloc] initWithTitle:@"Video Muxer" subTitle:@"视频封装" path:@"FSVideoMuxerVC"],
    ];
}

#pragma mark - Navigation
- (void)goToDemoPageWithViewControllerName:(NSString *)name {
    UIViewController *vc = [(UIViewController *) [NSClassFromString(name) alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    FSSectionItem *sectionItem = self.dataSource[indexPath.section];
    FSItem *item = sectionItem.items[indexPath.row];
    [self goToDemoPageWithViewControllerName:item.path];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    FSSectionItem *sectionItem = self.dataSource[section];
    return sectionItem.title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    FSSectionItem *sectionItem = self.dataSource[section];
    return sectionItem.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FSMainTableCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:FSMainTableCellIdentifier];
    }
    FSSectionItem *sectionItem = self.dataSource[indexPath.section];
    FSItem *item = sectionItem.items[indexPath.row];
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = item.subTitle;
    
    return cell;
}

#pragma mark - Property
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 50;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
    }
    
    return _tableView;
}

@end
