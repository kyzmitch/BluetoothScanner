//
//  PeripheralServicesFactory.m
//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import "PeripheralServicesFactory.h"
#import "PeripheralServicesFactorySubclass.h"

@implementation PeripheralServicesFactory

#pragma mark - BluetoothPeripheralAbstractFactory

- (NSArray<CBUUID *> *)backgroundScanServices {
    return _backgroundServices;
}

- (NSArray<CBUUID *> *)foregroundServices {
    if (_characteristicsUuids.allKeys.count > 0) {
        NSArray *servicesUuids = _characteristicsUuids.allKeys;
        return servicesUuids;
    }
    return nil;
}

- (NSArray<CBUUID *> *)characteristicsForService:(CBUUID *)uuid {
    return _characteristicsUuids[uuid];
}

#pragma mark - BluetoothPeripheralInterfaceValidator

- (void)markServiceAsCheckedForUuid:(CBUUID *)checkedUuid {
    @synchronized (self) {
        if (_serviceChecks[checkedUuid] != nil) {
            _serviceChecks[checkedUuid] = @(YES);
        }
        else{
            NSLog(@"%@: unknown service uuid %@", [self class], checkedUuid);
        }
    }
}
- (void)resetAllCheckmarksForServices {
    @synchronized (self) {
        for (CBUUID *key in _serviceChecks.allKeys) {
            _serviceChecks[key] = @(NO);
        }
    }
}
- (BOOL)isInterfaceCompletelyMatch {
    @synchronized (self) {
        for (CBUUID *key in _serviceChecks.allKeys) {
            NSNumber *value = _serviceChecks[key];
            // TODO: add check if it is really NSNumber or not
            if (value.boolValue == NO) {
                return NO;
            }
        }
    }
    return YES;
}

- (void)saveCharacteristics:(NSArray<CBCharacteristic *> *)characteristics forService:(CBUUID *)uuid{
    _characteristicsDictionary[uuid] = characteristics;
}

#pragma mark - PeripheralCharacteristicsProtocol

- (CBCharacteristic *)getCharacteristicByUuid:(NSString *)uuid fromService:(CBUUID *)serviceUuid{
    NSArray<CBCharacteristic *> *array = _characteristicsDictionary[serviceUuid];
    for (CBCharacteristic *ch in array) {
        if ([ch.UUID.UUIDString isEqualToString:uuid]) {
            return ch;
        }
    }
    return nil;
}

@end
