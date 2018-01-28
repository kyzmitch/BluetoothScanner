//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <BLEScanner/PeripheralBasicInfoProtocol.h>

typedef id<PeripheralBasicInfoProtocol>(^PeripheralBasicInfoComparing)(id<PeripheralBasicInfoProtocol> previous);

@protocol BluetoothScanProtocol
@required

- (BOOL)autoScanEnabled;
- (BOOL)instantScanEnabled;
- (NSUUID *)peripheralUuidToSearch;
- (void)setPeripheralUuidToSearch:(NSUUID *)uuid;
- (NSUInteger)scanTimeInSeconds;
- (NSArray<NSString *> *)namesToSearch;
- (NSArray<id<PeripheralBasicInfoProtocol>> *)foundPeripheralsWithName:(NSString *)name;
- (void)addPeripheral:(id<PeripheralBasicInfoProtocol>)info forName:(NSString *)name;
- (void)clearFoundPeripheralsForEveryName;
- (id<PeripheralBasicInfoProtocol>)find;
- (BOOL)somePeripheralFound;

@end
