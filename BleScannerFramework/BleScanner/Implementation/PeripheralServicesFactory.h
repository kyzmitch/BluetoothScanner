//
//  PeripheralServicesFactory.h
//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BLEScanner/BluetoothPeripheralAbstractFactory.h>
#import <BLEScanner/BluetoothPeripheralInterfaceValidator.h>
#import <BLEScanner/PeripheralCharacteristicsProtocol.h>

// TODO: separate class on two different classes if it's possible
// to have validator in different class

@interface PeripheralServicesFactory : NSObject <BluetoothPeripheralAbstractFactory, BluetoothPeripheralInterfaceValidator, PeripheralCharacteristicsProtocol>

@property (nonatomic, strong, nonnull, readonly) NSArray<CBUUID *> *backgroundServices;
@property (nonatomic, strong, nonnull, readonly) NSDictionary<CBUUID *, NSArray<CBUUID *> *> *characteristicsUuids;
@property (nonatomic, strong, nonnull, readonly) NSMutableDictionary<CBUUID *, NSNumber *> *serviceChecks;
@property (nonatomic, strong, nonnull, readonly) NSMutableDictionary<CBUUID *, NSArray<CBCharacteristic *> *> *characteristicsDictionary;

@end
