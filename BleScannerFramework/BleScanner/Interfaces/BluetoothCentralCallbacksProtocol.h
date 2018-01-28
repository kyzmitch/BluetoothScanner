//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BluetoothCentralCallbacksProtocol <NSObject>

- (void)centralManagerPoweredOn:(BOOL)poweredOn withState:(CBManagerState)state;
- (void)centralManagerConnectedTo:(CBPeripheral *)peripheral at:(NSDate *)time;
- (void)centralManagerFailConnectTo:(CBPeripheral *)peripheral;
- (void)centralManagerDisconnected:(CBPeripheral *)peripheral;
- (void)centralManagerFoundPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
- (BOOL)peripheralDiscoveredAllServices:(CBPeripheral *)peripheral;
- (BOOL)peripheralDiscoveredCharacteristics:(CBPeripheral *)peripheral forService:(CBService *)service;
- (BOOL)peripheralHasSameUUID:(NSUUID *)uuid;
- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state;

@end
