
#import <BLEScanner/BaseBluetoothScanner.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BluetoothConstants.h"
#import "BluetoothCentralDelegate.h"
#import "BluetoothPeripheralDelegate.h"
#import "BluetoothCentralDelegateProtocol.h"
#import "PeripheralInfo.h"
#import "NSString+Extension.h"

static NSUInteger counter = 0;
static unsigned long scannerNumber = 0;

@interface BaseBluetoothScanner ()
{
@private
    dispatch_source_t _searchTimerSource;
}

@property (nonatomic, strong) id<BluetoothPeripheralAbstractFactory, BluetoothPeripheralInterfaceValidator> peripheralApiFactory;
@property (nonatomic, strong) id<BluetoothScanProtocol> peripheralScanModel;
@property (nonatomic, strong) id<CBCentralManagerDelegate, BluetoothCentralDelegateProtocol> centralDelegate;
@property (nonatomic, strong) id<CBPeripheralDelegate, BluetoothCentralDelegateProtocol> peripheralDelegate;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) dispatch_queue_t centralQueue;
@property (nonatomic, strong) dispatch_queue_t searchQueue;

- (void)search;
- (BOOL)tryConnectToCachedPeripheral;
- (void)startSearchPeripheralByNameOrByUuid;
- (void)startSearchPeripheralByNameOrByUuidWithCounterReset:(BOOL)resetCounter;
- (void)discover;

- (BOOL)isCentralStatePoweredOn;
- (void)notifyAboutCentralState:(CBManagerState)state;

- (void)handleScanTimerExpiration;
- (dispatch_source_t)searchTimerSource;
- (void)startSearchTimerWithSeconds:(NSUInteger)seconds;
- (void)stopSearchTimer;
- (void)suspendSearchTimer;

@end

@implementation BaseBluetoothScanner

- (instancetype)initWithPeripheralInterfaceFactory:(id<BluetoothPeripheralAbstractFactory, BluetoothPeripheralInterfaceValidator>)peripheralInterfaceFactory scanModel:(id<BluetoothScanProtocol>)searchModel protocol:(id<BluetoothValuesProtocol>)protocol{
    self = [super init];
    if (!self) {
        return nil;
    }
    _peripheralApiFactory = peripheralInterfaceFactory;
    _peripheralScanModel = searchModel;
    NSString *bleSuffix = [NSString stringWithFormat:@"%@-%lu", @"ble", scannerNumber];
    NSString *bleResponsesSuffix = [NSString stringWithFormat:@"%@-%lu", @"ble.search", scannerNumber];
    scannerNumber++;
    _centralQueue = dispatch_queue_create([NSString queueNameWithSuffix:bleSuffix], DISPATCH_QUEUE_SERIAL);
    _searchQueue = dispatch_queue_create([NSString queueNameWithSuffix:bleResponsesSuffix], DISPATCH_QUEUE_SERIAL);
    _centralDelegate = [BluetoothCentralDelegate new];
    _centralDelegate.bluetoothCallbackDelegate = self;
    _peripheralDelegate = [[BluetoothPeripheralDelegate alloc] initWithValuesProtocol:protocol];
    _peripheralDelegate.bluetoothCallbackDelegate = self;
    
    return self;
}

- (void)dealloc{
    [self stopSearchTimer];
    dispatch_async(self.centralQueue, ^{
        [self.centralManager stopScan];
        if (self.peripheral) {
            [self.centralManager cancelPeripheralConnection:self.peripheral];
        }
    });
}

- (BOOL)isCentralStatePoweredOn{
    __block CBManagerState state;
    dispatch_sync(self.centralQueue, ^{
        state = self.centralManager.state;
    });
    return state == CBManagerStatePoweredOn ? YES : NO;
}

- (void)notifyAboutCentralState:(CBManagerState)state{
    NSDate *timestamp = [NSDate date];
    
    NSDictionary *userInfo = @{kTimestampDataKey: timestamp,
                               kBleCentralStateDataKey: [NSNumber numberWithInteger:state]};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kBleCentralStateNotification
                                                        object:nil
                                                      userInfo:userInfo];
}

#pragma mark - Public interface

- (void)start{
    NSLog(@"%@: scan start", [self class]);
    if (self.centralManager == nil) {
#if BLE_RESTORE_ENABLED
        // @NOTE: will not use restoration feature for now
        // the profit is small if consider that
        // restoration will not work if bluetooth will be turned off
        // while app will be in background CBPeripheralManagerOptionRestoreIdentifierKey
        NSDictionary *centralOptions = @{CBCentralManagerOptionRestoreIdentifierKey: kCentralManagerId,
                                         CBCentralManagerRestoredStatePeripheralsKey: @YES,
                                         CBCentralManagerRestoredStateScanServicesKey: @YES,
                                         CBCentralManagerRestoredStateScanOptionsKey: @YES};
#else
        NSDictionary *centralOptions = nil;
#endif
        
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self.centralDelegate
                                                                   queue:self.centralQueue
                                                                 options:centralOptions];
    }
    else if ([self isCentralStatePoweredOn]) {
        dispatch_async(self.searchQueue, ^{
            [self search];
        });
    }
    else{
        NSLog(@"%@: failed to start search - central is not powered on", [self class]);
    }
}

- (void)tryDisconnectAndForget:(BOOL)forget{
    NSLog(@"%@: disconnect", [self class]);
    if (forget) {
        [self.peripheralScanModel setPeripheralUuidToSearch:nil];
    }
    dispatch_async(self.centralQueue, ^{
        if (self.centralManager && self.peripheral) {
            [self.centralManager cancelPeripheralConnection:self.peripheral];
        }
    });
}

- (BOOL)isReadyForBluetoothRequests{
    __block BOOL result = YES;
    dispatch_sync(self.centralQueue, ^{
        if (self.centralManager == nil || self.centralManager.state != CBManagerStatePoweredOn) {
            result = NO;
        }
        if (self.peripheral == nil || self.peripheral.state != CBPeripheralStateConnected) {
            result = NO;
        }
    });
    
    return result;
}

- (void)subscribe:(CBCharacteristic *)ch forNotification:(BOOL)subscribe{
    dispatch_async(self.centralQueue, ^{
        [self.peripheral setNotifyValue:subscribe forCharacteristic:ch];
    });
}

- (void)read:(CBCharacteristic *)ch{
    dispatch_async(self.centralQueue, ^{
        [self.peripheral readValueForCharacteristic:ch];
    });
}

- (BOOL)isBluetoothPoweredOn{
    __block BOOL result = NO;
    dispatch_sync(self.centralQueue, ^{
        if (self.centralManager && self.centralManager.state == CBManagerStatePoweredOn) {
            result = YES;
        }
    });
    
    return result;
}

- (BOOL)isDeviceConnected{
    __block BOOL result = NO;
    dispatch_sync(self.centralQueue, ^{
        if (self.peripheral && self.peripheral.state == CBPeripheralStateConnected) {
            result = YES;
        }
    });
    
    return result;
}

- (BOOL)isScanning{
    __block BOOL result = NO;
    dispatch_sync(self.centralQueue, ^{
        if (self.centralManager && [self.centralManager respondsToSelector:@selector(isScanning)]){
            result = self.centralManager.isScanning;
        }
    });
    
    return result;
}

#pragma mark - Bluetooth Central callbacks

- (BOOL)peripheralHasSameUUID:(NSUUID *)uuid{
    if (self.peripheral == nil || uuid == nil) {
        return NO;
    }
    return [self.peripheral.identifier.UUIDString isEqualToString:uuid.UUIDString];
}

- (void)centralManagerPoweredOn:(BOOL)poweredOn withState:(CBManagerState)state{
    
    [self notifyAboutCentralState:state];
    if (poweredOn == NO) {
        NSLog(@"%@: bluetooth not powered on - need to interrupt all scanning and discovering which is in progress", [self class]);
        [self stopSearchTimer];
        dispatch_async(self.centralQueue, ^{
            [self.centralManager stopScan];
        });
        return;
    }
    
    dispatch_async(self.searchQueue, ^{
        [self search];
    });
}

- (void)centralManagerConnectedTo:(__unused CBPeripheral *)peripheral at:(__unused NSDate *)time{
    if (self.peripheral == nil) {
        NSLog(@"%@: connected to peripheral but internal peripheral is nil", [self class]);
        return;
    }
    
    [self discover];
}

- (void)centralManagerFailConnectTo:(CBPeripheral *)peripheral{
    if ([self.peripheral.identifier isEqual:peripheral.identifier] == NO) {
        NSLog(@"%@: failed to connect to unknown peripheral %@", [self class], peripheral.identifier.UUIDString);
        return;
    }
    self.peripheral = nil;
    
    if ([self.peripheralScanModel instantScanEnabled]){
        NSLog(@"%@: will start peripheral scan after error", [self class]);
        dispatch_async(self.centralQueue, ^{
            [self startSearchPeripheralByNameOrByUuid];
        });
    }
}

- (void)centralManagerDisconnected:(CBPeripheral *)peripheral{
    
    if ([self.peripheral.identifier isEqual:peripheral.identifier] == NO) {
        NSLog(@"%@: disconnected with unknown peripheral %@", [self class], peripheral.identifier.UUIDString);
        return;
    }
    self.peripheral = nil;
    // @NOTE: force disconnect to try to clean ios bluetooth stack for next search for peripheral
    // by mistake in firmware it can't advertise itself after disconnect initiated by iOS in background
    [self.centralManager cancelPeripheralConnection:peripheral];
    
    // https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html
    
    if ([self.peripheralScanModel instantScanEnabled]){
        NSLog(@"%@: will start peripheral scan after disconnect", [self class]);
        dispatch_async(self.centralQueue, ^{
            [self startSearchPeripheralByNameOrByUuid];
        });
    }
}

- (BOOL)peripheralDiscoveredAllServices:(CBPeripheral *)peripheral{
    
    dispatch_async(self.centralQueue, ^{
        [self.peripheralApiFactory resetAllCheckmarksForServices];
        for (CBService* s in peripheral.services){
            NSLog(@"%@: going to discover characteristics for service %@", [self class], s.UUID.UUIDString);
            [peripheral discoverCharacteristics:[self.peripheralApiFactory characteristicsForService:s.UUID] forService:s];
        }
    });
    
    return [self areDiscoveredServicesMatchModel];
}

- (void)centralManagerFoundPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSUUID *uuid = [self.peripheralScanModel peripheralUuidToSearch];
    if (uuid) {
        if ([uuid isEqual:peripheral.identifier]) {
            NSLog(@"%@: found remembered peripheral %@ - going to stop scan and connect to it", [self class], uuid.UUIDString);
            dispatch_async(self.centralQueue, ^{
                [self.centralManager stopScan];
                self.peripheral = peripheral;
                [self.centralManager connectPeripheral:peripheral options:nil];
            });
            return;
        }
    }
    else{
        NSString *name = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
#if BLE_CHECK_FOR_RSSI
        if ([[self.peripheralScanModel namesToSearch] containsObject:name]){
            PeripheralInfo *deviceInfo = [PeripheralInfo new];
            deviceInfo.RSSI = RSSI;
            deviceInfo.peripheral = peripheral;
            deviceInfo.name = name;
            [self.peripheralScanModel addPeripheral:deviceInfo forName:name];
        }
#else
        if ([[self.peripheralScanModel namesToSearch] containsObject:name]){
            // stop infinit scan
            dispatch_async(self.centralQueue, ^{
                [self.centralManager stopScan];
                self.peripheral = peripheral;
                [self.centralManager connectPeripheral:peripheral options:nil];
            });
            return;
        }
#endif
    }
}

- (BOOL)peripheralDiscoveredCharacteristics:(CBPeripheral *)peripheral forService:(CBService *)service{
    
    for (CBCharacteristic *ch in service.characteristics) {
        if ([[self.peripheralApiFactory characteristicsForService:service.UUID] containsObject:ch.UUID] == NO) {
            NSLog(@"%@: service %@ contains unknown characteristics", [self class], service.UUID.UUIDString);
            return NO;
        }
    }
    
    [self.peripheralApiFactory saveCharacteristics:service.characteristics forService:service.UUID];
    [self.peripheralApiFactory markServiceAsCheckedForUuid:service.UUID];
    
    if ([self.peripheralApiFactory isInterfaceCompletelyMatch]) {
        [self.peripheralScanModel setPeripheralUuidToSearch:peripheral.identifier];
    }
    
    return YES;
}

- (void)centralManager:(__unused CBCentralManager *)central willRestoreState:(__unused NSDictionary *)state{
    
#if BLE_RESTORE_ENABLED
    if (self.centralManager.state == CBCentralManagerStatePoweredOn){
        NSArray *peripherals = state[CBCentralManagerRestoredStatePeripheralsKey];
        if (peripherals && peripherals.count != 0){
            CBPeripheral *peripheral = [peripherals objectAtIndex:0];
            
            NSLog(@"%@: going to reconnect with restored peripheral", [self class]);
            dispatch_async(self.centralQueue, ^{
                self.peripheral = peripheral;
                [central connectPeripheral:peripheral options:nil];
            });
        }
        else{
            NSLog(@"%@: going to start scan at restoring", [self class]);
            if ([self isCentralStatePoweredOn]) {
                dispatch_async(self.searchQueue, ^{
                    [self search];
                });
            }
        }
    }
#endif
}

#pragma mark - Scan for remembered peripheral

- (BOOL)tryConnectToCachedPeripheral{
    NSUUID *uuid = [self.peripheralScanModel peripheralUuidToSearch];
    if (uuid == nil) {
        return NO;
    }
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[uuid]];
    BOOL peripheralRetrieved = NO;
    CBPeripheral *peripheral;
    
    if (peripherals && peripherals.count > 0){
        if (peripherals.count > 1){
            NSLog(@"%@: strange but retrieved peripherals count %lu > 1", [self class], (unsigned long)peripherals.count);
        }
        
        id obj = [peripherals objectAtIndex:0];
        if ([obj isKindOfClass:[CBPeripheral class]]){
            peripheral = obj;
            peripheralRetrieved = YES;
        }
    }
    
    if (peripheralRetrieved){
        self.peripheral = peripheral;
        NSLog(@"%@: going to reconnect to retrived peripheral", [self class]);
        [self.centralManager connectPeripheral:peripheral options:nil];
        return YES;
    }
    else{
        return NO;
    }
}

- (void)search{
    __block BOOL alreadyScanning = NO;
    
    // Locked block
    dispatch_sync(self.centralQueue, ^{
        // http://stackoverflow.com/questions/28280025/core-bluetooth-doesnt-find-peripherals-when-scanning-for-specific-cbuuid?rq=1
        if ([self.centralManager respondsToSelector:@selector(isScanning)]){
            if (self.centralManager.isScanning == YES){
                alreadyScanning = YES;
            }
        }
        else{
            NSLog(@"%@: can't check if already scanning or not - if not on iOS > 9.x", [self class]);
        }
    });
    
    if (alreadyScanning) {
        NSLog(@"%@: already scanning - ignore", [self class]);
        return;
    }
    
    if ([self.peripheralScanModel autoScanEnabled] == NO){
        NSLog(@"%@: exit search - auto scan disabled", [self class]);
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    
    dispatch_async(self.centralQueue, ^{
        
        __typeof__(self) self = weakSelf;
        if (self) {
            NSUUID *uuid = [self.peripheralScanModel peripheralUuidToSearch];
            if (uuid == nil){
                // no any remembered peripherals - need to scan and find with name
                NSLog(@"%@: will start scan for unknown nearest applicator by name", [self class]);
                [self startSearchPeripheralByNameOrByUuid];
            }
            else{
#if RETRIEVE_PERIPHERALS
                if ([self tryConnectToCachedPeripheral] == NO) {
                    NSLog(@"%@: retrievePeripheralsWithIdentifiers returned empty array - need to start simple scan", [self class]);
                    [self startSearchPeripheralByNameOrByUuid];
                }
#else
                // run simple scan, because by using retrievePeripheralsWithIdentifiers
                // sometimes if device is powered off or out of range
                // then in background - application will not connect to it
                // and will be killed by system
                // because no any tasks for background
                NSLog(@"%@: will start scan for remembered applicator", [self class]);
                [self startSearchPeripheralByNameOrByUuid];
#endif
            }
        }
    });
}

- (void)startSearchPeripheralByNameOrByUuid{
    [self startSearchPeripheralByNameOrByUuidWithCounterReset:YES];
}

- (void)startSearchPeripheralByNameOrByUuidWithCounterReset:(BOOL)resetCounter{
    
    [self.peripheralScanModel clearFoundPeripheralsForEveryName];
#if BLE_CHECK_FOR_RSSI
    NSUUID *uuid = [self.peripheralScanModel peripheralUuidToSearch];
    if (uuid == nil){
        // no need to check for RSSI if app has remembered device UUID
        if (resetCounter) {
            // reset logs timer counter
            counter = 0;
        }
        [self startScanTimer];
    }
#endif
    
    // That method already called in central queue
    // @NOTE: in background it's mandatory rule
    // to specify searched services
    NSArray<CBUUID *> *scanServices = [self.peripheralApiFactory backgroundScanServices];
    [self.centralManager scanForPeripheralsWithServices:scanServices
                                                options:nil];
}

#pragma mark - Search timer logic

- (dispatch_source_t)searchTimerSource{
    if (_searchTimerSource == nil) {
        _searchTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.searchQueue);
        if (_searchTimerSource) {
            __weak __typeof__(self) weakSelf = self;
            dispatch_source_set_event_handler(self.searchTimerSource, ^{
                __typeof__(self) strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf stopSearchTimer];
                    [strongSelf handleScanTimerExpiration];
                }
            });
        }
    }
    return _searchTimerSource;
}

- (void)startSearchTimerWithSeconds:(NSUInteger)seconds{
    int64_t delta = (int64_t)seconds * (int64_t)NSEC_PER_SEC;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delta);
    uint64_t interval = (uint64_t)seconds * NSEC_PER_SEC;
    
    dispatch_source_t source = [self searchTimerSource];
    dispatch_source_set_timer(source, startTime, interval, NSEC_PER_SEC / 10);
    dispatch_resume(source);
}

- (void)stopSearchTimer{
    dispatch_source_t source = _searchTimerSource;
    if (source){
        dispatch_source_cancel(source);
        _searchTimerSource = nil;
    }
}

- (void)suspendSearchTimer{
    dispatch_source_t source = [self searchTimerSource];
    if (source){
        dispatch_suspend(source);
    }
}

- (void)startScanTimer{
    NSUInteger seconds = [self.peripheralScanModel scanTimeInSeconds];
    
    // actually that start scan timer method already
    // called on centralQueue
    if (_searchTimerSource != nil) {
        [self suspendSearchTimer];
    }
    [self startSearchTimerWithSeconds:seconds];
    // 24 h* 60 = 1440
    // to have 50 traces maximum
    // every 28.8 minutes = 1728 seconds
    counter += seconds;
    if (counter > 1727) {
        NSLog(@"%@: already searched for 28.8 minutes", [self class]);
        counter = 0;
    }
}

- (void)handleScanTimerExpiration{

    if ([self.peripheralScanModel somePeripheralFound] == NO){
        // commenting out next log to not flud log file
        if ([self.peripheralScanModel instantScanEnabled]){
            dispatch_async(self.centralQueue, ^{
                [self.centralManager stopScan];
                [self startSearchPeripheralByNameOrByUuidWithCounterReset:NO];
            });
            return;
        }
    }
    
    // need to find peripheral with highest RSSI
    id<PeripheralBasicInfoProtocol> closestPeripheral = [self.peripheralScanModel find];
    if (closestPeripheral == nil) {
        NSLog(@"%@: failed to find device with highest RSSI", [self class]);
        dispatch_async(self.centralQueue, ^{
            [self.centralManager stopScan];
            [self startSearchPeripheralByNameOrByUuid];
        });
        return;
    }
    NSLog(@"%@: going to connect to peripheral with highest RSSI %@", [self class], closestPeripheral.RSSI);
    dispatch_async(self.centralQueue, ^{
        
        [self.centralManager stopScan];
        self.peripheral = closestPeripheral.peripheral;
        
        // probably device will be busy / connected to another application
        // by mistake of a user on the same or different iphone
        // and it can't be checked by comparing current Peripheral state
        // to Connected or Connecting, it always at this moment showing - Disconnected
        // so, as a solution it is possible to run timer to detect connection timeout
        
        [self.centralManager connectPeripheral:self.peripheral options:nil];
    });
}

#pragma mark - Discover services and characteristics

- (BOOL)areDiscoveredServicesMatchModel{
    BOOL matched = YES;
    // Usually it should be only one
    NSArray *currentServices = self.peripheral.services;
    if (currentServices && currentServices.count > 0){
        
        NSLog(@"%@: will start checking for already discovered services", [self class]);
        
        NSArray<CBUUID *> *neededServices = [self.peripheralApiFactory foregroundServices];
        for (CBService *obj in currentServices) {
            BOOL foundOne = NO;
            for (CBUUID *serviceUuid in neededServices) {
                if ([obj.UUID isEqual:serviceUuid]) {
                    foundOne = YES;
                    break;
                }
            }
            if (foundOne == NO) {
                NSLog(@"%@: service %@ not found in already discovered services", [self class], obj.UUID.UUIDString);
                matched = NO;
                break;
            }
        }
    }
    else{
        matched = NO;
    }
    
    return matched;
}

- (void)discover{
    if (self.peripheral == nil) {
        NSLog(@"%@: failed to discover services - peripheral is nil", [self class]);
        return;
    }
    
    self.peripheral.delegate = self.peripheralDelegate;
    BOOL needToDiscoverServicesFromTheScratch = ![self areDiscoveredServicesMatchModel];
    
    if (needToDiscoverServicesFromTheScratch) {
        NSLog(@"%@: going to discover services of peripheral from the scratch", [self class]);
        dispatch_async(self.centralQueue, ^{
            [self.peripheral discoverServices:[self.peripheralApiFactory foregroundServices]];
        });
    }
    else{
        NSLog(@"%@: going to discover characteristics for already discovered services - %ld", [self class], (unsigned long)self.peripheral.services.count);
        dispatch_async(self.centralQueue, ^{
            [self.peripheralApiFactory resetAllCheckmarksForServices];
            NSArray *currentServices = self.peripheral.services;
            for (CBService *service in currentServices) {
                [self.peripheral discoverCharacteristics:[self.peripheralApiFactory characteristicsForService:service.UUID] forService:service];
            }
        });
        
    }
}

@end
