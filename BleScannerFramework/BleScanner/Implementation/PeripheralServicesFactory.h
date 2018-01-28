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

// TODO: somehow make following properties not public or
// not possible for modifications outside of child class init methods

@property (nonatomic, strong, nonnull) NSArray<CBUUID *> *backgroundServices;
@property (nonatomic, strong, nonnull) NSDictionary<CBUUID *, NSArray<CBUUID *> *> *characteristicsUuids;
@property (nonatomic, strong, nonnull) NSMutableDictionary<CBUUID *, NSNumber *> *serviceChecks;
@property (nonatomic, strong, nonnull) NSMutableDictionary<CBUUID *, NSArray<CBCharacteristic *> *> *characteristicsDictionary;

@end
