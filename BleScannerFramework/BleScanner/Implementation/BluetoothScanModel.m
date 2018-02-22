
#import "BluetoothScanModel.h"
#import "BluetoothConstants.h"

@interface BluetoothScanModel ()
{
@private
    NSArray<NSString *> *_names;
    NSMutableDictionary<NSString *, NSMutableArray<id<PeripheralBasicInfoProtocol>> *> *_foundPeripherals;
}

@end

@implementation BluetoothScanModel

- (instancetype)initWithSearchedPeripheralName:(NSString *)searchedName{
    self = [self initWithSearchedPeripheralNames:@[searchedName]];
    return self;
}

- (instancetype)initWithSearchedPeripheralNames:(NSArray<NSString *> *)searchedNames{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _names = searchedNames;
    _foundPeripherals = [NSMutableDictionary new];
    for (NSString *name in _names) {
        NSMutableArray<id<PeripheralBasicInfoProtocol>> *array = [NSMutableArray<id<PeripheralBasicInfoProtocol>> new];
        [_foundPeripherals setObject:array forKey:name];
    }
    
    return self;
}

- (BOOL)autoScanEnabled{
    return YES;
}

- (BOOL)instantScanEnabled{
    return YES;
}

- (NSUUID *)peripheralUuidToSearch{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *cachedUuid = [settings stringForKey:kPairedPeripheralUuid];
    if (cachedUuid) {
        return [[NSUUID alloc] initWithUUIDString:cachedUuid];
    }
    else{
        return nil;
    }
}

- (void)setPeripheralUuidToSearch:(NSUUID *)uuid{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if (uuid == nil) {
        [settings removeObjectForKey:kPairedPeripheralUuid];
    }
    else{
        [settings setValue:uuid.UUIDString forKey:kPairedPeripheralUuid];
    }
    
    if ([settings synchronize] == NO){
        NSLog(@"%@: failed to save peripheral uuid in user defaults", [self class]);
    }
    else{
        NSLog(@"%@: remember peripheral uuid in usr defaults %@", [self class], uuid.UUIDString);
    }
}

- (NSUInteger)scanTimeInSeconds{
    return kDevicesScanTime;
}

- (NSArray<NSString *> *)namesToSearch{
    return _names;
}

- (NSArray<id<PeripheralBasicInfoProtocol>> *)foundPeripheralsWithName:(NSString *)name{
    
    NSArray<id<PeripheralBasicInfoProtocol>> *result;
    @synchronized (self) {
        result = _foundPeripherals[name];
    }
    return result;
}

- (void)addPeripheral:(id<PeripheralBasicInfoProtocol>)info forName:(NSString *)name{
    @synchronized (self) {
        NSMutableArray<id<PeripheralBasicInfoProtocol>> *array = _foundPeripherals[name];
        if (array) {
            [array addObject:info];
        }
    }
}

- (void)clearFoundPeripheralsForEveryName{
    @synchronized (self) {
        for (NSMutableArray *array in _foundPeripherals.allValues) {
            [array removeAllObjects];
        }
    }
}

- (BOOL)somePeripheralFound{
    BOOL result = NO;
    @synchronized (self) {
        for (NSMutableArray *array in _foundPeripherals.allValues) {
            if (array.count > 0) {
                result = YES;
                break;
            }
        }
    }
    
    return result;
}

- (id<PeripheralBasicInfoProtocol>)find{
    
    // need to find peripheral with highest RSSI
    long maxRSSI = LONG_MIN;

    id<PeripheralBasicInfoProtocol> nearestPeripheral = nil;
    
    @synchronized (self) {
        for (NSString *name in _foundPeripherals.allKeys) {
            NSArray<id<PeripheralBasicInfoProtocol>> *array = _foundPeripherals[name];
            for (id<PeripheralBasicInfoProtocol> info in array) {
                if (info.RSSI == nil){
                    continue;
                }
                
                long deviceRssiNum = info.RSSI.longValue;
                if (deviceRssiNum > maxRSSI){
                    maxRSSI = deviceRssiNum;
                    nearestPeripheral = info;
                }
            }
        }
    }
    
    return nearestPeripheral;
}

@end
