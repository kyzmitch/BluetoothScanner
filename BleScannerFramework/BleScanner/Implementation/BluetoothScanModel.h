//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BluetoothScanProtocol.h"

@interface BluetoothScanModel : NSObject <BluetoothScanProtocol>

- (instancetype)initWithSearchedPeripheralName:(NSString *)searchedName;
- (instancetype)initWithSearchedPeripheralNames:(NSArray<NSString *> *)searchedNames;

@end
