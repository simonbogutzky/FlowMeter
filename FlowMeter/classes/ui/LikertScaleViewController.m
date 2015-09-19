//
//  LikertScaleViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 21.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "LikertScaleViewController.h"

@interface LikertScaleViewController ()
@property (weak, nonatomic) IBOutlet UILabel *itemLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *likertScaleLabels;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel3;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel2;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel1;
@property (nonatomic) int itemIndex;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSMutableArray *responses;
@property (strong, nonatomic) NSMutableArray *circleControls;
@property (strong, nonatomic) NSMutableArray *circleIndicatorControls;
@end

@implementation LikertScaleViewController

#pragma mark -
#pragma mark - Getter (Lazy-Instantiation)

- (NSArray *)itemLabelTexts
{
    if (!_itemLabelTexts) {
        _itemLabelTexts = @[NSLocalizedString(@"Keine Items vorhanden", @"Keine Items vorhanden")];
    }
    return _itemLabelTexts;
}

- (NSArray *)itemSegments
{
    if (!_itemSegments) {
        _itemSegments = @[@1];
        for (UILabel *likertScaleLabel in self.likertScaleLabels) {
            likertScaleLabel.hidden = YES;
        }
    }
    return _itemSegments;
}

- (NSArray *)scaleLabels
{
    if (!_scaleLabels) {
        _scaleLabels = @[@[@"Trifft nicht zu", @"teils-teils", @"Trifft zu"]];
    }
    return _scaleLabels;
}

- (NSMutableArray *)responses
{
    if (!_responses) {
        _responses = [[NSMutableArray alloc] initWithCapacity:_itemLabelTexts.count];
    }
    return _responses;
}

- (NSMutableArray *)circleControls
{
    if (!_circleControls) {
        int numberOfItems = [(self.itemSegments)[self.itemIndex] intValue];
        _circleControls = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        _circleIndicatorControls = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        for (int i = 0; i < numberOfItems; i++) {
            UIControl *circleControl = [[UIControl alloc] initWithFrame:CGRectNull];
            circleControl.layer.cornerRadius = 10;
            
            UIControl *circleIndicatorControl = [[UIControl alloc] initWithFrame:CGRectNull];
            circleIndicatorControl.layer.cornerRadius = 14;
            if (self.cicleColors != nil) {
                circleControl.backgroundColor = self.cicleColors[i % (self.cicleColors.count)];
            } else {
                circleControl.backgroundColor = [UIColor redColor];
            }
            circleIndicatorControl.backgroundColor = [UIColor clearColor];
            circleControl.tag = i;
            circleIndicatorControl.tag = i;
            [circleControl addTarget:self action:@selector(circleControlTouchedInside:) forControlEvents:UIControlEventTouchUpInside];
            [circleIndicatorControl addTarget:self action:@selector(circleControlTouchedInside:) forControlEvents:UIControlEventTouchUpInside];
            [_circleControls addObject:circleControl];
            [_circleIndicatorControls addObject:circleIndicatorControl];
            [self.view addSubview:circleIndicatorControl];
            [self.view addSubview:circleControl];
        }
    }
    return _circleControls;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.itemLabel.text = (self.itemLabelTexts)[0];
    [self setCircleControlsForItemIndex:0];
    self.scaleLabel1.text = (self.scaleLabels)[0][0];
    self.scaleLabel2.text = (self.scaleLabels)[0][1];
    self.scaleLabel3.text = (self.scaleLabels)[0][2];
    self.date = [NSDate date];
}

- (void)increaseItemIndex
{
    self.itemIndex++;
    if (self.itemIndex < (self.itemLabelTexts).count) {
        self.itemLabel.text = (self.itemLabelTexts)[self.itemIndex];
        self.scaleLabel1.text = (self.scaleLabels)[self.itemIndex][0];
        self.scaleLabel2.text = (self.scaleLabels)[self.itemIndex][1];
        self.scaleLabel3.text = (self.scaleLabels)[self.itemIndex][2];
        
        [self setCircleControlsForItemIndex:self.itemIndex];
    } else {
        if ([self.delegate respondsToSelector:@selector(likertScaleViewController:didFinishWithResponses:atDate:)]) {
            [self.delegate likertScaleViewController:self didFinishWithResponses:self.responses atDate:self.date];
        }
    }
}

#pragma mark -
#pragma mark - CircleControl methods

- (void)redrawCicleControlsForSize:(CGSize)size
{
    CGFloat screenWidth = size.width;
    CGFloat screenHeight = size.height;
    NSUInteger numberOfCircles = (self.circleControls).count;
    CGFloat offset = (screenWidth - 80) / (numberOfCircles - 1);
    int i = 0;
    for (UIControl *circleControl in self.circleControls) {
        circleControl.frame = CGRectMake(45 - 14 + offset * i, screenHeight/2 + 9, 18, 18);
        i++;
    }
    i = 0;
    for (UIControl *circleIndicatorControl in self.circleIndicatorControls) {
        circleIndicatorControl.frame = CGRectMake(40 - 14 + offset * i, screenHeight/2 + 4, 28, 28);
        i++;
    }
}

- (void)setCircleControlsForItemIndex:(NSInteger)itemIndex {
    if (self.circleControls != nil) {
        for (UIControl *circleControl in self.circleControls) {
            [circleControl removeFromSuperview];
        }
        self.circleControls = nil;
        
        for (UIControl *circleIndicatorControls in self.circleIndicatorControls) {
            [circleIndicatorControls removeFromSuperview];
        }
        self.circleIndicatorControls = nil;
        
    }
    CGRect screenBound = [UIScreen mainScreen].bounds;
    CGSize screenSize = screenBound.size;
    [self redrawCicleControlsForSize:screenSize];
}

#pragma mark -
#pragma mark - IBActions

- (IBAction)circleControlTouchedInside:(id)sender
{
    UIControl *circleControl = sender;
    
    UIControl *circleIndicatorControl = self.circleIndicatorControls[circleControl.tag];
    circleIndicatorControl.backgroundColor = [self.cicleColors[circleControl.tag] colorWithAlphaComponent:0.6];
    [self.responses addObject:@(circleControl.tag + 1)];
    
    [self performSelector:@selector(increaseItemIndex) withObject:nil afterDelay:0.1];
}

- (IBAction)cancelTouched:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(likertScaleViewControllerCancelled:)]) {
        [self.delegate likertScaleViewControllerCancelled:self];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self redrawCicleControlsForSize:size];
}

@end
