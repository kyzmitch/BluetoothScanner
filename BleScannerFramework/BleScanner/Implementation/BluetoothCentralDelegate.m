
#import "BluetoothCentralDelegate.h"
#import "BluetoothConstants.h"
#import "NSString+Extension.h"

static unsigned long centralDelegateNumber = 0;

@interface BluetoothCentralDelegate ()

@property (nonatomic, strong) dispatch_queue_t centralDelegateQueue;

@end

@implementation BluetoothCentralDelegate

@synthesize bluetoothCallbackDelegate;

- (instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    NSString *bleResponsesSuffix = [NSString stringWithFormat:@"%@-%lu", @"blecentral", centralDelegateNumber];
    centralDelegateNumber++;
    _centralDelegateQueue = dispatch_queue_create([NSString queueNameWithSuffix:bleResponsesSuffix], DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)centr{
    NSLog(@"%@: state changed %ld", [self class], (long)centr.state);
    
    // creating strong ref
    __typeof__(self.bluetoothCallbackDelegate) bleDelegate = self.bluetoothCallbackDelegate;
    
    switch (centr.state){
        case CBManagerStatePoweredOn:{
            [bleDelegate centralManagerPoweredOn:YES withState:centr.state];
            break;
        }
        default:{
            [bleDelegate centralManagerPoweredOn:NO withState:centr.state];
        }
            break;
    }
}

- (void)centralManager:(__unused CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    // About using of attributes like __unused and syntax
    // https://stackoverflow.com/a/36832021
    
    NSDate *time = [NSDate date];
    NSLog(@"%@: connected peripheral %@", [self class], peripheral.identifier.UUIDString);
    
    __typeof__(self.bluetoothCallbackDelegate) bleDelegate = self.bluetoothCallbackDelegate;
    BOOL isItSearchedPeripheral = [bleDelegate peripheralHasSameUUID:peripheral.identifier];
    
    if (isItSearchedPeripheral){
        [bleDelegate centralManagerConnectedTo:peripheral at:time];
        
        dispatch_async(self.centralDelegateQueue, ^{
            NSDictionary *stateUserInfo = @{kTimestampDataKey: time,
                                            kPeripheralStateDataKey: [NSNumber numberWithInteger:peripheral.state]};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBlePeripheralStateNotification
                                                                object:nil
                                                              userInfo:stateUserInfo];
            
            NSNumber *successCodeNum = [NSNumber numberWithUnsignedInteger:kBleSearchedPeripheralFoundAndConnected];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:successCodeNum,
                                      kBlePeripheralConnectStatusDataKey,
                                      peripheral.identifier.UUIDString,
                                      kBlePeripheralUuidDataKey,
                                      peripheral.name,
                                      kBlePeripheralNameDataKey,
                                      nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kConnectWithPeripheralNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    }
    else{
        dispatch_async(self.centralDelegateQueue, ^{
            
            NSDictionary *stateUserInfo = @{kTimestampDataKey: time,
                                            kPeripheralStateDataKey: @(peripheral.state)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBlePeripheralStateNotification
                                                                object:nil
                                                              userInfo:stateUserInfo];
            
            NSNumber *successCodeNum = [NSNumber numberWithUnsignedInteger:kBleConnectedWithNotSearchedPeripheral];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:successCodeNum,
                                      kBlePeripheralConnectStatusDataKey, nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kConnectWithPeripheralNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    }
}

- (void)centralManager:(__unused CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    NSDate *timestamp = [NSDate date];
    
    NSLog(@"%@: peripheral with name %@ fail to connect with error: %@",
          [self class],
          peripheral.name,
          (error != nil ? [error description]: @"no error"));
    
    __typeof__(self.bluetoothCallbackDelegate) bleDelegate = self.bluetoothCallbackDelegate;
    BOOL isItSearchedPeripheral = [bleDelegate peripheralHasSameUUID:peripheral.identifier];
    
    if (isItSearchedPeripheral){
        dispatch_async(self.centralDelegateQueue, ^{
            
            NSDictionary *stateUserInfo = @{kTimestampDataKey: timestamp,
                                            kPeripheralStateDataKey: @(peripheral.state)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBlePeripheralStateNotification
                                                                object:nil
                                                              userInfo:stateUserInfo];
            
            NSNumber *successCodeNum = [NSNumber numberWithUnsignedInteger:kBleFailedToConnectPeripheral];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:successCodeNum,
                                      kBlePeripheralConnectStatusDataKey, nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kConnectWithPeripheralNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    }
    
    [bleDelegate centralManagerFailConnectTo:peripheral];
}

- (void)centralManager:(__unused CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSDate *timestamp = [NSDate date];
    NSString *currentUuid = peripheral.identifier.UUIDString;
    NSLog(@"%@: peripheral disconnected %@: %@", [self class], currentUuid, error ? [error description] : @"no error");
    
    __typeof__(self.bluetoothCallbackDelegate) bleDelegate = self.bluetoothCallbackDelegate;
    BOOL isItSearchedPeripheral = [bleDelegate peripheralHasSameUUID:peripheral.identifier];
    if (isItSearchedPeripheral){
        
        [bleDelegate centralManagerDisconnected:peripheral];
        
        dispatch_async(self.centralDelegateQueue, ^{
            // @NOTE: Avoid updating your windows and views in background
            NSDictionary *stateUserInfo = @{kTimestampDataKey: timestamp,
                                            kPeripheralStateDataKey: @(peripheral.state)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBlePeripheralStateNotification
                                                                object:nil
                                                              userInfo:stateUserInfo];
            
            NSNumber *successCodeNum = [NSNumber numberWithUnsignedInteger:kBlePeripheralDisconnected];
            NSDictionary *connectUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:successCodeNum,
                                             kBlePeripheralConnectStatusDataKey, nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kConnectWithPeripheralNotification
                                                                object:nil
                                                              userInfo:connectUserInfo];
        });
    }
}

- (void)centralManager:(__unused CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSString *name = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSLog(@"%@: peripheral found: %@ - %@ at %@ uuid: %@",
          [self class],
          peripheral.name,
          name,
          RSSI,
          peripheral.identifier.UUIDString);

    [self.bluetoothCallbackDelegate centralManagerFoundPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
}

-(void)centralManager:(CBCentralManager *)central
     willRestoreState:(NSDictionary *)state {
    // @NOTE: http://stackoverflow.com/a/34307921/483101
    
    NSLog(@"%@: willRestoreState - central %ld - %@", [self class], (long)central.state, state);
    
    [self.bluetoothCallbackDelegate centralManager:central willRestoreState:state];
}

@end
