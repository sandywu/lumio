//
//  LightManager.m
//  CircleGame
//
//  Created by Joanne Dyer on 1/26/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "LightManager.h"
#import "GameConfig.h"

@interface LightManager ()

@property (nonatomic, strong) NSMutableArray *twoDimensionalLightArray;

@end

@implementation LightManager

@synthesize route = _route;
@synthesize twoDimensionalLightArray = _twoDimensionalLightArray;

- (id)initWithLightArray:(NSMutableArray *)lightArray
{
    if (self = [super init]) {
        self.twoDimensionalLightArray = lightArray;
        
        //set self as the light manager for all the lights and ensure the connectors are in the correct initial states.
        for (NSMutableArray *innerArray in self.twoDimensionalLightArray) {
            for (Light *light in innerArray) {
                light.lightManager = self;
                if (light.lightState == Cooldown) {
                    [self lightNowOnCooldown:light];
                } else {
                    [self lightNowActive:light];
                }
            }
        }
        
        //add self as listener to the new value light needed notifcication.
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(newValueLightNeededEventHandler:)
         name:NOTIFICATION_NEW_VALUE_LIGHT_NEEDED
         object:nil];
    }
    return self;
}

- (void)update:(ccTime)dt {
    for (NSMutableArray *innerArray in self.twoDimensionalLightArray) {
        for (Light *light in innerArray) {
            [light update:dt];
        }
    }
}

//handles the events sent by lights when a value light has been occupied.
- (void)newValueLightNeededEventHandler:(NSNotification *)notification
{
    [self chooseNewValueLight];
}

- (void)chooseNewValueLight
{    
    //choose an instance to change to a value light. This light can not be almost occupied, or occupied.
    int randomRowIndex, randomColumnIndex;
    Light *chosenLight;
    do {
        //as the board is square we can just choose a row at random then a column at random.
        randomRowIndex = arc4random() % NUMBER_OF_ROWS;
        randomColumnIndex = arc4random() % NUMBER_OF_COLUMNS;
        chosenLight = [[self.twoDimensionalLightArray objectAtIndex:randomRowIndex] objectAtIndex:randomColumnIndex];
    } while (![chosenLight canBeValueLight]);
    
    //tell this light to give itself a value.
    [chosenLight setUpLightWithValue];
}

- (Light *)getSelectedLightFromLocation:(CGPoint)location {
    //go through all the lights seeing if they contain the point.
    Light *selectedLight = nil;
    for (NSMutableArray *innerArray in self.twoDimensionalLightArray) {
        for (Light *light in innerArray) {
            if (CGRectContainsPoint([light getBounds], location)) {
                selectedLight = light;
                break;
            }
        }
    }
    return selectedLight;
}

- (Light *)getLightAtRow:(int)row column:(int)column
{
    NSMutableArray *rowArray = [self.twoDimensionalLightArray objectAtIndex:row];
    return [rowArray objectAtIndex:column];
}

//called by a light when it becomes active, will update the state of the relevant connectors.
- (void)lightNowActive:(Light *)light
{
    if (light.row < NUMBER_OF_ROWS - 1) {
        Light *lightAbove = [self getLightAtRow:(light.row + 1) column:light.column];
        light.topConnector.state = lightAbove.lightState == Cooldown ? Disabled : Enabled;
    }
    if (light.column < NUMBER_OF_COLUMNS - 1) {
        Light *lightToTheRight = [self getLightAtRow:light.row column:(light.column + 1)];
        light.rightConnector.state = lightToTheRight.lightState == Cooldown ? Disabled : Enabled;
    }
    if (light.row > 0) {
        Light *lightBelow = [self getLightAtRow:(light.row - 1) column:light.column];
        lightBelow.topConnector.state = lightBelow.lightState == Cooldown ? Disabled : Enabled;
    }
    if (light.column > 0) {
        Light *lightToTheLeft = [self getLightAtRow:light.row column:(light.column - 1)];
        lightToTheLeft.rightConnector.state = lightToTheLeft.lightState == Cooldown ? Disabled : Enabled;
    }
}

//called by a light when it enters cooldown, will update the state of the relevant connectors and ensure it if removed from the route.
- (void)lightNowOnCooldown:(Light *)light
{
    if (light.row < NUMBER_OF_ROWS - 1) {
        light.topConnector.state = Disabled;
    }
    if (light.column < NUMBER_OF_COLUMNS - 1) {
        light.rightConnector.state = Disabled;
    }
    if (light.row > 0) {
        Light *lightBelow = [self getLightAtRow:(light.row - 1) column:light.column];
        lightBelow.topConnector.state = Disabled;
    }
    if (light.column > 0) {
        Light *lightToTheLeft = [self getLightAtRow:light.row column:(light.column - 1)];
        lightToTheLeft.rightConnector.state = Disabled;
    }
    
    [self.route removeLightFromRoute:light];
}

@end
