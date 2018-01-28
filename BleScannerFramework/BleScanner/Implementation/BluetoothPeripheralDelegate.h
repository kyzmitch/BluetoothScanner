//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BluetoothCentralDelegateProtocol.h"
#import "BluetoothValuesProtocol.h"

@interface BluetoothPeripheralDelegate : NSObject <CBPeripheralDelegate, BluetoothCentralDelegateProtocol>

- (instancetype)initWithValuesProtocol:(id<BluetoothValuesProtocol>)protocol;

@end
