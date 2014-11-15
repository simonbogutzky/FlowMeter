//
//  AcknowledgementViewController.m
//  FlowMeter
//
//  Created by Simon Bogutzky on 15.11.14.
//  Copyright (c) 2014 Simon Bogutzky. All rights reserved.
//

#import "AcknowledgementViewController.h"

@interface AcknowledgementViewController ()
    @property (weak, nonatomic) IBOutlet UITextView *textViewAcknowledgement;
@end

@implementation AcknowledgementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textViewAcknowledgement.text = NSLocalizedString(@"Die Entwicklung des FlowMeters wurde vom BMBF-Projekt 'Flow-Maschinen: Körperbewegung und Klang' an der Hochschule Bremen unter der Leitung von Prof. Dr. phil. Barbara Grüter unterstürzt (http://www.informatik.hs-bremen.de/gob/flow/). Ich danke meinen Kollegen des Flow-Maschinen Projekts Barbara Grüter und Nassrin Hajinejad für die Inspiration und anregende Diskussionen.", @"Danksagungen");
}

@end
