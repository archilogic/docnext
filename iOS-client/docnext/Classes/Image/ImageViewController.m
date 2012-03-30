//
//  ImageViewController.m
//  docnext
//
//  Created by  on 11/10/03.
//  Copyright 2011 Archilogic. All rights reserved.
//

#import "ImageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageState.h"
#import "ImageRenderEngine.h"
#import "LocalProviderUtil.h"
#import "ImageLevelUtil.h"
#import "LoadImageTask.h"
#import "Utilities.h"
#import "Downloader.h"
#import "FileUtil.h"
#import "LocalPathUtil.h"
#import "EAGLView.h"
#import "ConfigProvider.h"
#import "ImageListItemInfo.h"
#import "ImageListItemCell.h"
#import "BookmarkInfo.h"
#import "OrientationUtil.h"
#import "ImageAnnotationInfo.h"
#import "DebugLog.h"
#import "ASIHTTPRequest.h"

#import <MediaPlayer/MediaPlayer.h>

#define CONFIRM_RESTORE_LAST_OPENED_PAGE_TAG 123
#define CONFIRM_FINISH_TAG 234

@interface ImageViewController ()

@property(nonatomic, retain) ImageState* state;
@property(nonatomic, retain) ImageRenderEngine* renderEngine;
@property(nonatomic, retain) NSOperationQueue* executor;
@property(retain) NSMutableArray* bindQueue;
@property(retain) NSMutableArray* unbindQueue;
@property(nonatomic) DownloaderPermitType permitType;
@property(nonatomic) BOOL initialized;
@property(nonatomic, assign) UIView* currentMenuView;
@property(nonatomic, retain) NSMutableArray* toc;
@property(nonatomic, retain) NSMutableArray *bookmarks;
@property(nonatomic) BOOL downloadCompleted;
@property(nonatomic) int lastSelectedBookmarkTextViewIndex;
@property(nonatomic) CGSize thumbnailSize;
@property(nonatomic, retain) NSArray* toPortraitPage;
@property(nonatomic, retain) MPMoviePlayerController* moviePlayer;
@property(nonatomic) UIInterfaceOrientation orientationOnEnterMovie;

@end

@implementation ImageViewController

@synthesize gestureRecognizerView;
@synthesize pageLoadingView;
@synthesize menuView;
@synthesize memoryView;
@synthesize pageInfoLabel;
@synthesize toggleBookmarkButton;
@synthesize menuButtonsView;
@synthesize menuLabelsView;
@synthesize thumbnailButton;
@synthesize tocButton;
@synthesize bookmarkButton;
@synthesize configButton;
@synthesize thumbnailView;
@synthesize tocView;
@synthesize bookmarkView;
@synthesize configView;
@synthesize configOtherView;
@synthesize readingDirectionHorizontalButton;
@synthesize readingDirectionVerticalButton;
@synthesize rotationLockLabel;
@synthesize rotationLockSwitch;
@synthesize brightnessSlider;
@synthesize hideMenuButton;
@synthesize progressHolder;
@synthesize progressView;
@synthesize brightnessView;

@synthesize thumbnailFlowCoverView;
@synthesize thumbnailPageLabel;
@synthesize thumbnailPageSlider;

@synthesize tocTableView;

@synthesize bookmarkTableView;

@synthesize state;
@synthesize renderEngine;
@synthesize executor;
@synthesize bindQueue;
@synthesize unbindQueue;
@synthesize permitType;
@synthesize initialized;
@synthesize currentMenuView;
@synthesize toc;
@synthesize bookmarks;
@synthesize downloadCompleted;
@synthesize lastSelectedBookmarkTextViewIndex;
@synthesize thumbnailSize;
@synthesize toPortraitPage;
@synthesize moviePlayer;
@synthesize orientationOnEnterMovie;

- (void)err:(NSString *)tag {
    GLenum err = glGetError();
    if(err){
        NSLog(@"GLError at %@ 0x0%X", tag, err);
    }
}

- (CGSize)convertCGSize:(CGSize)size {
    float f = self.view.contentScaleFactor;
    return CGSizeMake(size.width * f, size.height * f);
}

- (CGPoint)convertCGPoint:(CGPoint)point {
    float f = self.view.contentScaleFactor;
    return CGPointMake(point.x * f, point.y * f);
}

- (CGRect)invertCGRect:(CGRect)rect {
    float f = self.view.contentScaleFactor;
    return CGRectMake(rect.origin.x / f, rect.origin.y / f, rect.size.width / f, rect.size.height / f);
}

- (void)applyBrightness {
    self.brightnessView.alpha = 1 - [ConfigProvider brightness];
}

- (id)indexSafeAt:(NSArray *)list index:(int)index {
    if (index < 0 || index >= list.count) {
        return [NSNull null];
    }
    
    return AT(list, index);
}

- (UIImage *)thumbnailImage:(int)page {
    NSError* err = nil;
    
    NSArray* toPortrait = [self.state.image toPortraitPage:[LocalProviderUtil info:self.state.docId]];
    
    if ([self indexSafeAt:toPortrait index:page] != [NSNull null]) {
        if (self.downloadCompleted) {
            int p = AT_AS(toPortrait, page, NSNumber).intValue;
            
            NSString* path = [FileUtil fullPath:[LocalPathUtil imageThumbnailPath:self.state.docId page:p]];
            
            NSData* data = [NSData dataWithContentsOfFile:path options:0 error:&err];
            if (err) {
                NSLog(@"Error: %@", err);
                assert(0);
            }

            UIImage* thumb = [UIImage imageWithData:data];
            
            self.thumbnailSize = thumb.size;
            
            return thumb;
        } else {
            return [UIImage imageNamed:@"image_downloading"];
        }
    } else {
        UIGraphicsBeginImageContext(self.thumbnailSize);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, self.thumbnailSize.width, self.thumbnailSize.height));
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
}

- (void)loadTOC {
    self.toc = [NSMutableArray arrayWithCapacity:0];
    
    for (NSDictionary* elem in [[LocalProviderUtil info:self.state.docId] toc:self.state.image]) {
        @autoreleasepool {
            int page = FOR_I(elem, @"page");
            NSString* text = FOR(elem, @"text");
            
            [self.toc addObject:[ImageListItemInfo infoWithParam:[self thumbnailImage:page] page:page text:text]];
        }
    }
}

- (void)loadBookmarks {
    self.bookmarks = [NSMutableArray arrayWithCapacity:0];
    
    for (BookmarkInfo* b in [LocalProviderUtil bookmark:self.state.docId]) {
        @autoreleasepool {
            [self.bookmarks addObject:[ImageListItemInfo infoWithParam:[self thumbnailImage:b.page] page:b.page text:b.comment]];
        }
    }
}

- (void)bindConfig {
    self.brightnessSlider.value = ([ConfigProvider brightness] - 0.2) / 0.8;
    [self.rotationLockSwitch setOn:[ConfigProvider orientation] != ConfigProviderOrientationFree];
    
    if ([ConfigProvider readingDirection] == ConfigProviderReadingDirectionHorizontal) {
        [self.readingDirectionHorizontalButton setImage:[UIImage imageNamed:@"button_reading_direction_horizontal_selected"] forState:UIControlStateNormal];
        [self.readingDirectionVerticalButton setImage:[UIImage imageNamed:@"button_reading_direction_vertical"] forState:UIControlStateNormal];
    } else {
        [self.readingDirectionHorizontalButton setImage:[UIImage imageNamed:@"button_reading_direction_horizontal"] forState:UIControlStateNormal];
        [self.readingDirectionVerticalButton setImage:[UIImage imageNamed:@"button_reading_direction_vertical_selected"] forState:UIControlStateNormal];
    }
}

- (void)prepareData {
    DocInfo* doc = [LocalProviderUtil info:self.state.docId];
    self.state.image = [LocalProviderUtil imageInfo:self.state.docId];

#ifdef DebugLogLevelDebug
    NSLog(@"width: %d, height: %d, maxLevel: %d, isUseActualSize: %d, maxNumberOfLevel: %d, isWebp: %d, hasConcatFile: %d", self.state.image.width, self.state.image.height, self.state.image.maxLevel, self.state.image.isUseActualSize, self.state.image.maxNumberOfLevel, self.state.image.isWebp, self.state.image.hasConcatFile);
#endif
    
    self.state.direction = doc.binding == ProviderBindingTypeLeft ? ImageDirectionL2R : ImageDirectionR2L;
    
    self.state.minLevel = [ImageLevelUtil minLevel:self.state.image.maxLevel];
    self.state.maxLevel = [ImageLevelUtil maxLevel:self.state.minLevel imageMaxLevel:self.state.image.maxLevel imageMaxNumberOfLevel:self.state.image.maxNumberOfLevel];
    
#ifdef DebugLogLevelDebug
    NSLog(@"state.minLevel: %d, state.maxLevel: %d", self.state.minLevel, self.state.maxLevel);
#endif
    
    // reduce level for memory
    if ([OrientationUtil isSpreadMode] && self.state.maxLevel > self.state.minLevel) {
        self.state.maxLevel--;
    }
    
    int width = self.state.minLevel != self.state.image.maxLevel || !self.state.image.isUseActualSize ? TEXTURE_SIZE * pow(2, self.state.minLevel) : self.state.image.width;
    self.state.pageSize = CGSizeMake(width, self.state.image.height * width / self.state.image.width);

    self.state.pages = [doc pages:self.state.image];
    
    self.state.spreadFirstPages = [doc firstPages:self.state.image];
    
    if ([OrientationUtil isSpreadMode]) {
        if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page)] && self.state.direction == ImageDirectionR2L) {
            self.state.page++;
        } else if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page - 1)] && self.state.direction == ImageDirectionL2R) {
            self.state.page--;
        }
    }
    
    [self.state loadOverlay];
    
    self.thumbnailFlowCoverView.imageRatio = 1.0 * self.state.image.width / self.state.image.height;
    
    [self bindMenuInfo];
}

- (void)setupGL {
    // initialize gl
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    // glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) seems not valid
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    // glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    // glEnable(GL_ALPHA_BITS);
}

- (void)prepareGL {
    self.state.surfaceSize = [self convertCGSize:self.view.bounds.size];
    [self.state initScale];
    
    [self.renderEngine prepare:self.state.pages minLevel:self.state.minLevel maxLevel:self.state.maxLevel pageSize:self.state.pageSize surfaceSize:self.state.surfaceSize image:self.state.image doc:[LocalProviderUtil info:self.state.docId]];
    
    if ([OrientationUtil isSpreadMode]) {
#ifdef PRELOAD
        [self loadTop:self.state.page];
        [self loadTop:self.state.page + 1];
        [self loadTop:self.state.page + 2];
        [self loadTop:self.state.page + 3];
        [self loadTop:self.state.page - 1];
        [self loadTop:self.state.page - 2];
        [self loadRest:self.state.page];
        [self loadRest:self.state.page + 1];
#else
        if (self.state.direction == ImageDirectionL2R) {
            if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page)]) {
                [self loadTop:self.state.page];
                [self loadTop:self.state.page + 1];
                [self loadRest:self.state.page];
                [self loadRest:self.state.page + 1];
            } else {
                [self loadTop:self.state.page];
                [self loadRest:self.state.page];
            }
        } else {
            if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page - 1)]) {
                [self loadTop:self.state.page - 1];
                [self loadTop:self.state.page];
                [self loadRest:self.state.page - 1];
                [self loadRest:self.state.page];
            } else {
                [self loadTop:self.state.page];
                [self loadRest:self.state.page];
            }
        }
#endif
    } else {
#ifdef PRELOAD
        [self loadTop:self.state.page];
        [self loadTop:self.state.page + 1];
        [self loadTop:self.state.page - 1];
        [self loadRest:self.state.page];
#else
        if ([OrientationUtil isIPhone]) {
            [self loadTop:self.state.page];
            [self loadTop:self.state.page + 1];
            [self loadTop:self.state.page - 1];
            [self loadRest:self.state.page];
        } else {
            [self loadTop:self.state.page];
            [self loadRest:self.state.page];
        }
#endif
    }
}

- (void)refreshPageLoadingView {
    NSObject* p = AT([[LocalProviderUtil imageInfo:self.state.docId] toPortraitPage:[LocalProviderUtil info:self.state.docId]], self.state.page);
    
    self.pageLoadingView.hidden = p == [NSNull null] || [LocalProviderUtil isAllTopImageExists:self.state.docId page:((NSNumber *)p).intValue];
}

- (void)confirmRestoreLastOpenedPage {
    if ([LocalProviderUtil lastOpenedPage:self.state.docId] != -1) {
        UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"confirm", nil) message:NSLocalizedString(@"restore_confirm_dialog_message", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil), nil] autorelease];
        alert.tag = CONFIRM_RESTORE_LAST_OPENED_PAGE_TAG;
        [alert show];
    }
}

- (void)showView {
#ifdef DebugLogLevelDebug
    NSLog(@"showView begin");
#endif
    [self setupGL];
    [self prepareData];
    
    self.gestureRecognizerView.delegate = self;
    
    [self refreshPageLoadingView];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
#ifdef DebugLogLevelDebug
            NSLog(@"Begin additional loading");
#endif
            // toc
            [self loadTOC];
            [self.tocTableView reloadData];
            
            // bookmark
            [self loadBookmarks];
            [self.bookmarkTableView reloadData];
            
            [self bindConfig];
#ifdef DebugLogLevelDebug
            NSLog(@"End additional loading");
#endif
        }
    });
    
#ifdef DebugLogLevelDebug
    NSLog(@"showView end");
#endif
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.state = [[[ImageState alloc] init] autorelease];
        self.state.loader = self;
        self.state.pageChangeListener = self;
        self.state.pageChanger = self;
        self.state.moviePresenter = self;
        
        self.renderEngine = [[[ImageRenderEngine alloc] init] autorelease];
        self.renderEngine.mod = [OrientationUtil isSpreadMode] ? 4 : 3;
        self.executor = [[[NSOperationQueue alloc] init] autorelease];
        self.executor.maxConcurrentOperationCount = 1;
        [self.executor setSuspended:YES];
        self.bindQueue = [NSMutableArray array];
        self.unbindQueue = [NSMutableArray array];
        self.initialized = NO;
        self.currentMenuView = nil;
        self.thumbnailSize = CGSizeMake(190, 190);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMoviePlayerDidExitFullscreen:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMoviePlayerWillExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMoviePlayerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMovieNaturalSizeAvailable:) name:MPMovieNaturalSizeAvailableNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    NSError* err = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CONFIG_CHANGED object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_COMPLETE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_TEXTURE_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_ANNOTATION_PROGRESS object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieNaturalSizeAvailableNotification object:nil];

    for (LoadImageTask* task in self.executor.operations) {
        task.abort = YES;
    }
    [self.executor cancelAllOperations];
    [self.executor waitUntilAllOperationsAreFinished];
    
    if (self.permitType == DownloaderPermitTypeSample) {
        if ([LocalProviderUtil isCompleted:self.state.docId]) {
            [[NSFileManager defaultManager] removeItemAtPath:[FileUtil fullPath:[LocalPathUtil docDir:self.state.docId]] error:&err];
            if (err) {
                NSLog(@"Error: %@", err);
                assert(0);
            }
        } else if([[[Downloader instance] list] containsObject:self.state.docId]) {
            // this condition for downloading error
            [[Downloader instance] removeItem:self.state.docId];
        }
    }
    
    self.gestureRecognizerView = nil;
    self.pageLoadingView = nil;
    self.menuView = nil;
    self.pageInfoLabel = nil;
    self.toggleBookmarkButton = nil;
    self.menuButtonsView = nil;
    self.menuLabelsView = nil;
    self.thumbnailButton = nil;
    self.tocButton = nil;
    self.bookmarkButton = nil;
    self.configButton = nil;
    self.thumbnailView = nil;
    self.tocView = nil;
    self.bookmarkView = nil;
    self.configView = nil;
    self.configOtherView = nil;
    self.readingDirectionHorizontalButton = nil;
    self.readingDirectionVerticalButton = nil;
    self.rotationLockLabel = nil;
    self.rotationLockSwitch = nil;
    self.brightnessSlider = nil;
    self.hideMenuButton = nil;
    self.progressHolder = nil;
    self.progressView = nil;
    self.brightnessView = nil;
    
    self.thumbnailFlowCoverView = nil;
    self.thumbnailPageLabel = nil;
    self.thumbnailPageSlider = nil;
    
    self.tocTableView = nil;
    
    self.bookmarkTableView = nil;
    
    self.state = nil;
    self.renderEngine = nil;
    self.executor = nil;
    self.bindQueue = nil;
    self.unbindQueue = nil;
    self.currentMenuView = nil;
    self.toc = nil;
    self.bookmarks = nil;
    self.toPortraitPage = nil;
    self.moviePlayer = nil;
    
    [super dealloc];
}

- (void)adjustStaticMenu:(UIInterfaceOrientation)orientation {
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        CGRectSetHeight(self.menuButtonsView.frame, 81 /* self.menuButtonsView.frame.size.height */);
        
        CGRectSetHeight(self.configView.frame, 205 /* self.configReadingDirectionView.frame.size.height */);

        self.menuLabelsView.alpha = 1;
        
        float offset = (self.view.bounds.size.width - 320) / 2;
        
        CGRectSetX(self.configOtherView.frame, offset);
        CGRectSetX(self.rotationLockLabel.frame, offset + 30);
        CGRectSetY(self.rotationLockLabel.frame, 146);
        CGRectSetX(self.rotationLockSwitch.frame, offset + 174);
        CGRectSetY(self.rotationLockSwitch.frame, 143);
        
        self.progressHolder.alpha = 1;
        CGRectSetHeight(self.thumbnailView.frame, self.progressHolder.frame.origin.y - self.thumbnailView.frame.origin.y - self.menuButtonsView.frame.size.height);
        CGRectSetHeight(self.tocView.frame, self.progressHolder.frame.origin.y - self.tocView.frame.origin.y - self.menuButtonsView.frame.size.height);
        CGRectSetHeight(self.bookmarkView.frame, self.progressHolder.frame.origin.y - self.bookmarkView.frame.origin.y - self.menuButtonsView.frame.size.height);
    } else {
        // 25 is ad-hoc value
        CGRectSetHeight(self.menuButtonsView.frame, 56 /* self.menuButtonsView.frame.size.height - 25 */);
        
        CGRectSetHeight(self.configView.frame, 168 /* self.configReadingDirectionView.frame.size.height - self.rotationLockSwitch.frame.size.height - 10 */);

        self.menuLabelsView.alpha = 0;
        
        float offset = (self.view.bounds.size.width - 480) / 2;
        
        CGRectSetX(self.configOtherView.frame, offset);
        CGRectSetX(self.rotationLockLabel.frame, offset + 320 + (160 - self.rotationLockLabel.frame.size.width) / 2);
        // 10 for padding
        CGRectSetY(self.rotationLockLabel.frame, (self.configOtherView.frame.size.height - self.rotationLockLabel.frame.size.height - 10 - self.rotationLockSwitch.frame.size.height) / 2);
        CGRectSetX(self.rotationLockSwitch.frame, offset + 320 + (160 - self.rotationLockSwitch.frame.size.width) / 2);
        CGRectSetY(self.rotationLockSwitch.frame, (self.configOtherView.frame.size.height + self.rotationLockLabel.frame.size.height + 10 - self.rotationLockSwitch.frame.size.height) / 2);
        
        self.progressHolder.alpha = 0;
        CGRectSetHeight(self.thumbnailView.frame, self.view.bounds.size.height - self.thumbnailView.frame.origin.y - self.menuButtonsView.frame.size.height);
        CGRectSetHeight(self.tocView.frame, self.view.bounds.size.height - self.tocView.frame.origin.y - self.menuButtonsView.frame.size.height);
        CGRectSetHeight(self.bookmarkView.frame, self.view.bounds.size.height - self.bookmarkView.frame.origin.y - self.menuButtonsView.frame.size.height);
    }
    
    if (self.currentMenuView) {
        CGRectSetY(self.menuButtonsView.frame, self.currentMenuView.frame.origin.y + self.currentMenuView.frame.size.height);
    }
    
    CGRectSetHeight(self.menuButtonsView.superview.frame, self.menuButtonsView.frame.origin.y + self.menuButtonsView.frame.size.height);
    CGRectSetY(self.hideMenuButton.frame, self.menuButtonsView.superview.frame.origin.y + self.menuButtonsView.superview.frame.size.height);
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        CGRectSetHeight(self.hideMenuButton.frame, self.progressHolder.frame.origin.y - self.hideMenuButton.frame.origin.y);
    } else {
        CGRectSetHeight(self.hideMenuButton.frame, self.view.frame.size.height - self.hideMenuButton.frame.origin.y);
    }
}

- (void)viewDidLoad {
#ifdef DebugLogLevelDebug
    NSLog(@"viewDidLoad begin");
#endif
    [super viewDidLoad];
    
    [self applyBrightness];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConfigChanged:) name:CONFIG_CHANGED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [(EAGLView *)self.view setRendererDelegate:self];
    
    if ([LocalProviderUtil isCompleted:self.state.docId]) {
        self.downloadCompleted = YES;
        self.progressHolder.hidden = YES;
    } else {
        self.downloadCompleted = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDownloaderProgress:) name:DOWNLOADER_PROGRESS object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDownloaderComplete:) name:DOWNLOADER_COMPLETE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDownloaderTextureProgress:) name:DOWNLOADER_TEXTURE_PROGRESS object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDownloaderAnnotationProgress:) name:DOWNLOADER_ANNOTATION_PROGRESS object:nil];
    }
    
    [self.thumbnailFlowCoverView setContext:((EAGLView *)self.view).renderer.context];
    
    [self performSelector:@selector(confirmRestoreLastOpenedPage) withObject:nil afterDelay:0.5];
#ifdef DebugLogLevelDebug
    NSLog(@"viewDidLoad end");
#endif
}

- (void)updateMemoryUsage {
    self.memoryView.text = [NSString stringWithFormat:@"free memory:%dMB, current task:%dMB", [self get_free_memory] / 1024 / 1024, [self get_resident_size] / 1024 / 1024 ];
}

- (void)viewWillAppear:(BOOL)animated {
#ifdef DebugLogLevelDebug
    NSLog(@"viewWillAppear begin");
#endif
    [super viewWillAppear:animated];

    if (!self.initialized) {
        self.initialized = YES;

        [self showView];
        self.toPortraitPage = [self.state.image toPortraitPage:[LocalProviderUtil info:self.state.docId]];
        [self prepareGL];
    } else {
        [self.renderEngine cleanup];
        [self prepareGL];
        
        if ([OrientationUtil isSpreadMode]) {
            if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page)] && self.state.direction == ImageDirectionR2L) {
                self.state.page++;
            } else if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page - 1)] && self.state.direction == ImageDirectionL2R) {
                self.state.page--;
            }
        }
    }
    
    [self adjustStaticMenu:[UIApplication sharedApplication].statusBarOrientation];
    
    [(EAGLView *)self.view startAnimation];
#ifdef DebugLogLevelDebug
    NSLog(@"viewWillAppear end");
#endif
}

- (void)viewDidAppear:(BOOL)animated {
#ifdef DebugLogLevelDebug
    NSLog(@"viewDidAppear begin");
#endif
    [super viewDidAppear:animated];
#ifdef DebugLogLevelDebug
    NSLog(@"viewDidAppear end");
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    [(EAGLView *)self.view stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.renderEngine.suspend = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.toPortraitPage = [self.state.image toPortraitPage:[LocalProviderUtil info:self.state.docId]];
    
    self.state.maxLevel = [ImageLevelUtil maxLevel:self.state.minLevel imageMaxLevel:self.state.image.maxLevel imageMaxNumberOfLevel:self.state.image.maxNumberOfLevel];
    
    // reduce level for memory
    if ([OrientationUtil isSpreadMode] && self.state.maxLevel > self.state.minLevel) {
        self.state.maxLevel--;
    }
    
    self.state.spreadFirstPages = [[LocalProviderUtil info:self.state.docId] firstPages:self.state.image];
    
    if ([OrientationUtil isSpreadMode]) {
        if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page)] && self.state.direction == ImageDirectionR2L) {
            self.state.page++;
        } else if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page - 1)] && self.state.direction == ImageDirectionL2R) {
            self.state.page--;
        }
    }

    self.renderEngine.mod = [OrientationUtil isSpreadMode] ? 4 : 3;
    [self.renderEngine cleanup];
    [self prepareGL];
    
    [self.thumbnailFlowCoverView invalidateCache];
    [self.thumbnailFlowCoverView draw];

    [self loadTOC];
    [self.tocTableView reloadData];
    [self.bookmarkTableView reloadData];
    
    self.renderEngine.suspend = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return [ConfigProvider shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self adjustStaticMenu:toInterfaceOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
#ifdef DebugLogLevelDebug
    NSLog(@"didReceiveMemoryWarning");
#endif 
}

- (BOOL)isInMenu {
    return self.menuView.alpha > 0;
}

- (LoadImageTask *)applyPriority:(LoadImageTask *)task page:(int)page {
    if (task.level == self.state.minLevel) {
        if (task.page == page) {
            task.queuePriority = NSOperationQueuePriorityVeryHigh;
        } else {
            task.queuePriority = NSOperationQueuePriorityHigh;
        }
    } else {
        if (task.page == page) {
            task.queuePriority = NSOperationQueuePriorityNormal;
        } else {
            task.queuePriority = NSOperationQueuePriorityLow;
        }
    }

    return task;
}

- (int)thumbnailLeftOriginPosition:(int)page {
    return self.state.direction == ImageDirectionL2R ? page : (self.state.pages - 1 - page);
}

- (void)setThumbnailLabels:(int)index {
    self.thumbnailPageLabel.text = [NSString stringWithFormat:@"%d / %d", index + 1, self.state.pages];
}

#pragma mark public

- (IBAction)toggleBookmarkButtonClick  {
    NSMutableArray* newBookmarks = [NSMutableArray arrayWithArray:[LocalProviderUtil bookmark:self.state.docId]];
    
    BookmarkInfo* info = [BookmarkInfo info:AT_AS([self.state.image toSpreadPage:[LocalProviderUtil info:self.state.docId]], self.state.page, NSNumber).intValue comment:NSLocalizedString(@"bookmark_no_comment", nil)];
    
    if ([newBookmarks containsObject:info]) {
        [newBookmarks removeObject:info];
    } else {
        [newBookmarks addObject:info];
        [newBookmarks sortUsingComparator:^(id x, id y) {
            BookmarkInfo* bx = x;
            BookmarkInfo* by = y;
            
            return bx.page == by.page ? NSOrderedSame : (bx.page < by.page ? NSOrderedAscending : NSOrderedDescending);
        }];
    }
    
    [LocalProviderUtil setBookmark:self.state.docId bookmark:newBookmarks];
    
    [self bindMenuInfo];
    
    [self loadBookmarks];
    [self.bookmarkTableView reloadData];
}

- (void)changeMenuView:(UIView *)v {
    if (self.currentMenuView == v) {
        return;
    }
    
    void (^proc)(BOOL) = ^(BOOL finished){
        [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.currentMenuView = v;
            
            CGRectSetY(self.menuButtonsView.frame, v.frame.origin.y + v.frame.size.height);
            
            CGRectSetHeight(self.menuButtonsView.superview.frame, self.menuButtonsView.frame.origin.y + self.menuButtonsView.frame.size.height);
            
            CGRectSetY(self.hideMenuButton.frame, self.menuButtonsView.superview.frame.origin.y + self.menuButtonsView.superview.frame.size.height);
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                CGRectSetHeight(self.hideMenuButton.frame, self.progressHolder.frame.origin.y - self.hideMenuButton.frame.origin.y);
            } else {
                CGRectSetHeight(self.hideMenuButton.frame, self.view.frame.size.height - self.hideMenuButton.frame.origin.y);
            }
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                v.alpha = 1;
            } completion:^(BOOL finished){
            }];
        }];
    };

    if (self.currentMenuView) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.currentMenuView setAlpha:0];
        } completion:proc];
    } else {
        proc(NO);
    }
}

- (IBAction)thumbnailButtonClick {
    [self changeMenuView:self.thumbnailView];
    [self.thumbnailButton setImage:[UIImage imageNamed:@"button_thumbnail_selected"] forState:UIControlStateNormal];
    [self.tocButton setImage:[UIImage imageNamed:@"button_toc"] forState:UIControlStateNormal];
    [self.bookmarkButton setImage:[UIImage imageNamed:@"button_bookmark"] forState:UIControlStateNormal];
    [self.configButton setImage:[UIImage imageNamed:@"button_config"] forState:UIControlStateNormal];
}

- (IBAction)tocButtonClick {
    [self changeMenuView:self.tocView];
    [self.thumbnailButton setImage:[UIImage imageNamed:@"button_thumbnail"] forState:UIControlStateNormal];
    [self.tocButton setImage:[UIImage imageNamed:@"button_toc_selected"] forState:UIControlStateNormal];
    [self.bookmarkButton setImage:[UIImage imageNamed:@"button_bookmark"] forState:UIControlStateNormal];
    [self.configButton setImage:[UIImage imageNamed:@"button_config"] forState:UIControlStateNormal];
}

- (IBAction)bookmarkButtonClick {
    [self changeMenuView:self.bookmarkView];
    [self.thumbnailButton setImage:[UIImage imageNamed:@"button_thumbnail"] forState:UIControlStateNormal];
    [self.tocButton setImage:[UIImage imageNamed:@"button_toc"] forState:UIControlStateNormal];
    [self.bookmarkButton setImage:[UIImage imageNamed:@"button_bookmark_selected"] forState:UIControlStateNormal];
    [self.configButton setImage:[UIImage imageNamed:@"button_config"] forState:UIControlStateNormal];
}

- (IBAction)configButtonClick {
    [self changeMenuView:self.configView];
    [self.thumbnailButton setImage:[UIImage imageNamed:@"button_thumbnail"] forState:UIControlStateNormal];
    [self.tocButton setImage:[UIImage imageNamed:@"button_toc"] forState:UIControlStateNormal];
    [self.bookmarkButton setImage:[UIImage imageNamed:@"button_bookmark"] forState:UIControlStateNormal];
    [self.configButton setImage:[UIImage imageNamed:@"button_config_selected"] forState:UIControlStateNormal];
}

- (IBAction)brightnessChanged {
    float brightness = 0.8 * self.brightnessSlider.value + 0.2;
    
    [ConfigProvider setBrightness:brightness];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CONFIG_CHANGED object:nil];
}

- (IBAction)zoomSizeNormalClick {
    [self.state changeScaleToOrigin:NO];
}

- (IBAction)zoomSizeDoubleClick {
    [self.state changeScaleToOrigin:YES];
}

- (IBAction)readingDirectionHorizontalClick {
    [ConfigProvider setReadingDirection:ConfigProviderReadingDirectionHorizontal];
    
    [self bindConfig];
}

- (IBAction)readingDirectionVerticalClick {
    [ConfigProvider setReadingDirection:ConfigProviderReadingDirectionVertical];
    
    [self bindConfig];
}

- (IBAction)rotationLockChanged {
    if (self.rotationLockSwitch.isOn) {
        [ConfigProvider setOrientationByUIInterfaceOrientation:self.interfaceOrientation];
    } else {
        [ConfigProvider setOrientationAsFree];
    }
}

- (IBAction)backClick {
    UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"confirm", nil) message:NSLocalizedString(@"finish_confirm_dialog_message", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil), nil] autorelease];
    alert.tag = CONFIRM_FINISH_TAG;
    [alert show];
}

- (IBAction)hideMenuClick {
    [self.view endEditing:YES];

    [UIView animateWithDuration:0.2 animations:^{
        self.menuView.alpha = 0;
    }];
}

- (void)setParams:(NSString* )docId permitType:(DownloaderPermitType)aPermitType {
    self.state.docId = docId;
    self.permitType = aPermitType;
}

- (void)bindMenuInfo {
    self.pageInfoLabel.text = [NSString stringWithFormat:@"%@ ( %d / %d page )", [LocalProviderUtil tocText:self.state.docId page:self.state.page], self.state.page + 1, self.state.pages];
    
    NSArray* toSpread = [self.state.image toSpreadPage:[LocalProviderUtil info:self.state.docId]];
    NSString* bookmarkImageName = [[LocalProviderUtil bookmark:self.state.docId] containsObject:[BookmarkInfo info:AT_AS(toSpread, self.state.page, NSNumber).intValue comment:nil]] ? @"button_bookmark_on" : @"button_bookmark_off";
    [self.toggleBookmarkButton setImage:[UIImage imageNamed:bookmarkImageName] forState:UIControlStateNormal];
}

- (IBAction)thumbnailPageSliderChanged {
    int cover = floor(self.thumbnailPageSlider.value + 0.5);
    
    if (cover != self.thumbnailFlowCoverView.offset) {
        self.thumbnailFlowCoverView.offset = cover;
        [self.thumbnailFlowCoverView draw];
        
        [self setThumbnailLabels:[self thumbnailLeftOriginPosition:cover]];
    }
}

#pragma mark PageChanger

- (void)changePage:(int)page refresh:(BOOL)refresh {
    if (refresh) {
        if ([OrientationUtil isSpreadMode]) {
#ifdef PRELOAD
            [self unloadTop:self.state.page];
            [self unloadTop:self.state.page + 1];
            [self unloadTop:self.state.page + 2];
            [self unloadTop:self.state.page + 3];
            [self unloadTop:self.state.page - 1];
            [self unloadTop:self.state.page - 2];
            [self unloadRest:self.state.page];
            [self unloadRest:self.state.page + 1];
#else
            if (self.state.direction == ImageDirectionL2R) {
                if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page)]) {
                    [self unloadTop:self.state.page];
                    [self unloadTop:self.state.page + 1];
                    [self unloadRest:self.state.page];
                    [self unloadRest:self.state.page + 1];
                } else {
                    [self unloadTop:self.state.page];
                    [self unloadRest:self.state.page];
                }
            } else {
                if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page - 1)]) {
                    [self unloadTop:self.state.page - 1];
                    [self unloadTop:self.state.page];
                    [self unloadRest:self.state.page - 1];
                    [self unloadRest:self.state.page];
                } else {
                    [self unloadTop:self.state.page];
                    [self unloadRest:self.state.page];
                }
            }
#endif
        } else {
#ifdef PRELOAD
            [self unloadTop:self.state.page];
            [self unloadTop:self.state.page + 1];
            [self unloadTop:self.state.page - 1];
            [self unloadRest:self.state.page];
#else
            if ([OrientationUtil isIPhone]) {
                [self unloadTop:self.state.page];
                [self unloadTop:self.state.page + 1];
                [self unloadTop:self.state.page - 1];
                [self unloadRest:self.state.page];
            } else {
                [self unloadTop:self.state.page];
                [self unloadRest:self.state.page];
            }
#endif
        }
    }
    
    self.state.page = page;
    
    if (refresh) {
        if ([OrientationUtil isSpreadMode]) {
#ifdef PRELOAD
            [self loadTop:self.state.page];
            [self loadTop:self.state.page + 1];
            [self loadTop:self.state.page + 2];
            [self loadTop:self.state.page + 3];
            [self loadTop:self.state.page - 1];
            [self loadTop:self.state.page - 2];
            [self loadRest:self.state.page];
            [self loadRest:self.state.page + 1];
#else
            if (self.state.direction == ImageDirectionL2R) {
                if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page)]) {
                    [self loadTop:self.state.page];
                    [self loadTop:self.state.page + 1];
                    [self loadRest:self.state.page];
                    [self loadRest:self.state.page + 1];
                } else {
                    [self loadTop:self.state.page];
                    [self loadRest:self.state.page];
                }
            } else {
                if ([self.state.spreadFirstPages containsObject:NUM_I(self.state.page - 1)]) {
                    [self loadTop:self.state.page - 1];
                    [self loadTop:self.state.page];
                    [self loadRest:self.state.page - 1];
                    [self loadRest:self.state.page];
                } else {
                    [self loadTop:self.state.page];
                    [self loadRest:self.state.page];
                }
            }
#endif
        } else {
#ifdef PRELOAD
            [self loadTop:self.state.page];
            [self loadTop:self.state.page + 1];
            [self loadTop:self.state.page - 1];
            [self loadRest:self.state.page];
#else
            if ([OrientationUtil isIPhone]) {
                [self loadTop:self.state.page];
                [self loadTop:self.state.page + 1];
                [self loadTop:self.state.page - 1];
                [self loadRest:self.state.page];
            } else {
                [self loadTop:self.state.page];
                [self loadRest:self.state.page];
            }
#endif
        }
    }
    
    [self bindMenuInfo];
    
    [LocalProviderUtil setLastOpenedPage:self.state.docId page:page];

    self.menuView.alpha = 0;
}

#pragma mark ConfigProvider Nofitifaction

- (void)onConfigChanged:(NSNotification *)notification {
    [self applyBrightness];
}

#pragma mark Downloader Notification

- (void)onDownloaderComplete:(NSNotification *)notification {
    if ([self.state.docId compare:notification.object] != NSOrderedSame) {
        return;
    }
    
    self.downloadCompleted = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_PROGRESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOWNLOADER_COMPLETE object:nil];
 
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressHolder.hidden = YES;
        
        [self.thumbnailFlowCoverView invalidateCache];
        [self.thumbnailFlowCoverView draw];

        // toc
        [self loadTOC];
        [self.tocTableView reloadData];
        
        // bookmark
        [self loadBookmarks];
        [self.bookmarkTableView reloadData];
    });
}

// TODO: Confirm behavior on suspend
- (void)onDownloaderProgress:(NSNotification *)notification {
    if (![self.state.docId isEqualToString:notification.object]) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = FOR_F(notification.userInfo, @"progress");
    });
}

- (void)onDownloaderTextureProgress:(NSNotification *)notification {
    if (![self.state.docId isEqualToString:notification.object]) {
        return;
    }
    
    NSDictionary* dic = notification.userInfo;
    int page = FOR_I(dic, @"page");
    int level = FOR_I(dic, @"level");
    int px = FOR_I(dic, @"px");
    int py = FOR_I(dic, @"py");
    
    if (abs(page - self.state.page) <= 1 && level <= self.state.maxLevel) {
        [self.executor addOperation:[LoadImageTask taskWithParam:self.state.docId page:page level:level px:px py:py isWebp:self.state.image.isWebp pageHolder:self.state binder:self threshold:[OrientationUtil isSpreadMode] ? 4 : 2]];
    }
    
    __block id this = [self retain];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshPageLoadingView];
        [this release];
    });
}

- (void)onDownloaderAnnotationProgress:(NSNotification *)notification {
    if (![self.state.docId isEqualToString:notification.object]) {
        return;
    }
    
    // TODO page aware
    // NSDictionary* dic = notification.userInfo;
    // int page = FOR_I(dic, @"page");

    [self.state loadOverlay];
}

#pragma mark GestureRecognizerDelegate

- (void)onScale:(float)scale focus:(CGPoint)focus {
    [self.state zoom:scale focus:[self convertCGPoint:focus]];
}

- (void)onScroll:(CGPoint)distance {
    [self.state drag:[self convertCGPoint:distance]];
}

- (void)onSingleTap:(CGPoint)point {
#ifdef DebugLogLevelDebug
    NSLog(@"singleTap: %@", NSStringFromCGPoint(point));
#endif
    
    if ([self.state tap:[self convertCGPoint:point]]) {
        [UIView animateWithDuration:0.2 animations:^{
            self.menuView.alpha = 1;
        }];
        
        // thumbnail
        self.thumbnailFlowCoverView.offset = [self thumbnailLeftOriginPosition:self.state.page];
        [self.thumbnailFlowCoverView draw];
        
        self.thumbnailPageSlider.minimumValue = 0.0;
        self.thumbnailPageSlider.maximumValue = self.state.pages - 1.0;
        self.thumbnailPageSlider.value = [self thumbnailLeftOriginPosition:self.state.page];
        
        [self setThumbnailLabels:self.state.page];
    }
}

- (void)onDoubleTap:(CGPoint)point {
    [self.state doubleTap:[self convertCGPoint:point]];
}

- (void)onLongPress {
}

- (void)onFling:(CGPoint)velocity {
    [self.state fling:[self convertCGPoint:velocity]];
}

- (void)onTouchBegin {
    self.state.isInteracting = YES;
}

- (void)onTouchEnd {
    self.state.isInteracting = NO;
}

#pragma mark PageLoader

- (void)loadTop:(int)page {
    if (page < 0 || page >= self.state.pages) {
        return;
    }
    
    if (AT(self.toPortraitPage, page) == [NSNull null]) {
        return;
    }
    
    NSArray* dimen = [self.renderEngine textureDimension:page];
#ifdef REDUCE_TEXTURE
    int level = self.state.minLevel;
#else
    for (int level = self.state.minLevel; level <= self.state.maxLevel; level++) {
#endif
    for (int py = 0; py < AT2_AS(dimen, level - self.state.minLevel, 1, NSNumber).intValue; py++) {
        for (int px = 0; px < AT2_AS(dimen, level - self.state.minLevel, 0, NSNumber).intValue; px++ ) {
            [self.executor addOperation:[self applyPriority:[LoadImageTask taskWithParam:self.state.docId page:page level:level px:px py:py isWebp:self.state.image.isWebp pageHolder:self.state binder:self threshold:[OrientationUtil isSpreadMode] ? 4 : 2] page:self.state.page]];
        }
    }
#ifndef REDUCE_TEXTURE
    }
#endif
}

- (void)loadRest:(int)page {
#ifdef REDUCE_TEXTURE
    if (page < 0 || page >= self.state.pages) {
        return;
    }
    
    if (AT(self.toPortraitPage, page) == [NSNull null]) {
        return;
    }
    
    NSArray* dimen = [self.renderEngine textureDimension:page];
    for (int level = self.state.minLevel + 1; level <= self.state.maxLevel; level++) {
        for (int py = 0; py < AT2_AS(dimen, level - self.state.minLevel, 1, NSNumber).intValue; py++) {
            for (int px = 0; px < AT2_AS(dimen, level - self.state.minLevel, 0, NSNumber).intValue; px++ ) {
                [self.executor addOperation:[self applyPriority:[LoadImageTask taskWithParam:self.state.docId page:page level:level px:px py:py isWebp:self.state.image.isWebp pageHolder:self.state binder:self threshold:[OrientationUtil isSpreadMode] ? 4 : 2] page:self.state.page]];
            }
        }
    }
#endif
}

- (void)unloadTop:(int)page {
    if (page < 0 || page >= self.state.pages) {
        return;
    }
    
    if (AT(self.toPortraitPage, page) == [NSNull null]) {
        return;
    }
    
    NSArray* dimen = [self.renderEngine textureDimension:page];
#ifdef REDUCE_TEXTURE
    for (LoadImageTask* task in self.executor.operations) {
        if (task.page == page && task.level == self.state.minLevel) {
            task.abort = YES;
        }
    }
    
    @synchronized(self.bindQueue) {
        for (BindQueueItem* item in self.bindQueue) {
            if (item.page == page && item.level == self.state.minLevel) {
                free(item.data);
                item.data = nil;
                [self.bindQueue removeObject:item];
            }
        }
    }
    
    int level = self.state.minLevel;
#else
    for (LoadImageTask* task in self.executor.operations) {
        if (task.page == page) {
            task.abort = YES;
        }
    }
    
    @synchronized(self.bindQueue) {
        for (BindQueueItem* item in self.bindQueue) {
            if (item.page == page) {
                free(item.data);
                item.data = nil;
                [self.bindQueue removeObject:item];
            }
        }
    }
    
    for (int level = self.state.minLevel; level <= self.state.maxLevel; level++) {
#endif
    for (int py = 0; py < AT2_AS(dimen, level - self.state.minLevel, 1, NSNumber).intValue; py++) {
        for (int px = 0; px < AT2_AS(dimen, level - self.state.minLevel, 0, NSNumber).intValue; px++ ) {
            UnbindQueueItem* item = [UnbindQueueItem itemWithParam:page level:level px:px py:py];
            
            @synchronized(self.unbindQueue) {
                [self.unbindQueue addObject:item];
            }
        }
    }
#ifndef REDUCE_TEXTURE
    }
#endif
}

- (void)unloadRest:(int)page {
#ifdef REDUCE_TEXTURE
    if (page < 0 || page >= self.state.pages) {
        return;
    }
    
    if (AT(self.toPortraitPage, page) == [NSNull null]) {
        return;
    }
    
    for (LoadImageTask* task in self.executor.operations) {
        if (task.page == page && task.level != self.state.minLevel) {
            task.abort = YES;
        }
    }

    @synchronized(self.bindQueue) {
        for (BindQueueItem* item in self.bindQueue) {
            if (item.page == page && item.level != self.state.minLevel) {
                free(item.data);
                item.data = nil;
                [self.bindQueue removeObject:item];
            }
        }
    }

    NSArray* dimen = [self.renderEngine textureDimension:page];
    for (int level = self.state.minLevel + 1; level <= self.state.maxLevel; level++) {
        for (int py = 0; py < AT2_AS(dimen, level - self.state.minLevel, 1, NSNumber).intValue; py++) {
            for (int px = 0; px < AT2_AS(dimen, level - self.state.minLevel, 0, NSNumber).intValue; px++ ) {
                UnbindQueueItem* item = [UnbindQueueItem itemWithParam:page level:level px:px py:py];
                
                @synchronized(self.unbindQueue) {
                    [self.unbindQueue addObject:item];
                }
            }
        }
    }
#endif
}

#pragma mark TextureBinder

- (void)bind:(BindQueueItem *)item {
    @synchronized(self.bindQueue) {
        [self.bindQueue addObject:item];
    }
}

#pragma mark PageChangeListener

- (void)pageChange:(int)page {
    [self bindMenuInfo];
    
    for (LoadImageTask* task in self.executor.operations) {
        [self applyPriority:task page:page];
    }
    
    [self refreshPageLoadingView];
    
    [LocalProviderUtil setLastOpenedPage:self.state.docId page:page];
}

#pragma mark MoviePresenter

- (BOOL)isMovieAvailable:(NSURL *)url {
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:url];
    
    request.requestMethod = @"HEAD";
    request.timeOutSeconds = 3;
    
    [request startSynchronous];

    int sc = request.responseStatusCode;
    if (sc != 200 || request.error) {
        NSLog(@"statusCode: %d, statusMessage: %@, error: %@, url: %@", sc, request.responseStatusMessage, request.error, url);
        NSLog(@"body: %@", request.responseString);
        return NO;
    }
    
    return YES;
}

- (void)showMovie:(ImageAnnotationInfo *)info {
    NSURL* url = [NSURL URLWithString:((MovieAnnotationInfo *)info.annotation).target];
    
    if (![self isMovieAvailable:url]) {
        [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", nil) message:NSLocalizedString(@"message_error_cannot_play_movie", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] autorelease] show];
        return;
    }
    
    self.moviePlayer = [[[MPMoviePlayerController alloc] initWithContentURL:url] autorelease];
    
    self.moviePlayer.view.frame = [self invertCGRect:info.frame];
    [self.view addSubview:self.moviePlayer.view];
    
    [self.moviePlayer setFullscreen:YES animated:TRUE];
    [self.moviePlayer play];
    
    self.orientationOnEnterMovie = [UIApplication sharedApplication].statusBarOrientation;
}

#pragma mark MPMoviePlayerController notification

- (void)onMoviePlayerWillExitFullscreen:(NSNotification *)notification {
    UIInterfaceOrientation o = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UIInterfaceOrientationIsPortrait(o) != UIInterfaceOrientationIsPortrait(self.orientationOnEnterMovie)) {
        [self willRotateToInterfaceOrientation:o duration:0];
        [self didRotateFromInterfaceOrientation:self.orientationOnEnterMovie];
    }
}

- (void)onMoviePlayerDidExitFullscreen:(NSNotification *)notification {
    [self.moviePlayer stop];
}

- (void)onMoviePlayerPlaybackDidFinish:(NSNotification *)notification {
    if ([[notification.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue] == MPMovieFinishReasonPlaybackError) {
        [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", nil) message:NSLocalizedString(@"message_error_cannot_play_movie", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] autorelease] show];
    }
    
    [self.moviePlayer.view removeFromSuperview]; // for invalid movie. should find better way though...
    self.moviePlayer = nil;
}

- (void)onMovieNaturalSizeAvailable:(NSNotification *)notification {
    MPMoviePlayerController* mpc = notification.object;
    
    NSLog(@"onMovieNaturalSizeAvailable: naturalSize: %@", NSStringFromCGSize(mpc.naturalSize));
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == CONFIRM_RESTORE_LAST_OPENED_PAGE_TAG) {
        // 0: cancel, 1: restore
        if (buttonIndex == 1) {
            [self changePage:[LocalProviderUtil lastOpenedPage:self.state.docId] refresh:YES];
        }
    } else if (alertView.tag == CONFIRM_FINISH_TAG) {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
            
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark ESRendererDelegate

- (void)performRender {
    if (self.executor.isSuspended) {
        [self.executor setSuspended:NO];
    }
    
    while (self.unbindQueue.count > 0) {
        UnbindQueueItem* item = nil;

        @synchronized(self.unbindQueue) {
            item = [[self.unbindQueue.lastObject retain] autorelease];
            [self.unbindQueue removeLastObject];
        }
        
        [self.renderEngine unbindPageImage:item minLevel:self.state.minLevel];
    }
    
    while (self.bindQueue.count > 0) {
        BindQueueItem* item = nil;
        
        @synchronized(self.bindQueue) {
            item = [[self.bindQueue.lastObject retain] autorelease];
            [self.bindQueue removeLastObject];
        }
        
        if (item.level > self.state.maxLevel || item.page < self.state.page - ([OrientationUtil isSpreadMode] ? 2 : 1) || item.page > self.state.page + ([OrientationUtil isSpreadMode] ? 3 : 1)) {
            free(item.data);
            item.data = nil;
        } else {
            [self.renderEngine bindPageImage:item minLevel:self.state.minLevel];
            break;
        }
    }

    [self.state update];
    
    [self.renderEngine render:self.state];
    
    [self err:@"loop"];
}

#pragma mark FlowCoverViewDelegate

- (int)flowCoverNumberImages:(FlowCoverView *)view {
    return self.state.pages;
}

- (UIImage *)flowCover:(FlowCoverView *)view cover:(int)cover {
    return [self thumbnailImage:[self thumbnailLeftOriginPosition:cover]];
}

- (void)flowCover:(FlowCoverView *)view didSelect:(int)cover {
    int p = [self thumbnailLeftOriginPosition:cover];
    if ([OrientationUtil isSpreadMode]) {
        if ([self.state.spreadFirstPages containsObject:NUM_I(p)] && self.state.direction == ImageDirectionR2L) {
            p++;
        } else if ([self.state.spreadFirstPages containsObject:NUM_I(p - 1)] && self.state.direction == ImageDirectionL2R) {
            p--;
        }
    }
    [self changePage:p refresh:YES];
}

- (void)flowCover:(FlowCoverView *)view didChanged:(int)cover {
    [self setThumbnailLabels:[self thumbnailLeftOriginPosition:cover]];
    
    [self.thumbnailPageSlider setValue:cover animated:YES];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tocTableView) {
        return self.toc.count;
    } else if (tableView == self.bookmarkTableView) {
        return self.bookmarks.count;
    } else {
        assert(0);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return IMAGE_LIST_ITEM_CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    ImageListItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = (ImageListItemCell *)[[[UIViewController alloc] initWithNibName:@"ImageListItemCell" bundle:nil] autorelease].view;
        
        if (tableView == self.bookmarkTableView) {
            cell.textView.userInteractionEnabled = YES;
            cell.textView.delegate = self;
        }
    }
    
    ImageListItemInfo* info = AT(tableView == self.bookmarkTableView ? self.bookmarks : self.toc, indexPath.row);
    
    cell.thumbnailImageView.image = info.thumbnail;
    cell.textView.text = info.text;
    cell.textView.tag = indexPath.row;

    if (tableView == self.bookmarkTableView) {
        NSArray* fromSpread = [self.state.image fromSpreadPage:[LocalProviderUtil info:state.docId]];
        cell.pageLabel.text = [NSString stringWithFormat:@"%d", AT_AS(fromSpread, info.page, NSNumber).intValue + 1];
    } else {
        cell.pageLabel.text = [NSString stringWithFormat:@"%d", info.page + 1];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView == self.bookmarkTableView;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.bookmarkTableView) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSMutableArray* newBookmarks = [NSMutableArray arrayWithArray:[LocalProviderUtil bookmark:self.state.docId]];
            
            [newBookmarks removeObjectAtIndex:indexPath.row];
            
            [LocalProviderUtil setBookmark:self.state.docId bookmark:newBookmarks];
            
            [self loadBookmarks];
            
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
            
            [self bindMenuInfo];
        }   
    }    
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
    
    if (tableView == self.bookmarkTableView) {
        NSArray* fromSpread = [self.state.image fromSpreadPage:[LocalProviderUtil info:state.docId]];
        [self changePage:AT_AS(fromSpread, AT_AS(self.bookmarks, indexPath.row, ImageListItemInfo).page, NSNumber).intValue refresh:YES];
    } else if (tableView == self.tocTableView) {
        [self changePage:AT_AS(self.toc, indexPath.row, ImageListItemInfo).page refresh:YES];
    }
}

#pragma mark UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.lastSelectedBookmarkTextViewIndex = textView.tag;
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    NSArray* bs = [LocalProviderUtil bookmark:self.state.docId];

    AT_AS(bs, textView.tag, BookmarkInfo).comment = textView.text;

    [LocalProviderUtil setBookmark:self.state.docId bookmark:bs];
    
    AT_AS(self.bookmarks, textView.tag, ImageListItemInfo).text = textView.text;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark UIKeyboard Notification

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect frame = [self.view.superview convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil];
    
    [UIView animateWithDuration:0.2 animations:^{
        CGRectSetHeight(self.bookmarkTableView.frame, self.view.frame.size.height - frame.size.height - self.bookmarkView.frame.origin.y);
        
        [self.bookmarkTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.lastSelectedBookmarkTextViewIndex inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    CGRectSetHeight(self.bookmarkTableView.frame, self.bookmarkView.frame.size.height);
}

#import <mach/mach.h>
#import <mach/mach_host.h>

- (natural_t)get_free_memory {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }
    
    natural_t mem_free = vm_stat.free_count * pagesize;
    return mem_free;
}

- (u_int)get_resident_size {
    struct task_basic_info t_info;
    mach_msg_type_number_t t_info_count = TASK_BASIC_INFO_COUNT;
    
    if (task_info(current_task(), TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count)!= KERN_SUCCESS)
    {
        NSLog(@"%s(): Error in task_info(): %s",
              __FUNCTION__, strerror(errno));
    }
    
    u_int rss = t_info.resident_size;
    
    return rss;
}

@end
