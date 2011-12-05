//
//  BookmarkCell.h
//  docnext
//
//  Created by  on 11/10/20.
//  Copyright (c) 2011 Archilogic. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IMAGE_LIST_ITEM_CELL_HEIGHT 116

@interface ImageListItemCell : UITableViewCell

@property (retain, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property(nonatomic, retain) IBOutlet UITextView* textView;
@property(nonatomic, retain) IBOutlet UILabel* pageLabel;

@end
