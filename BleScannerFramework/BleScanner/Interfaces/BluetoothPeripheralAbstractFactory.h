//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BluetoothPeripheralAbstractFactory

@required
- (NSArray<CBUUID *> *)backgroundScanServices;
- (NSArray<CBUUID *> *)foregroundServices;
- (NSArray<CBUUID *> *)characteristicsForService:(CBUUID *)uuid;

@end
