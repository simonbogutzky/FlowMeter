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
    for (int i = 4; i <= [[self.itemSegments objectAtIndex:0] intValue]; i++) {
        [self.likertScaleSegmentedControl insertSegmentWithTitle:@"" atIndex:i animated:NO];
    }
}


@end
