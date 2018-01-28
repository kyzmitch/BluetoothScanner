//  BluetoothScanner
//
//  Created by Andrei Ermoshin on 28/01/2018.
//  Copyright © 2018 Andrei Ermoshin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BaseDeviceServiceProtocol
@required
- (void)tryConnect;
- (void)disconnectAndForget:(BOOL)forget;
- (void)readValueByChName:(NSString *)chUuid;
- (void)subscribe:(BOOL)enable forChName:(NSString *)chUuid;

@end
