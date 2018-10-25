//
//  ViewController.m
//  MDHVideoListScroll
//
//  Created by Apple on 2018/10/24.
//  Copyright © 2018年 马大哈. All rights reserved.
//

#import "ViewController.h"
#import "VideoCell.h"


/*
 * The scroll derection of scrollView.
 */
typedef NS_ENUM(NSUInteger, ZFPlayerScrollDerection) {
    ZFPlayerScrollDerectionNone = 0,
    ZFPlayerScrollDerectionUp,        // Scroll up
    ZFPlayerScrollDerectionDown       // Scroll Down
};


static NSString *kIdentifier = @"kIdentifier";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat zf_lastOffsetY;
@property (nonatomic, strong) NSIndexPath *zf_playingIndexPath;
@property (nonatomic, assign) ZFPlayerScrollDerection zf_scrollDerection;

@property (nonatomic, strong) UIButton *playBtn;


@end

@implementation ViewController



#pragma mark - getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
        [_tableView registerClass:[VideoCell class] forCellReuseIdentifier:kIdentifier];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
    }
    return _tableView;
}


- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.backgroundColor = [UIColor yellowColor];
        _playBtn.frame = CGRectMake(0, 0, 50, 50);
    }
    return _playBtn;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    self.zf_playingIndexPath = indexPath;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell.contentView addSubview:self.playBtn];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return 200.0;

}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    /*
     如果用户一旦接触scrollview就返回YES,有可能还没有开始拖动
    @property(nonatomic,readonly,getter=isTracking)     BOOL tracking;
     如果用户已经开始拖动就返回YES，
    @property(nonatomic,readonly,getter=isDragging)     BOOL dragging;
     如果用户没有在拖动（手指没有接触scrollview）就返回YES，但是scrollview仍然在惯性滑动
    @property(nonatomic,readonly,getter=isDecelerating) BOOL decelerating;
     */
    BOOL scrollToScrollStop = !self.tableView.isTracking && !self.tableView.isDragging && !self.tableView.isDecelerating;
    if (scrollToScrollStop) {
        [self _scrollViewDidStopScroll];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    if (!decelerate) {
        BOOL dragToDragStop = !self.tableView.isTracking && !self.tableView.isDragging && !self.tableView.isDecelerating;
        if (dragToDragStop) {
            [self _scrollViewDidStopScroll];
        }
    }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
   
    [self _scrollViewDidStopScroll];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
   
    [self _scrollViewScrolling];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
   
    [self _scrollViewBeginDragging];
}



#pragma mark - helper

- (void)_scrollViewDidStopScroll {
   
    NSLog(@"tableview已经停止滚动");
}

- (void)_scrollViewBeginDragging {
    self.zf_lastOffsetY = self.tableView.contentOffset.y;
}

- (void)_scrollViewScrolling {
    CGFloat offsetY = self.tableView.contentOffset.y;
    self.zf_scrollDerection = (offsetY - self.zf_lastOffsetY > 0) ? ZFPlayerScrollDerectionUp : ZFPlayerScrollDerectionDown;
    self.zf_lastOffsetY = offsetY;
    
    NSLog(@"%@======self.tableView.contentOffset.y %.0f",self.zf_scrollDerection == ZFPlayerScrollDerectionUp ? @"向上滑动" :@"向下滑动",offsetY);
    
    // 当tablview已经无法正常向下滑动，此时如果一直向下拖动tableview，就无需继续执行以下逻辑代码。
    if (self.tableView.contentOffset.y < 0) return;
    
    // 如果当前没有播放的cell，就无需继续执行以下逻辑代码。
    if (!self.zf_playingIndexPath) return;
    
    UIView *cell = [self zf_getCellForIndexPath:self.zf_playingIndexPath];
    if (!cell) {
        NSLog(@"没有正在播放视频的cell");
        return;
    }
    UIView *playerView = [cell viewWithTag:1000];
    CGRect rect = [playerView convertRect:playerView.frame toView:self.view];
    
    NSLog(@"把containerView转换rect到VC.view上，与tableview同级");
    
    CGFloat topSpacing = CGRectGetMinY(rect) - CGRectGetMinY(self.tableView.frame) - CGRectGetMinY(playerView.frame) - self.tableView.contentInset.top;
    NSLog(@"当前播放的View距离Tableview<上>边界距离（frame高度）：%f",topSpacing);
    
    CGFloat bottomSpacing = CGRectGetMaxY(self.tableView.frame) - CGRectGetMaxY(rect) + CGRectGetMinY(playerView.frame) - self.tableView.contentInset.bottom;
    NSLog(@"当前播放的View距离Tableview<下>边界距离（frame高度）：%f",bottomSpacing);
    
    CGFloat contentInsetHeight = CGRectGetMaxY(self.tableView.frame) - CGRectGetMinY(self.tableView.frame) - self.tableView.contentInset.top - self.tableView.contentInset.bottom;
    NSLog(@"当前tableview的内容高度：%f",contentInsetHeight);
    
    CGFloat playerDisapperaPercent = 0;
    CGFloat playerApperaPercent = 0;
    
    // 向上滑动
    if (self.zf_scrollDerection == ZFPlayerScrollDerectionUp) { /// Scroll up
        /// Player is disappearing.
        /*
         场景分析:
         当前播放器位于屏幕中间，向上滑动此时尚未滑出屏幕前 topSpacing-正数 playerDisapperaPercent-负数，
         一旦播放器上边界滑出屏幕playerDisapperaPercent-> 正数并逐步大于1.0，
         此时已经呈现播放器正逐步离开当前屏幕有效区域
         */
        if (topSpacing <= 0 && CGRectGetHeight(rect) != 0) {
            playerDisapperaPercent = -topSpacing/CGRectGetHeight(rect);
            if (playerDisapperaPercent > 1.0) playerDisapperaPercent = 1.0;
            NSLog(@"当前播放视频的cell正在离开当前屏幕有效播放区域。。。。。。");
        }
        
        /// Top area
        if (topSpacing <= 0 && topSpacing > -CGRectGetHeight(rect)/2) {

            NSLog(@"当前播放视频的cell《即将离开》当前屏幕有效播放区域。。。。。。");

        } else if (topSpacing <= -CGRectGetHeight(rect)) {

            NSLog(@"当前播放视频的cell《已经离开》当前屏幕有效播放区域。。。。。。");

        } else if (topSpacing > 0 && topSpacing <= contentInsetHeight) {

            if (CGRectGetHeight(rect) != 0) {
                playerApperaPercent = -(topSpacing-contentInsetHeight)/CGRectGetHeight(rect);
                if (playerApperaPercent > 1.0) playerApperaPercent = 1.0;
                NSLog(@"当前播放视频的cell在当前屏幕有效播放区域上持续出现。。。。。。");
                
            }

            if (topSpacing <= contentInsetHeight && topSpacing > contentInsetHeight-CGRectGetHeight(rect)/2) {

                NSLog(@"当前播放视频的cell《即将出现》在当前屏幕有效播放区域。。。。。。");

            } else {
                NSLog(@"当前播放视频的cell《已经出现》在当前屏幕有效播放区域。。。。。。");
            }
        }
        
    } else if (self.zf_scrollDerection == ZFPlayerScrollDerectionDown) { /// 向下滑动

        if (bottomSpacing <= 0 && CGRectGetHeight(rect) != 0) {
            playerDisapperaPercent = -bottomSpacing/CGRectGetHeight(rect);
            if (playerDisapperaPercent > 1.0) playerDisapperaPercent = 1.0;
            NSLog(@"当前播放视频的cell正在离开当前屏幕有效播放区域。。。。。。");
        }

        if (bottomSpacing <= 0 && bottomSpacing > -CGRectGetHeight(rect)/2) {

            NSLog(@"当前播放视频的cell《即将离开》当前屏幕有效播放区域。。。。。。");

        } else if (bottomSpacing <= -CGRectGetHeight(rect)) {
            NSLog(@"当前播放视频的cell《已经离开》当前屏幕有效播放区域。。。。。。");

        } else if (bottomSpacing > 0 && bottomSpacing <= contentInsetHeight) {

            if (CGRectGetHeight(rect) != 0) {
                playerApperaPercent = -(bottomSpacing-contentInsetHeight)/CGRectGetHeight(rect);
                if (playerApperaPercent > 1.0) playerApperaPercent = 1.0;

                NSLog(@"当前播放视频的cell在当前屏幕有效播放区域上持续出现。。。。。。");
            }

            if (bottomSpacing <= contentInsetHeight && bottomSpacing > contentInsetHeight-CGRectGetHeight(rect)/2) {

                NSLog(@"当前播放视频的cell《即将出现》在当前屏幕有效播放区域。。。。。。");
            } else {

                NSLog(@"当前播放视频的cell《已经出现》在当前屏幕有效播放区域。。。。。。");
            }
        }
    }
}

- (UIView *)zf_getCellForIndexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            
            return cell;
        }
    }
    
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;

    
    [self.view addSubview:self.tableView];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
