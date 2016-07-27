//
//  ViewController.m
//  NowTableViewLoadmore
//
//  Created by liangshangjia on 16/7/25.
//  Copyright © 2016年 Stree7. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    UIActivityIndicatorView *_indicator;
}
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, assign) BOOL isloading;
@property (nonatomic, assign) BOOL isdragging;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.tableView setRowHeight:50];
    _dataArray = [NSMutableArray array];
    [self.tableView setBackgroundColor:[UIColor blackColor]];
    
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [view addSubview:indicator];
    indicator.center = view.center;
    [indicator startAnimating];
    _indicator = indicator;
    view.backgroundColor = [UIColor blackColor];
    self.tableView.tableHeaderView = view;
    
    [self loadDefaultDataWithNum:20];
}


- (NSArray *)randomData
{
    return [self randomDataWithNum:(arc4random()%5)+5];
}


- (void)loadDefaultDataWithNum:(NSUInteger)num
{
    self.isloading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"HH_mm_ss"];
        for (NSUInteger i = 0; i < num; i ++) {
            
            NSString *str = [formatter stringFromDate: [NSDate date]];
            [self.dataArray insertObject:[NSString stringWithFormat:@"%@ ___ %@",@(arc4random()%100),str] atIndex:0];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isloading = NO;
        });
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];


    });
    

}


- (NSArray *)randomDataWithNum:(NSUInteger)num
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"HH_mm_ss"];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:num];
    
    for (NSUInteger i = 0; i < num; i ++) {
        
        [NSThread sleepForTimeInterval:1];
        NSString *str = [formatter stringFromDate: [NSDate date]];
        [array addObject:[NSString stringWithFormat:@"%@ ___ %@",@(arc4random()%100),str]];
    }
    return array;
}


// http://stackoverflow.com/a/11602040 Keep UITableView static when inserting rows at the top
- (void)staticLoadMore
{
    
    self.isloading = YES;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray *oldMessages = [self randomData];
        __block CGPoint delayOffset = weakSelf.tableView.contentOffset;
        NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:oldMessages.count];
        NSMutableIndexSet *indexSets = [[NSMutableIndexSet alloc] init];
        [oldMessages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            [indexPaths addObject:indexPath];
            
            delayOffset.y += 50; //cell高度，此处要给予高度
            [indexSets addIndex:idx];
        }];
        
        NSMutableArray *messages = [[NSMutableArray alloc] initWithArray:weakSelf.dataArray];
        [messages insertObjects:oldMessages atIndexes:indexSets];
        
        
        [NSThread sleepForTimeInterval:1];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView setAnimationsEnabled:NO];
            weakSelf.tableView.userInteractionEnabled = NO;
            //            [weakSelf.tableView beginUpdates];
            
            weakSelf.dataArray = messages;
            
            [weakSelf.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            
            //            [weakSelf.tableView endUpdates];
            
            [UIView setAnimationsEnabled:YES];
            
            [weakSelf.tableView setContentOffset:delayOffset animated:NO];
            weakSelf.tableView.userInteractionEnabled = YES;
            self.isloading = NO;
        });
        
    });
    
}



- (void)setIsloading:(BOOL)isloading
{
    _isloading = isloading;
    isloading ? [_indicator startAnimating] : [_indicator stopAnimating];
}

#pragma mark - Tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (nil == cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.backgroundColor = [UIColor blackColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    [cell.textLabel setText:self.dataArray[indexPath.row]];

    return cell;
}




#pragma mark - Scrollview


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isdragging = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    _isdragging = NO;
    

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y <= 30) {
        if (!_isloading && !_isdragging) {
            [self staticLoadMore];
        }
    }
}




@end
