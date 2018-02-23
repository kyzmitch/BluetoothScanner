//
//  PeripheralServicesFactorySubclass.h
//  BleScanner
//
//  Created by Andrey Ermoshin on 23/02/2018.
//  Copyright © 2018 kyzmitch. All rights reserved.
//

#import <BLEScanner/PeripheralServicesFactory.h>

@interface PeripheralServicesFactory ()

@property (nonatomic, strong, nonnull, readwrite) NSArray<CBUUID *> *backgroundServices;
@property (nonatomic, strong, nonnull, readwrite) NSDictionary<CBUUID *, NSArray<CBUUID *> *> *characteristicsUuids;
@property (nonatomic, strong, nonnull, readwrite) NSMutableDictionary<CBUUID *, NSNumber *> *serviceChecks;
@property (nonatomic, strong, nonnull, readwrite) NSMutableDictionary<CBUUID *, NSArray<CBCharacteristic *> *> *characteristicsDictionary;

@end
