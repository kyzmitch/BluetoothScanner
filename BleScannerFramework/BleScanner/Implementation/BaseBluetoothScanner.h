//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BLEScanner/BluetoothPeripheralAbstractFactory.h>
#import <BLEScanner/BluetoothPeripheralInterfaceValidator.h>
#import <BLEScanner/BluetoothCentralCallbacksProtocol.h>
#import <BLEScanner/BluetoothScanProtocol.h>
#import <BLEScanner/BluetoothEngineInterface.h>
#import <BLEScanner/BluetoothConnectionStatusProtocol.h>
#import <BLEScanner/BluetoothValuesProtocol.h>

@interface BaseBluetoothScanner : NSObject <BluetoothCentralCallbacksProtocol, BluetoothEngineInterface, BluetoothConnectionStatusProtocol>

// TODO: Need to think if validator instance can be separated from factory instance

- (instancetype)initWithPeripheralInterfaceFactory:(id<BluetoothPeripheralAbstractFactory, BluetoothPeripheralInterfaceValidator>)peripheralInterfaceFactory scanModel:(id<BluetoothScanProtocol>)searchModel protocol:(id<BluetoothValuesProtocol>)protocol;

@end
