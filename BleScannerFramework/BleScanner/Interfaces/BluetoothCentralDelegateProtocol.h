//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BluetoothCentralCallbacksProtocol.h"

@protocol BluetoothCentralDelegateProtocol

@required
@property (nonatomic, weak) id<BluetoothCentralCallbacksProtocol> bluetoothCallbackDelegate;

@end
