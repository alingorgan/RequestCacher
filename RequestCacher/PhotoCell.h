//
//  PhotoCell.h
//  RequestCacher
//
//  Created by Alin Gorgan on 1/11/13.
//  Copyright (c) 2013 Alin Gorgan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"

@interface PhotoCell : UITableViewCell

@property (nonatomic, weak) IBOutlet AsyncImageView* imageView;

@end
