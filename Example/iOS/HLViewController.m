//
//  HLViewController.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 11/14/2014.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import "HLViewController.h"

#import <SpriteKit/SpriteKit.h>

#import "HLAlignmentScene.h"
#import "HLCatalogScene.h"
#import "HLExampleScene.h"
#import "HLLabelButtonNode.h"
#import "SKNode+HLGestureTarget.h"

@implementation HLViewController
{
  HLToolbarNode *_applicationToolbarNode;
  HLCatalogScene *_catalogScene;
  HLAlignmentScene *_alignmentScene;
  SKScene<HLExampleScene> *_currentScene;
  NSString *_currentSceneTag;
}

- (void)loadView
{
  SKView *skView = [[SKView alloc] init];
  skView.ignoresSiblingOrder = YES;
  self.view = skView;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  _applicationToolbarNode = [[HLToolbarNode alloc] init];
  _applicationToolbarNode.backgroundColor = [SKColor colorWithWhite:0.0f alpha:0.5f];
  _applicationToolbarNode.squareColor = [SKColor clearColor];
  _applicationToolbarNode.highlightColor = [SKColor colorWithWhite:1.0f alpha:0.2f];
  _applicationToolbarNode.automaticHeight = YES;
  _applicationToolbarNode.automaticToolsScaleLimit = YES;
  _applicationToolbarNode.justification = HLToolbarNodeJustificationCenter;
  _applicationToolbarNode.squareSeparatorSize = 0.0f;
  _applicationToolbarNode.backgroundBorderSize = 0.0f;
  SKNode *catalogNode = [self HL_createLabelWithText:@"Catalog"];
  SKNode *alignmentNode = [self HL_createLabelWithText:@"Alignment"];
  [_applicationToolbarNode setTools:@[ catalogNode, alignmentNode ]
                               tags:@[ @"catalog", @"alignment" ]
                          animation:HLToolbarNodeAnimationNone];
  [_applicationToolbarNode hlSetGestureTarget:_applicationToolbarNode];
  _applicationToolbarNode.delegate = self;

  _catalogScene = [[HLCatalogScene alloc] initWithSize:self.view.bounds.size];
  _catalogScene.scaleMode = SKSceneScaleModeResizeFill;
  _catalogScene.anchorPoint = CGPointMake(0.5f, 0.5f);
  // note: "Z-position then parent" works well with "ignores sibling order."
  _catalogScene.gestureTargetHitTestMode = HLSceneGestureTargetHitTestModeZPositionThenParent;

  _alignmentScene = [[HLAlignmentScene alloc] initWithSize:self.view.bounds.size];
  _alignmentScene.scaleMode = SKSceneScaleModeResizeFill;
  _alignmentScene.anchorPoint = CGPointMake(0.5f, 0.5f);
  // note: "Z-position then parent" works well with "ignores sibling order."
  _alignmentScene.gestureTargetHitTestMode = HLSceneGestureTargetHitTestModeZPositionThenParent;

  [self HL_presentScene:@"catalog"];
}

- (void)toolbarNode:(HLToolbarNode *)toolbarNode didTapTool:(NSString *)toolTag
{
  [self HL_presentScene:toolTag];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return UIInterfaceOrientationMaskAllButUpsideDown;
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

- (void)HL_presentScene:(NSString *)sceneTag
{
  if (!sceneTag) {
    return;
  }

  if (_currentSceneTag && [_currentSceneTag isEqualToString:sceneTag]) {
    return;
  }

  SKScene<HLExampleScene> *scene = nil;
  if ([sceneTag isEqualToString:@"catalog"]) {
    scene = _catalogScene;
  } else if ([sceneTag isEqualToString:@"alignment"]) {
    scene = _alignmentScene;
  } else {
    return;
  }

  if (_currentSceneTag) {
    [_applicationToolbarNode setHighlight:NO forTool:_currentSceneTag];
    [_currentScene setApplicationToolbar:nil];
  }

  [_applicationToolbarNode setHighlight:YES forTool:sceneTag];
  [scene setApplicationToolbar:_applicationToolbarNode];

  [(SKView *)self.view presentScene:scene transition:[SKTransition fadeWithColor:[SKColor blackColor] duration:1.0]];

  _currentSceneTag = sceneTag;
  _currentScene = scene;
}

- (SKNode *)HL_createLabelWithText:(NSString *)text
{
  HLLabelButtonNode *labelNode = [[HLLabelButtonNode alloc] initWithColor:[SKColor clearColor] size:CGSizeZero];
  labelNode.automaticHeight = YES;
  labelNode.automaticWidth = YES;
  labelNode.labelPadX = 10.0f;
  labelNode.labelPadY = 2.0f;
  labelNode.fontSize = 12.0f;
  labelNode.fontColor = [SKColor whiteColor];
  labelNode.heightMode = HLLabelHeightModeFont;
  labelNode.text = text;
  return labelNode;
}

@end
