//
//  BluetoothConstants.h
//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BleReturnCode) {
    kBleNoError,
    kBleNoPeripheralParametersToSearch,
    kBleCentralIsNotPoweredOn,
    kBleSearchedPeripheralFoundAndConnected,
    kBleConnectedWithNotSearchedPeripheral,
    kBleFailedToConnectPeripheral,
    kBlePeripheralDisconnected,
    kBleFailedDiscoverServices,
    kBleNoServicesDiscovered,
    kBleNotAllServicesDiscovered,
    kBleCharacteristicsDiscoveringDone,
    kBleFailedToDiscoverCharacteristics,
    kBleFailedToSubscribeForNotifications
};

typedef NS_ENUM(NSUInteger, BleStartScanResult) {
    kStartDeviceScanUnknown,
    kStartDeviceScanAlreadyScanning,
    kStartDeviceScanBluetoothIsNotPoweredOn,
    kStartDeviceScanOk
};

extern NSString * const kConnectWithPeripheralNotification;
extern NSString * const kBleScanCharacteristicsNotification;
extern NSString * const kBleCentralStateNotification;
extern NSString * const kBlePeripheralStateNotification;
extern NSString * const kBleSubscribeStateNotification;
extern NSString * const kTimestampDataKey;
extern NSString * const kBleCentralStateDataKey;
extern NSString * const kPeripheralStateDataKey;
extern NSString * const kBlePeripheralConnectStatusDataKey;
extern NSString * const kBlePeripheralUuidDataKey;
extern NSString * const kBlePeripheralNameDataKey;
extern NSString * const kBleCharacteristicsScanStatusDataKey;
extern NSString * const kBleSubscriptionStateDataKey;
extern NSString * const kPairedPeripheralUuid;

extern NSUInteger const kDevicesScanTime;
extern NSString * const kCentralManagerId;

#define BLE_RESTORE_ENABLED 0
#define BLE_CHECK_FOR_RSSI 1
#define RETRIEVE_PERIPHERALS 0

