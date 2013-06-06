//
//  PhotoCell.m
//  RequestCacher
//
//  Created by Alin Gorgan on 1/11/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import "PhotoCell.h"

@implementation PhotoCell

@synthesize imageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
