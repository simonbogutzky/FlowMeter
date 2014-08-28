//
//  LikertScaleViewController.m
//  DataCollector
//
//  Created by Simon Bogutzky on 21.01.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "LikertScaleViewController.h"

@interface LikertScaleViewController ()
@property (weak, nonatomic) IBOutlet UILabel *itemLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *likertScaleSegmentedControl;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *likertScaleLabels;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel3;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel2;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel1;
@property (nonatomic) int itemIndex;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSMutableArray *responses;
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
        self.likertScaleSegmentedControl.hidden = YES;
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
        _responses = [[NSMutableArray alloc] initWithCapacity:[_itemLabelTexts count]];
    }
    return _responses;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.itemLabel.text = [self.itemLabelTexts objectAtIndex:0];
    [self setSegmentsForItemIndex:0];
    self.scaleLabel1.text = [[self.scaleLabels objectAtIndex:0] objectAtIndex:0];
    self.scaleLabel2.text = [[self.scaleLabels objectAtIndex:0] objectAtIndex:1];
    self.scaleLabel3.text = [[self.scaleLabels objectAtIndex:0] objectAtIndex:2];
    self.date = [NSDate date];
}

- (void)setSegmentsForItemIndex:(NSInteger)itemIndex {
    
    if ([[self.itemSegments objectAtIndex:itemIndex] intValue] < self.likertScaleSegmentedControl.numberOfSegments) {
        NSUInteger currentSegmentCount = self.likertScaleSegmentedControl.numberOfSegments;
        NSUInteger newSegmentCount = [[self.itemSegments objectAtIndex:itemIndex] intValue];
        NSUInteger removeCount = currentSegmentCount - newSegmentCount;
        
        for (int i = 0; i < removeCount; i++) {
            [self.likertScaleSegmentedControl removeSegmentAtIndex:newSegmentCount animated:YES];
        }
    }
    
    if ([[self.itemSegments objectAtIndex:itemIndex] intValue] > self.likertScaleSegmentedControl.numberOfSegments) {
        for (NSUInteger i = self.likertScaleSegmentedControl.numberOfSegments + 1; i <= [[self.itemSegments objectAtIndex:itemIndex] intValue]; i++) {
            [self.likertScaleSegmentedControl insertSegmentWithTitle:@"" atIndex:i animated:YES];
        }
    }
}

- (IBAction)displayNextItem:(id)sender {
    [self.responses addObject:[NSNumber numberWithLong:self.likertScaleSegmentedControl.selectedSegmentIndex + 1]];
    
    self.itemIndex++;
    if (self.itemIndex < [self.itemLabelTexts count]) {
        self.itemLabel.text = [self.itemLabelTexts objectAtIndex:self.itemIndex];
        self.scaleLabel1.text = [[self.scaleLabels objectAtIndex:self.itemIndex] objectAtIndex:0];
        self.scaleLabel2.text = [[self.scaleLabels objectAtIndex:self.itemIndex] objectAtIndex:1];
        self.scaleLabel3.text = [[self.scaleLabels objectAtIndex:self.itemIndex] objectAtIndex:2];
        
        [self setSegmentsForItemIndex:self.itemIndex];
        [self.likertScaleSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    } else {
        if ([self.delegate respondsToSelector:@selector(likertScaleViewController:didFinishWithResponses:atDate:)]) {
            [self.delegate likertScaleViewController:self didFinishWithResponses:self.responses atDate:self.date];
        }
    }
    
}

@end
