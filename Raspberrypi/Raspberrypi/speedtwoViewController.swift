//
//  speed2ViewController.swift
//  Raspberrypi
//
//  Created by Brandon Mai Nguyen on 10/14/18.
//  Copyright © 2018 Brandon Mai Nguyen. All rights reserved.
//

import UIKit
import CoreBluetooth

class speedtwoViewController: UIViewController, CBPeripheralManagerDelegate, UITextViewDelegate, UITextFieldDelegate
{
    //Initialize values
    @IBOutlet weak var baseTextView: UITextView!
    @IBOutlet weak var Speedometerdisplay: UILabel!
    @IBOutlet weak var sliderOutlet: UISlider!
    //Data in and Data out
    @objc var peripheralManager: CBPeripheralManager?
    @objc var peripheral: CBPeripheral!
    private var consoleAsciiText:NSAttributedString? = NSAttributedString(string: "")
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        //Create and start the peripheral manager
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        //-Notification for updating the text view with incoming text
        updateIncomingData()
    }
    
    //this function recieves data from the arudino and displays it.
    @objc func updateIncomingData ()
    {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Notify"), object: nil , queue: nil)
        {
            notification in
            let appendString = "\n"
            let myFont = UIFont(name: "Helvetica Neue", size: 15.0)
            let myAttributes2 = [NSAttributedStringKey.font: myFont!, NSAttributedStringKey.foregroundColor: UIColor.red]
            let attribString = NSAttributedString(string: "[Incoming]: " + (characteristicASCIIValue as String) + appendString, attributes: myAttributes2)
            let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
            self.baseTextView.attributedText = NSAttributedString(string: characteristicASCIIValue as String , attributes: myAttributes2)
            
            newAsciiText.append(attribString)
            
            self.consoleAsciiText = newAsciiText
            self.baseTextView.attributedText = self.consoleAsciiText
        }
    }
    
    //this function sends data out
    func outgoingData (data: String)
    {
        let appendString = "\n"
        
        let inputText = String(data)
        
        let myFont = UIFont(name: "Helvetica Neue", size: 15.0)
        let myAttributes1 = [NSAttributedStringKey.font: myFont!, NSAttributedStringKey.foregroundColor: UIColor.blue]
        
        writeValue(data: inputText)
        
        let attribString = NSAttributedString(string: "[Outgoing]: " + inputText + appendString, attributes: myAttributes1)
        let newAsciiText = NSMutableAttributedString(attributedString: self.consoleAsciiText!)
        newAsciiText.append(attribString)
        
        consoleAsciiText = newAsciiText
        baseTextView.attributedText = consoleAsciiText
        
    }
    
    // Write functions
    func writeValue(data: String)
    {
        let data = data
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        if let blePeripheral = blePeripheral
        {
            if let txCharacteristic = txCharacteristic
            {
                blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    //slider changes the speed and sends a integer value
    @IBAction func Speed(_ sender: UISlider)
    {
        
        Speedometerdisplay.text = String(Int(sliderOutlet.value))
        
        outgoingData(data: String(Int(sliderOutlet.value)))
     
        
        writeCharacteristic(val: Int8(Int(sliderOutlet.value)))
    }
    
    //send the slider value out using "writeCharacteristic"
    func writeCharacteristic(val: Int8)
    {
        var val = val
        let ns = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
        blePeripheral?.writeValue(ns as Data, for: txCharacteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    //updates the text field
   // func textFieldShouldReturn(_ textField: UITextField) -> Bool
    //{
     //   textField.resignFirstResponder()
     //   outgoingData()
     //   return(true)
    //}
    
    //prints out an error if not detected
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?)
    {
        if let error = error
        {
            print("\(error)")
            return
        }
    }
    
    //Prints a message stating that the device is on and connected
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        if peripheral.state == .poweredOn
        {
            return
        }
        print("Peripheral manager is running")
    }
    
    //Check when someone subscribe to our characteristic, start sending the data
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic)
    {
        print("Device subscribe to characteristic")
    }
    
}
