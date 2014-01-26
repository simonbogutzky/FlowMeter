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

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.itemLabel.text = [self.itemLabelTexts objectAtIndex:0];
    [self setSegmentsForItemIndex:0];
}

- (void)setSegmentsForItemIndex:(NSInteger)itemIndex {
    
    if ([[self.itemSegments objectAtIndex:itemIndex] intValue] < self.likertScaleSegmentedControl.numberOfSegments) {
        for (int i = 0; i < self.likertScaleSegmentedControl.numberOfSegments; i++) {
            if (i >= [[self.itemSegments objectAtIndex:itemIndex] intValue] - 1) {
                [self.likertScaleSegmentedControl removeSegmentAtIndex:i - 1 animated:YES];
            }
        }
    }
    
    if ([[self.itemSegments objectAtIndex:itemIndex] intValue] > self.likertScaleSegmentedControl.numberOfSegments) {
        for (int i = self.likertScaleSegmentedControl.numberOfSegments + 1; i <= [[self.itemSegments objectAtIndex:itemIndex] intValue]; i++) {
            [self.likertScaleSegmentedControl insertSegmentWithTitle:@"" atIndex:i animated:YES];
        }
    }
}

- (IBAction)displayNextItem:(id)sender {
    self.itemIndex++;
    if (self.itemIndex < [self.itemLabelTexts count]) {
        self.itemLabel.text = [self.itemLabelTexts objectAtIndex:self.itemIndex];
        
        [self setSegmentsForItemIndex:self.itemIndex];
    }
    
    [self.likertScaleSegmentedControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
}

@end
