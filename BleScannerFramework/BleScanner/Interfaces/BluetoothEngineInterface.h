//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BluetoothEngineInterface

@required
- (void)start;
- (void)tryDisconnectAndForget:(BOOL)forget;
- (BOOL)isReadyForBluetoothRequests;

- (void)subscribe:(CBCharacteristic *)ch forNotification:(BOOL)subscribe;
- (void)read:(CBCharacteristic *)ch;

@end
