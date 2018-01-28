//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BluetoothPeripheralInterfaceValidator

@required
- (void)markServiceAsCheckedForUuid:(CBUUID *)checkedUuid;
- (void)resetAllCheckmarksForServices;
- (BOOL)isInterfaceCompletelyMatch;
- (void)saveCharacteristics:(NSArray<CBCharacteristic *> *)characteristics forService:(CBUUID *)uuid;

@end
