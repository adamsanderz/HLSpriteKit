//
//  HLCatalogScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 11/14/14.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import "HLCatalogScene.h"

#import <TargetConditionals.h>

#import "HLSpriteKit.h"

#if ! TARGET_OS_IPHONE
// note: Under macOS, hack into the SKView to forward scroll wheel events
// in order to demonstrate scaling interaction in the HLScrollNode.
@implementation SKView(ScrollWheelForwarding)
- (void)scrollWheel:(NSEvent *)event
{
  [self.scene scrollWheel:event];
}
@end
#endif

@implementation HLCatalogScene
{
  BOOL _contentCreated;
  HLToolbarNode *_applicationToolbarNode;
  HLScrollNode *_catalogScrollNode;
  HLMessageNode *_messageNode;
  HLTiledNode *_tiledNode;
}

- (void)didMoveToView:(SKView *)view
{
  [super didMoveToView:view];

  if (!_contentCreated) {
    [self HL_createContent];
    _contentCreated = YES;
  }

#if TARGET_OS_IPHONE
  NSString *message = @"Scroll and zoom catalog using pan and pinch.";
#else
  NSString *message = @"Scroll catalog using left-click; zoom with scroll-wheel or trackpad pinch.";
#endif
  [self runAction:[SKAction sequence:@[ [SKAction waitForDuration:1.0],
                                        [SKAction runBlock:^{
    [self HL_showMessage:message];
  }] ]]];
}

- (void)didChangeSize:(CGSize)oldSize
{
  [super didChangeSize:oldSize];
  _catalogScrollNode.size = self.size;
  [self HL_layoutApplicationToolbarNode];
}

- (void)update:(NSTimeInterval)currentTime
{
  static NSTimeInterval lastTime = 0.0;
  if (lastTime > 0.0) {
    NSTimeInterval incrementalTime = currentTime - lastTime;
    [_tiledNode hlActionRunnerUpdate:incrementalTime];
  }
  lastTime = currentTime;
}

- (void)setApplicationToolbar:(HLToolbarNode *)applicationToolbarNode
{
  if (_applicationToolbarNode == applicationToolbarNode) {
    return;
  }
  if (_applicationToolbarNode) {
    [_applicationToolbarNode removeFromParent];
  }
  _applicationToolbarNode = applicationToolbarNode;
  if (_applicationToolbarNode) {
    [self addChild:_applicationToolbarNode];
    [self HL_layoutApplicationToolbarNode];
  }
}

- (void)HL_layoutApplicationToolbarNode
{
  _applicationToolbarNode.size = CGSizeMake(self.size.width, 0.0f);
  [_applicationToolbarNode layoutToolsAnimation:HLToolbarNodeAnimationNone];
  _applicationToolbarNode.position = CGPointMake(0.0f, (_applicationToolbarNode.size.height - self.size.height) / 2.0f + 5.0f);
  _applicationToolbarNode.zPosition = 1.0f;
}

- (void)HL_createContent
{
  SKSpriteNode *catalogNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.5f green:0.7f blue:0.9f alpha:1.0f] size:CGSizeZero];
#if TARGET_OS_IPHONE
  NSArray *columnAnchorPoints = @[ [NSValue valueWithCGPoint:CGPointMake(0.5f, 0.5f)] ];
#else
  NSArray *columnAnchorPoints = @[ [NSValue valueWithPoint:NSMakePoint(0.5f, 0.5f)] ];
#endif
  HLTableLayoutManager *catalogLayoutManager = [[HLTableLayoutManager alloc] initWithColumnCount:2
                                                                                    columnWidths:@[ @(0.0f) ]
                                                                              columnAnchorPoints:columnAnchorPoints
                                                                                      rowHeights:@[ @(0.0f) ]];
  catalogLayoutManager.tableBorder = 5.0f;
  catalogLayoutManager.columnSeparator = 15.0f;
  catalogLayoutManager.rowSeparator = 15.0f;
  [catalogNode hlSetLayoutManager:catalogLayoutManager];

  HLMultilineLabelNode *multilineLabelNode = [self HL_createContentMultilineLabelNode];
  // note: Show the label on a solid background to illustrate the size of the multiline label node.
  SKSpriteNode *multilineLabelBackgroundNode = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.65f green:0.8f blue:0.95f alpha:1.0f]
                                                                            size:multilineLabelNode.size];
  [multilineLabelBackgroundNode addChild:multilineLabelNode];
#if TARGET_OS_IPHONE
  [multilineLabelNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped HLMultilineLabelNode."];
  }]];
#else
  [multilineLabelNode hlSetGestureTarget:[HLClickGestureTarget clickGestureTargetWithHandleGestureBlock:^(NSGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Clicked HLMultilineLabelNode."];
  }]];
#endif
  [self needSharedGestureRecognizersForNode:multilineLabelNode];
  [catalogNode addChild:multilineLabelBackgroundNode];

  HLGridNode *gridNode = [self HL_createContentGridNode];
#if TARGET_OS_IPHONE
  gridNode.squareTappedBlock = ^(int squareIndex){
    [self HL_showMessage:[NSString stringWithFormat:@"Tapped HLGridNode squareIndex %d.", squareIndex]];
  };
#else
  gridNode.squareClickedBlock = ^(int squareIndex){
    [self HL_showMessage:[NSString stringWithFormat:@"Clicked HLGridNode squareIndex %d.", squareIndex]];
  };
#endif
  [gridNode hlSetGestureTarget:gridNode];
  [self needSharedGestureRecognizersForNode:gridNode];
  // Alternately, use UIResponder/NSResponder interface with squareTappedBlock/squareClickedBlock:
  //   gridNode.userInteractionEnabled = YES;
  [catalogNode addChild:gridNode];

  HLToolbarNode *toolbarNode = [self HL_createContentToolbarNode];
#if TARGET_OS_IPHONE
  toolbarNode.toolTappedBlock = ^(NSString *toolTag){
    [self HL_showMessage:[NSString stringWithFormat:@"Tapped tool '%@' on HLToolbarNode.", toolTag]];
  };
#else
  toolbarNode.toolClickedBlock = ^(NSString *toolTag){
    [self HL_showMessage:[NSString stringWithFormat:@"Clicked tool '%@' on HLToolbarNode.", toolTag]];
  };
#endif
  [toolbarNode hlSetGestureTarget:toolbarNode];
  [self needSharedGestureRecognizersForNode:toolbarNode];
  // Alternately, use UIResponder/NSResponder interface with toolTappedBlock/toolClickedBlock:
  //   toolbarNode.userInteractionEnabled = YES;
  [catalogNode addChild:toolbarNode];

  _tiledNode = [self HL_createContentTiledNode];
#if TARGET_OS_IPHONE
  [_tiledNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped HLTiledNode."];
  }]];
#else
  [_tiledNode hlSetGestureTarget:[HLClickGestureTarget clickGestureTargetWithHandleGestureBlock:^(NSGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Clicked HLTiledNode."];
  }]];
#endif
  [self needSharedGestureRecognizersForNode:_tiledNode];
  [catalogNode addChild:_tiledNode];
  // Animation depends on hlUpdateActionRunner code in update method.
  [_tiledNode hlRunAction:[HLAction rotateFromAngle:0.0 to:M_PI duration:3.0] withKey:@"rotate"];

  HLLabelButtonNode *labelButtonNode = [self HL_createContentLabelButtonNode];
#if TARGET_OS_IPHONE
  [labelButtonNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Tapped HLLabelButtonNode."];
  }]];
#else
  [labelButtonNode hlSetGestureTarget:[HLClickGestureTarget clickGestureTargetWithHandleGestureBlock:^(NSGestureRecognizer *gestureRecognizer){
    [self HL_showMessage:@"Clicked HLLabelButtonNode."];
  }]];
#endif
  [self needSharedGestureRecognizersForNode:labelButtonNode];
  [catalogNode addChild:labelButtonNode];

  [catalogNode hlLayoutChildren];
  catalogNode.size = catalogLayoutManager.size;

  _catalogScrollNode = [[HLScrollNode alloc] initWithSize:self.size contentSize:catalogLayoutManager.size];
#if TARGET_OS_IPHONE
  _catalogScrollNode.contentInset = UIEdgeInsetsMake(30.0f, 30.0f, 30.0f, 30.f);
#else
  _catalogScrollNode.contentInset = NSEdgeInsetsMake(30.0f, 30.0f, 30.0f, 30.f);
#endif
  _catalogScrollNode.contentScaleMinimum = 0.0f;
  _catalogScrollNode.contentScaleMinimumMode = HLScrollNodeContentScaleMinimumFitLoose;
  _catalogScrollNode.contentScaleMaximum = 3.0f;
  _catalogScrollNode.contentScale = 0.0f;
  _catalogScrollNode.contentNode = catalogNode;
  [_catalogScrollNode hlSetGestureTarget:_catalogScrollNode];
  [self needSharedGestureRecognizersForNode:_catalogScrollNode];
  // Alternately, use UIResponder/NSResponder interface:
  //   _catalogScrollNode.userInteractionEnabled = YES;
  //   self.view.multipleTouchEnabled = YES;
  [self addChild:_catalogScrollNode];
}

#if ! TARGET_OS_IPHONE

- (void)scrollWheel:(NSEvent *)event
{
  NSPoint contentLocation = [event locationInNode:_catalogScrollNode.contentNode];
  CGFloat newContentScale = _catalogScrollNode.contentScale * (1.0f + event.deltaY * 0.02f);
  [_catalogScrollNode pinContentLocation:contentLocation andSetContentScale:newContentScale];
}

#endif

- (HLGridNode *)HL_createContentGridNode
{
  HLGridNode *gridNode = [[HLGridNode alloc] initWithGridWidth:3
                                                   squareCount:10
                                                   anchorPoint:CGPointMake(0.5f, 0.5f)
                                                    layoutMode:HLGridNodeLayoutModeFill
                                                    squareSize:CGSizeMake(24.0f, 24.0f)
                                          backgroundBorderSize:3.0f
                                           squareSeparatorSize:1.0f];
  NSMutableArray *gridContentNodes = [NSMutableArray array];
  for (NSInteger n = 0; n < 10; ++n) {
    SKLabelNode *contentNode = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    contentNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    contentNode.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    contentNode.fontSize = 12.0f;
    if (n == 9) {
      contentNode.text = @"None";
    } else {
      contentNode.text = [NSString stringWithFormat:@"%c", (char)(n + 65)];
    }
    [gridContentNodes addObject:contentNode];
  }
  [gridNode setContent:gridContentNodes];
  return gridNode;
}

- (HLLabelButtonNode *)HL_createContentLabelButtonNode
{
  HLLabelButtonNode *labelButtonNode = [[HLLabelButtonNode alloc] initWithColor:[SKColor colorWithRed:0.9f green:0.7f blue:0.5f alpha:1.0f]
                                                                           size:CGSizeMake(0.0f, 24.0f)];
  labelButtonNode.fontSize = 14.0f;
  labelButtonNode.automaticWidth = YES;
  labelButtonNode.automaticHeight = NO;
  labelButtonNode.labelPadX = 5.0f;
  labelButtonNode.heightMode = HLLabelHeightModeFont;
  labelButtonNode.text = @"HLLabelButtonNode";
  return labelButtonNode;
}

- (HLTiledNode *)HL_createContentTiledNode
{
  CGSize imageSize = CGSizeMake(50.0f, 30.0f);

#if TARGET_OS_IPHONE
  UIGraphicsBeginImageContext(imageSize);
  CGContextRef context = UIGraphicsGetCurrentContext();
#else
  NSImage *image = [[NSImage alloc] initWithSize:imageSize];
  [image lockFocus];
  CGContextRef context = [NSGraphicsContext.currentContext CGContext];
#endif

  CGContextSetFillColorWithColor(context, [[SKColor yellowColor] CGColor]);
  CGContextFillRect(context, CGRectMake(0.0f, 0.0f, imageSize.width / 2.0f, imageSize.height));
  CGContextSetFillColorWithColor(context, [[SKColor blueColor] CGColor]);
  CGContextFillRect(context, CGRectMake(imageSize.width / 2.0f, 0.0f, imageSize.width / 2.0f, imageSize.height));
  CGContextSetFillColorWithColor(context, [[SKColor greenColor] CGColor]);
  CGContextFillEllipseInRect(context, CGRectMake(2.0f, 2.0f, imageSize.width - 4.0f, imageSize.height - 4.0f));

#if TARGET_OS_IPHONE
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
#else
  [image unlockFocus];
#endif

  SKTexture *texture = [SKTexture textureWithImage:image];
  HLTiledNode *tiledNode = [HLTiledNode tiledNodeWithTexture:texture size:CGSizeMake(120.0f, 100.0f)];
  return tiledNode;
}

- (HLToolbarNode *)HL_createContentToolbarNode
{
  HLToolbarNode *toolbarNode = [[HLToolbarNode alloc] init];
  toolbarNode.automaticHeight = NO;
  toolbarNode.automaticWidth = NO;
  toolbarNode.backgroundBorderSize = 2.0f;
  toolbarNode.squareSeparatorSize = 4.0f;
  toolbarNode.toolPad = 2.0f;
  toolbarNode.size = CGSizeMake(240.0f, 32.0f);

  NSMutableArray *toolNodes = [NSMutableArray array];
  NSMutableArray *toolTags = [NSMutableArray array];

  SKSpriteNode *redTool = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(20.0f, 20.0f)];
  [toolNodes addObject:redTool];
  [toolTags addObject:@"red"];

  SKSpriteNode *orangeTool = [SKSpriteNode spriteNodeWithColor:[SKColor orangeColor] size:CGSizeMake(10.0f, 20.0f)];
  [toolNodes addObject:orangeTool];
  [toolTags addObject:@"orange"];

  SKSpriteNode *yellowTool = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(30.0f, 20.0f)];
  [toolNodes addObject:yellowTool];
  [toolTags addObject:@"yellow"];

  SKSpriteNode *greenTool = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(20.0f, 20.0f)];
  [toolNodes addObject:greenTool];
  [toolTags addObject:@"green"];

  [toolbarNode setTools:toolNodes tags:toolTags animation:HLToolbarNodeAnimationSlideUp];
  return toolbarNode;
}

- (HLMultilineLabelNode *)HL_createContentMultilineLabelNode
{
  NSString *text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
  HLMultilineLabelNode *multilineLabelNode = [[HLMultilineLabelNode alloc] initWithText:text
                                                                           widthMaximum:240.0f
                                                                            lineSpacing:0.0f
                                                                              alignment:NSTextAlignmentLeft
                                                                               fontName:@"Helvetica"
                                                                               fontSize:12.0f
                                                                              fontColor:[SKColor darkGrayColor]
                                                                                 shadow:nil];
  return multilineLabelNode;
}

- (void)HL_showMessage:(NSString *)message
{
  if (!_messageNode) {
    _messageNode = [[HLMessageNode alloc] initWithColor:[SKColor colorWithWhite:0.0f alpha:0.3f]
                                                   size:CGSizeZero];
    _messageNode.zPosition = 1.0f;
    _messageNode.fontName = @"Helvetica";
    _messageNode.fontSize = 12.0f;
    _messageNode.messageLingerDuration = 5.0;
  }
  _messageNode.size = CGSizeMake(self.size.width, 20.0f);
  _messageNode.position = CGPointMake(0.0f, (self.size.height - _messageNode.size.height) / 2.0f - 10.0f);
  [_messageNode showMessage:message parent:self];
}

@end
