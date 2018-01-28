//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <BLEScanner/BaseDeviceServiceProtocol.h>

@protocol BluetoothValuesProtocol

@required
- (void)handleNewCharacteristicValue:(CBCharacteristic *)characteristic;
- (void)handleCharacteristicStateUpdate:(CBCharacteristic *)characteristic;
- (void)setBluetoothInterface:(id<BaseDeviceServiceProtocol>)interface;

@end
