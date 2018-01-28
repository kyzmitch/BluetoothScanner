//
//  AppDelegate.m
//  ScannerIOSDemo
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import "AppDelegate.h"
#import <BLEScanner/BaseBluetoothScanner.h>
#import <BLEScanner/BluetoothScanModel.h>
#import <BLEScanner/BluetoothValuesProtocol.h>
#import <FitbitBleFramework/FitbitFlexServicesFactory.h>
#import "ViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) id<BluetoothEngineInterface> scanner;
@property (nonatomic, strong) id<BluetoothValuesProtocol> deviceValuesModel;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self setupUi];
    [self setupPeripheral];
    return YES;
}

- (void)setupUi {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    ViewController *ctrl = [storyboard instantiateViewControllerWithIdentifier:@"mainScreen"];
    ctrl.view.frame = [UIScreen mainScreen].bounds;
    self.window.rootViewController = ctrl;
    [self.window makeKeyAndVisible];
}

- (void)setupPeripheral {
    FitbitFlexServicesFactory *deviceServicesModel = [FitbitFlexServicesFactory new];
    BluetoothScanModel *scanModel = [[BluetoothScanModel alloc] initWithSearchedPeripheralName:@"Flex"];
    self.deviceValuesModel = nil;
    
    self.scanner = [[BaseBluetoothScanner alloc] initWithPeripheralInterfaceFactory:deviceServicesModel scanModel:scanModel protocol:self.deviceValuesModel];
    [self.scanner start];
    
}

@end
