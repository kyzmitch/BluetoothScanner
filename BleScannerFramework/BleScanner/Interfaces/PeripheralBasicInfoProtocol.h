//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol PeripheralBasicInfoProtocol

@required
@property (nonatomic, strong) NSNumber *RSSI;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, copy) NSString *name;

@end
