
#import "BluetoothPeripheralDelegate.h"
#import "BluetoothConstants.h"
#import "NSString+Extension.h"

static unsigned long peripheralDelegateNumber = 0;

@interface BluetoothPeripheralDelegate ()

@property (nonatomic, strong) dispatch_queue_t peripheralDelegateQueue;
@property (nonatomic, strong) id<BluetoothValuesProtocol> protocolHandler;

@end

@implementation BluetoothPeripheralDelegate

@synthesize bluetoothCallbackDelegate;

- (instancetype)initWithValuesProtocol:(id<BluetoothValuesProtocol>)protocol{
    self = [super init];
    if (!self) {
        return nil;
    }
    NSString *bleResponsesSuffix = [NSString stringWithFormat:@"%@-%lu", @"ble.peripheral", peripheralDelegateNumber];
    peripheralDelegateNumber++;
    _peripheralDelegateQueue = dispatch_queue_create([NSString queueNameWithSuffix:bleResponsesSuffix], DISPATCH_QUEUE_SERIAL);
    _protocolHandler = protocol;
    return self;
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error){
        NSLog(@"%@: failed to discover services of %@ - error: %@", [self class], peripheral.identifier.UUIDString, [error description]);
        
        dispatch_async(self.peripheralDelegateQueue, ^{
            NSDictionary *userInfo = @{kBleCharacteristicsScanStatusDataKey: @(kBleFailedDiscoverServices)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBleScanCharacteristicsNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
        return;
    }
    
    if (peripheral.services == nil || peripheral.services.count == 0){
        NSLog(@"%@: peripheral has no any services", [self class]);
        dispatch_async(self.peripheralDelegateQueue, ^{
            NSDictionary *userInfo = @{kBleCharacteristicsScanStatusDataKey: @(kBleNoServicesDiscovered)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBleScanCharacteristicsNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
        return;
    }
    
    BOOL allNeededServicesFound = [self.bluetoothCallbackDelegate peripheralDiscoveredAllServices:peripheral];
    
    if (allNeededServicesFound == NO){
        dispatch_async(self.peripheralDelegateQueue, ^{
            NSDictionary *userInfo = @{kBleCharacteristicsScanStatusDataKey: @(kBleNotAllServicesDiscovered)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBleScanCharacteristicsNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
        
        return;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if (error){
        NSLog(@"%@: failed to discover characteristics for service %@ with error: %@", [self class], service.UUID.UUIDString, [error description]);
        dispatch_async(self.peripheralDelegateQueue, ^{
            NSDictionary *userInfo = @{kBleCharacteristicsScanStatusDataKey: @(kBleFailedToDiscoverCharacteristics)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBleScanCharacteristicsNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
        return;
    }
    
    BOOL allCharacteristicsWereFound = [self.bluetoothCallbackDelegate peripheralDiscoveredCharacteristics:peripheral forService:service];
    
    if (allCharacteristicsWereFound){
        dispatch_async(self.peripheralDelegateQueue, ^{
            NSDictionary *userInfo = @{kBleCharacteristicsScanStatusDataKey: @(kBleCharacteristicsDiscoveringDone)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBleScanCharacteristicsNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
        
        return;
    }
}

- (void)peripheral:(__unused CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
    if (error){
        NSLog(@"%@: notification State error %@", [self class], [error description]);
        dispatch_async(self.peripheralDelegateQueue, ^{
            NSDictionary *userInfo = @{kBleSubscriptionStateDataKey: @(kBleFailedToSubscribeForNotifications)};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kBleSubscribeStateNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
        return;
    }
    
    NSLog(@"%@: notification state update for %@ - isNotifying %d",
          [self class],
          characteristic.UUID.UUIDString,
          characteristic.isNotifying);
    
    [self.protocolHandler handleCharacteristicStateUpdate:characteristic];

}

-(void)peripheral:(__unused CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // @NOTE: will be invoked to handle response for read request
    // and for incoming notification
    
    if (error){
        NSLog(@"%@: failed read updated value %@ with error: %@", [self class], characteristic.UUID.UUIDString, [error description]);
        return;
    }
    
    [self.protocolHandler handleNewCharacteristicValue:characteristic];
}

@end
