//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BluetoothConnectionStatusProtocol

@required
- (BOOL)isBluetoothPoweredOn;
- (BOOL)isDeviceConnected;
- (BOOL)isScanning;

@end
