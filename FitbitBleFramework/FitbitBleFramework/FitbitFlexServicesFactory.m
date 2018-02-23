//
//  FitbitFlexServicesFactory.m
//  FitbitBleFramework
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import "FitbitFlexServicesFactory.h"
#import <BLEScanner/PeripheralServicesFactorySubclass.h>
#import <BLEScanner/BluetoothConstants.h>

static NSString *backgroundSrv  = @"ADAB4127-6E7D-4601-BDA2-BFFAA68956BA";
// Custom services
static NSString *service1uuid   = @"ADAB4127-6E7D-4601-BDA2-BFFAA68956BA";
static NSString *service2uuid   = @"558DFA00-4FA8-4105-9F02-4EAA93E62980";
static NSString *service1ch1    = @"ADABFB01-6E7D-4601-BDA2-BFFAA68956BA"; // Read/Notify
static NSString *service1ch2    = @"ADABFB02-6E7D-4601-BDA2-BFFAA68956BA"; // Read/Write without response
static NSString *service2ch1    = @"558DFA01-4FA8-4105-9F02-4EAA93E62980"; // Read/Notify

// Device information
// https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.service.device_information.xml
static NSString * deviceInfoServiceUuid = @"180A";

// Battery service
// https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.battery_level.xml&u=org.bluetooth.characteristic.battery_level.xml
// value from 0 to 100 but it is info for different class - for values
static NSString *batteryServiceUuid = @"180F";
// Battery level characteristic UUID: 0x2A19
static NSString *batteryLevelChUuid = @"2A19";

@implementation FitbitFlexServicesFactory

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.backgroundServices = @[[CBUUID UUIDWithString:backgroundSrv]];
    CBUUID *service1 = [CBUUID UUIDWithString:service1uuid];
    NSArray<CBUUID *> *characteristicsForService1 = @[[CBUUID UUIDWithString:service1ch1], [CBUUID UUIDWithString:service1ch2]];
    CBUUID *service2 = [CBUUID UUIDWithString:service2uuid];
    NSArray<CBUUID *> *characteristicsForService2 = @[[CBUUID UUIDWithString:service2ch1]];
    CBUUID *batteryLevelService = [CBUUID UUIDWithString:batteryServiceUuid];
    self.characteristicsUuids = @{service1: characteristicsForService1, service2: characteristicsForService2, batteryLevelService: @[batteryLevelChUuid]};
    self.characteristicsDictionary = [NSMutableDictionary dictionaryWithDictionary:@{service1: [NSMutableArray array], service2: [NSMutableArray array], batteryLevelService: [NSMutableArray array]}];
    self.serviceChecks = [NSMutableDictionary dictionaryWithDictionary:@{service1: @(NO), service2: @(NO), batteryLevelService: @(NO)}];
    
    return self;
}

@end
