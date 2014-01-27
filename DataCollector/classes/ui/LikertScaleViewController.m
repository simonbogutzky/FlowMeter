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
@property (nonatomic) int itemIndex;
@property (nonatomic) double timestamp;
@property (strong, nonatomic) NSMutableArray *itemResponses;
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

- (NSMutableArray *)itemResponses
{
    if (!_itemResponses) {
        _itemResponses = [[NSMutableArray alloc] initWithCapacity:[_itemLabelTexts count]];
    }
    return _itemResponses;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.itemLabel.text = [self.itemLabelTexts objectAtIndex:0];
    [self setSegmentsForItemIndex:0];
    self.timestamp = [[NSDate date] timeIntervalSince1970];
}

- (void)setSegmentsForItemIndex:(NSInteger)itemIndex {
    
    if ([[self.itemSegments objectAtIndex:itemIndex] intValue] < self.likertScaleSegmentedControl.numberOfSegments) {
        int currentSegmentCount = self.likertScaleSegmentedControl.numberOfSegments;
        int newSegmentCount = [[self.itemSegments objectAtIndex:itemIndex] intValue];
        int removeCount = currentSegmentCount - newSegmentCount;
        
        for (int i = 0; i < removeCount; i++) {
            [self.likertScaleSegmentedControl removeSegmentAtIndex:newSegmentCount animated:YES];
        }
    }
    
    if ([[self.itemSegments objectAtIndex:itemIndex] intValue] > self.likertScaleSegmentedControl.numberOfSegments) {
        for (int i = self.likertScaleSegmentedControl.numberOfSegments + 1; i <= [[self.itemSegments objectAtIndex:itemIndex] intValue]; i++) {
            [self.likertScaleSegmentedControl insertSegmentWithTitle:@"" atIndex:i animated:YES];
        }
    }
}

- (IBAction)displayNextItem:(id)sender {
    [self.itemResponses addObject:[NSNumber numberWithInt:self.likertScaleSegmentedControl.selectedSegmentIndex]];
    
    self.itemIndex++;
    if (self.itemIndex < [self.itemLabelTexts count]) {
        self.itemLabel.text = [self.itemLabelTexts objectAtIndex:self.itemIndex];
        
        [self setSegmentsForItemIndex:self.itemIndex];
        [self.likertScaleSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    } else {
        if ([self.delegate respondsToSelector:@selector(likertScaleViewController:didFinishWithResponses:atTimestamp:)]) {
            [self.delegate likertScaleViewController:self didFinishWithResponses:self.itemResponses atTimestamp:self.timestamp];
        }
    }
    
}

@end
