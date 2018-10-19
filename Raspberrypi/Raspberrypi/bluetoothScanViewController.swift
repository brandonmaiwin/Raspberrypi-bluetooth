//
//  bluetoothScanViewController.swift
//  Raspberrypi
//
//  Created by Brandon Mai Nguyen on 10/9/18.
//  Copyright © 2018 Brandon Mai Nguyen. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

var txCharacteristic : CBCharacteristic?
var rxCharacteristic : CBCharacteristic?
var blePeripheral : CBPeripheral?
var characteristicASCIIValue = NSString()

class bluetoothScanViewController : UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource
{

    //Variable Initialization
    @objc var centralManager : CBCentralManager!
    @objc var RSSIs = [NSNumber]()
    @objc var data = NSMutableData()
    @objc var writeData: String = ""
    @objc var peripherals: [CBPeripheral] = []
    @objc var characteristicValue = [CBUUID: NSData]()
    @objc var timer = Timer()
    @objc var characteristics = [String : CBCharacteristic]()
    
    //UI Variables
    @IBOutlet weak var baseTableView: UITableView!
    @IBOutlet weak var refreshButton: UIButton!
    
    // Refresh Button Action
    @IBAction func refreshAction(_ sender: Any)
    {
        disconnectFromDevice()
        self.peripherals = []
        self.RSSIs = []
        self.baseTableView.reloadData()
        startScan()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.baseTableView.delegate = self
        self.baseTableView.dataSource = self
        self.baseTableView.reloadData()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        let backButton = UIBarButtonItem(title: "Disconnect", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        disconnectFromDevice()
        super.viewDidAppear(animated)
        refreshScanView()
        print("View Cleared")
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        print("Stop Scanning")
        centralManager?.stopScan()
    }
    
    //Initailizing CBCentralManager to start and begin running. Using the scanForPeripherials method
    @objc func startScan()
    {
        peripherals = []
        print("Now Scanning...")
        self.timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        Timer.scheduledTimer(timeInterval: 17, target: self, selector: #selector(self.cancelScan), userInfo: nil, repeats: false)
    }
    
    //To cancel the scan, we use the stopScan() method
    @objc func cancelScan()
    {
        self.centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripherals.count)")
    }
    
    //refreshes the Scan View
    @objc func refreshScanView()
    {
        baseTableView.reloadData()
    }
    
    //-Terminate all Peripheral Connection
    @objc func disconnectFromDevice ()
    {
        if blePeripheral != nil
        {
            centralManager?.cancelPeripheralConnection(blePeripheral!)
        }
    }
    
    //Restores Central Manager delegate if something went wrong
    @objc func restoreCentralManager()
    {
                centralManager?.delegate = self
    }
    
    /*
     Called when the central manager discovers a peripheral while scanning. Also, once peripheral is connected, cancel scanning.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        blePeripheral = peripheral
        self.peripherals.append(peripheral)
        self.RSSIs.append(RSSI)
        peripheral.delegate = self
        self.baseTableView.reloadData()
        if blePeripheral == nil
        {
            print("Found new pheripheral devices with services")
            print("Peripheral name: \(String(describing: peripheral.name))")
            print("**********************************")
            print ("Advertisement Data : \(advertisementData)")
        }
    }
    
    //Connecting to bluetooth
    @objc func connectToDevice () {
        centralManager?.connect(blePeripheral!, options: nil)
    }
    

     //This method is invoked when a call to connect(_:options:) is successful. You typically implement this method to set the peripheral’s delegate and to discover its services.
    //-Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*****************************")
        print("Connection complete")
        print("Peripheral info: \(String(describing: blePeripheral))")
        
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager?.stopScan()
        print("Scan Stopped")
        
        //Erase data that we might have
        data.length = 0
        
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices([BLEService_UUID])
        
        
        //Once connected, move to new view controller to manager incoming and outgoing data
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let uartViewController = storyboard.instantiateViewController(withIdentifier: "speedtwoViewController") as! speedtwoViewController
        
        uartViewController.peripheral = peripheral
        
        navigationController?.pushViewController(uartViewController, animated: true)
    }
    
    
    
    //Fail to connect notification and check
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        if error != nil
        {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    @objc func disconnectAllConnection() {
        centralManager.cancelPeripheralConnection(blePeripheral!)
    }
    
    //Print error message if device is not discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        print("*******************************************************")
        if ((error) != nil)
        {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services
        {
            peripheral.discoverCharacteristics(nil, for: service)
            // bleService = service
        }
        print("Discovered Services: \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        
        print("*******************************************************")
        
        if ((error) != nil)
        {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else
        {
            return
        }
        print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics
        {
            //looks for the right characteristic
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)
            {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx)
            {
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    // Getting Values From Characteristic
    
    /*After you've found a characteristic of a service that you are interested in, you can read the characteristic's value by calling the peripheral "readValueForCharacteristic" method within the "didDiscoverCharacteristicsFor service" delegate.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        
        if characteristic == rxCharacteristic
        {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
            {
                characteristicASCIIValue = ASCIIstring
                print("Value Recieved: \((characteristicASCIIValue as String))")
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: nil)
                
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        print("*******************************************************")
        
        if error != nil
        {
            print("\(error.debugDescription)")
            return
        }
        if ((characteristic.descriptors) != nil)
        {
            for x in characteristic.descriptors!
            {
                let descript = x as CBDescriptor?
                print("function name: DidDiscoverDescriptorForChar \(String(describing: descript?.description))")
                print("Rx Value \(String(describing: rxCharacteristic?.value))")
                print("Tx Value \(String(describing: txCharacteristic?.value))")
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    {
        print("*******************************************************")
        if (error != nil)
        {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        }
        else
        {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying)
        {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        print("Disconnected")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        guard error == nil else
        {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?)
    {
        guard error == nil else
        {
            print("Error discovering services: error")
            return
        }
        print("Succeeded!")
    }
    
    //Table View Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //Connect to device where the peripheral is connected
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! peripheralView
        let peripheral = self.peripherals[indexPath.row]
        let RSSI = self.RSSIs[indexPath.row]
        
        
        if peripheral.name == nil
        {
            cell.peripheralLabel.text = "nil"
        }
        else
        {
            cell.peripheralLabel.text = peripheral.name
        }
        cell.rssiLabel.text = "RSSI: \(RSSI)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        blePeripheral = peripherals[indexPath.row]
        connectToDevice()
    }
    
    /*
     Invoked when the central manager’s state is updated.
     This is where we kick off the scan if Bluetooth is turned on.
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        if central.state == CBManagerState.poweredOn
        {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            print("Bluetooth Enabled")
            startScan()
            
        }
        else
        {
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
            
            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertControllerStyle.alert)
            let action = UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    //This function returns the screen back to the prior screen
    @IBAction func backTap(_ sender: Any)
    {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
