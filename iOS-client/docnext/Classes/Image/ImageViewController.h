//
//  ImageViewController.h
//  docnext
//
//  Created by  on 11/10/03.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "GestureRecognizerView.h"
#import "BindQueueItem.h"
#import "DownloaderTypes.h"
#import "ESRenderer.h"
#import "FlowCoverView.h"
#import "EAGLView.h"

@class ImageAnnotationInfo;

@protocol PageLoader <NSObject>

- (void)loadTop:(int)page;
- (void)loadRest:(int)page;
- (void)unloadTop:(int)page;
- (void)unloadRest:(int)page;

@end

@protocol TextureBinder <NSObject>

- (void)bind:(BindQueueItem *)item;

@end

@protocol PageChangeListener <NSObject>

- (void)pageChange:(int)page;

@end

@protocol PageChanger <NSObject>

- (void)changePage:(int)page refresh:(BOOL)refresh;

@end

@protocol MoviePresenter <NSObject>

- (void)showMovie:(ImageAnnotationInfo *)info;

@end

@interface ImageViewController : UIViewController <GestureRecognizerDelegate, PageLoader, TextureBinder, PageChangeListener, UIAlertViewDelegate, ESRendererDelegate, FlowCoverViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, PageChanger, MoviePresenter>

@property(nonatomic, retain) IBOutlet GestureRecognizerView* gestureRecognizerView;
@property(nonatomic, retain) IBOutlet UIView* pageLoadingView;
@property(nonatomic, retain) IBOutlet UIView* menuView;
@property(nonatomic, retain) IBOutlet UILabel* memoryView;
@property(nonatomic, retain) IBOutlet UILabel* pageInfoLabel;
@property(nonatomic, retain) IBOutlet UIButton* toggleBookmarkButton;
@property(nonatomic, retain) IBOutlet UIView* menuButtonsView;
@property(nonatomic, retain) IBOutlet UIView* menuLabelsView;
@property(nonatomic, retain) IBOutlet UIButton* thumbnailButton;
@property(nonatomic, retain) IBOutlet UIButton* tocButton;
@property(nonatomic, retain) IBOutlet UIButton* bookmarkButton;
@property(nonatomic, retain) IBOutlet UIButton* configButton;
@property(nonatomic, retain) IBOutlet UIView* thumbnailView;
@property(nonatomic, retain) IBOutlet UIView* tocView;
@property(nonatomic, retain) IBOutlet UIView* bookmarkView;
@property(nonatomic, retain) IBOutlet UIView* configView;
@property(nonatomic, retain) IBOutlet UIView* configOtherView;
@property(nonatomic, retain) IBOutlet UIButton* readingDirectionHorizontalButton;
@property(nonatomic, retain) IBOutlet UIButton* readingDirectionVerticalButton;
@property(nonatomic, retain) IBOutlet UILabel* rotationLockLabel;
@property(nonatomic, retain) IBOutlet UISwitch* rotationLockSwitch;
@property(nonatomic, retain) IBOutlet UISlider* brightnessSlider;
@property(nonatomic, retain) IBOutlet UIButton* hideMenuButton;
@property(nonatomic, retain) IBOutlet UIView* progressHolder;
@property(nonatomic, retain) IBOutlet UIProgressView* progressView;
@property(nonatomic, retain) IBOutlet UIView* brightnessView;

@property(nonatomic, retain) IBOutlet FlowCoverView* thumbnailFlowCoverView;
@property(nonatomic, retain) IBOutlet UILabel* thumbnailPageLabel;
@property(nonatomic, retain) IBOutlet UISlider* thumbnailPageSlider;

@property(nonatomic, retain) IBOutlet UITableView* tocTableView;

@property(nonatomic, retain) IBOutlet UITableView* bookmarkTableView;

- (IBAction)toggleBookmarkButtonClick;
- (IBAction)thumbnailButtonClick;
- (IBAction)tocButtonClick;
- (IBAction)bookmarkButtonClick;
- (IBAction)configButtonClick;
- (IBAction)brightnessChanged;
- (IBAction)zoomSizeNormalClick;
- (IBAction)zoomSizeDoubleClick;
- (IBAction)readingDirectionHorizontalClick;
- (IBAction)readingDirectionVerticalClick;
- (IBAction)rotationLockChanged;
- (IBAction)backClick;
- (IBAction)hideMenuClick;
- (void)setParams:(NSString* )docId permitType:(DownloaderPermitType)permitType;
- (void)bindMenuInfo;
- (natural_t)get_free_memory;
- (u_int)get_resident_size;
- (void)updateMemoryUsage;
- (IBAction)thumbnailPageSliderChanged;

@end
