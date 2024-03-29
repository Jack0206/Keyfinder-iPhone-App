//
//  KeyChainViewController.m
//  Key_chain
//
//  Created by Brandon Chen on 1/8/14.
//  Copyright (c) 2014 Brandon Chen. All rights reserved.
//

#import "KeyChainViewController.h"
#import "BLECentralSingleton.h"
#import "KeyChainDetailViewController.h"
#import <Foundation/NSKeyedArchiver.h>
#import "KeychainProfile.h"
#import "Keychain.h"

@interface KeyChainViewController ()



@end

@implementation KeyChainViewController

@synthesize BLECentralManager;
@synthesize registerList;
@synthesize Peripheral_list;
@synthesize repeatingTimer;
@synthesize Edit_Button;
//@synthesize EditMode;

//@synthesize locationManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.hidesBackButton = YES;
    registerList = [BLECentralSingleton getBLERegistered_peripheral_list];
    BLECentralManager = [BLECentralSingleton getBLECentral];
    BLECentralManager.delegate = self;
    Peripheral_list = [BLECentralSingleton getBLEPeripheral_list];
    registerList = [BLECentralSingleton getBLERegistered_peripheral_list];
    [self.tableView reloadData]; // to reload selected cell

    // Start scan.
    [BLECentralManager stopScan];
    [BLECentralManager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"0xffa1"]] options:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    /*
     When a row is selected, the segue creates the detail view controller as the destination.
     Set the detail view controller's detail item to the item associated with the selected row.
     */
    if ([[segue identifier] isEqualToString:@"ToKeyChainDetail"]) {
        
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        KeyChainDetailViewController *detailViewController = [segue destinationViewController];
        detailViewController.keychain = [registerList objectAtIndex:selectedRowIndex.row];
    }
}


-(void)startRepeatingTimer{
    
    // Cancel a preexisting timer.
    [self.repeatingTimer invalidate];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self selector:@selector(targetMethod:)
                                                    userInfo:[self userInfo] repeats:YES];
    self.repeatingTimer = timer;
}


- (NSDictionary *)userInfo {
    
    return @{ @"StartDate" : [NSDate date] };
}

- (void)targetMethod:(NSTimer*)theTimer {
    NSDate *startDate = [[theTimer userInfo] objectForKey:@"StartDate"];

}

- (void)invocationMethod:(NSDate *)date {
    //    NSLog(@"Invocation for timer started on %@", date);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [registerList count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if(cell==nil){
        
        cell = [ [UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    
    Keychain *keychain = [registerList objectAtIndex:indexPath.row];
    
    cell.textLabel.text = keychain.configProfile.name;
    cell.detailTextLabel.text = [keychain connectionState];
    
    /*UILabel *label;
    
    label = (UILabel *)[cell viewWithTag:1];
    
    label.text = keychain.configProfile.name;*/
  
    
    return cell;
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    return UITableViewCellEditingStyleDelete;
}


     
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (editingStyle == UITableViewCellEditingStyleDelete){
        Keychain* key = [registerList objectAtIndex:indexPath.row];
        if(key.peripheral){
            [BLECentralManager cancelPeripheralConnection:key.peripheral];
        }
        [registerList removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadData];
    }
}

- (IBAction)Enter_edit_mode:(id)sender {
    static int flag = 0;
    if(!flag) {
       [self.tableView setEditing:YES animated:YES];
        [self.Edit_Button setTitle:@"Done" forState:UIControlStateNormal];
        flag = 1;
    }
    else {
        [self.tableView setEditing:NO animated:YES];
        [self.Edit_Button setTitle:@"Edit" forState:UIControlStateNormal];
        flag = 0;
    }
}


- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"Peripheral %@ connected",[peripheral.identifier UUIDString]);
    
    for(Keychain* key in registerList) {
        if (key.peripheral == peripheral){
            key.peripheral.delegate = key;
            [peripheral discoverServices:[NSArray arrayWithObjects:[CBUUID UUIDWithString:@"0xffa1"],[CBUUID UUIDWithString:@"0xffa5"],[CBUUID  UUIDWithString:@"0xffa6"],[CBUUID  UUIDWithString:@"0xffa7"],nil ]];
            [self.tableView reloadData];
            break;
        }
    }
    
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    
    NSLog(@"####%@ disconnected#####",peripheral.name);
    
    for(Keychain* key in registerList) {
        if (key.peripheral == peripheral){
            if(key.configProfile.disconnection_alert){
                [key alert:@"Disconnected"];
            }
            NSDictionary* options = @{CBConnectPeripheralOptionNotifyOnConnectionKey: @YES,
                                      CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES,
                                      CBConnectPeripheralOptionNotifyOnNotificationKey: @YES};
            
            [BLECentralManager connectPeripheral:peripheral options: options];
            [self.tableView reloadData];
            break;

        }
    }
    
}


- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@ %@ %@", peripheral.name, peripheral.identifier, advertisementData);
    
    for(Keychain* key in registerList){
        if ([key.configProfile.BDaddress isEqual:[advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey]]){
            NSDictionary* options = @{CBConnectPeripheralOptionNotifyOnConnectionKey: @YES,
                                      CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES,
                                      CBConnectPeripheralOptionNotifyOnNotificationKey: @YES};
            key.peripheral = peripheral;
            [BLECentralManager connectPeripheral:peripheral options:options];
            break;
        }
    }
    
}



- (void) centralManager:(CBCentralManager *)central
didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    NSLog(@"Currently connected peripherals :");

}

- (void) centralManager:(CBCentralManager *)central
 didRetrievePeripherals:(NSArray *)peripherals {
    NSLog(@"Currently known peripherals :");
    int i = 0;
    for(CBPeripheral *peripheral in peripherals) {
        NSLog(@"[%d] - peripheral : %@ with UUID : %@",i,peripheral,peripheral.UUID);
        //Do something on each known peripheral.
    }
}





- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    //self.cBReady = false;
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            //self.cBReady = true;
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CoreBluetooth BLE hardware is resetting");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            break;
        default:
            break;
    }
}


@end
