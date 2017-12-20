//
//  ConnexionViewController.swift
//  iVane
//
//  Created by Rémy Seba on 27/06/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData

class ConnexionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var PeripheralsTableView: UITableView!
    @IBOutlet weak var charTextField: UITextField!
    @IBOutlet weak var serviceTextField: UITextField!
    
    
    var peripherals = [String]()
    
    
    
    var context: NSManagedObjectContext!
    var devices = [Device]()
    
    // declarations Variables BLUETOOTH
    var manager:CBCentralManager!
    var connectedPeripheral:CBPeripheral!
    var vaneCharacteristic:CBCharacteristic?
    
    
    var deviceName = ""
    var serviceUUID = CBUUID(string: "FFE0")
    var charUUID = CBUUID(string: "FFE1")
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

         context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Device", for: indexPath) as! ConnexionTableViewCell
        
        cell.bleNameLabel.text = peripherals[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        self.manager.stopScan()
        deviceName = peripherals[indexPath.row]
        
    }
    
    
    
    //MARK:- scan for devices
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
            
        case .poweredOn:
            print("powered on")
            central.scanForPeripherals(withServices: nil, options: nil)
            
        case .poweredOff:
            print("powered off")
            
        case .resetting:
            print("resetting")
            
        case .unauthorized:
            print("unauthorized")
            
        case .unknown:
            print("unknown")
            
        case .unsupported:
            print("unsupported")
        }
    }
    
    //MARK:- connect to a device
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        if let device = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("Appareil: \(peripheral)")
            
            self.peripherals.append(device)
        }
        
        
        self.PeripheralsTableView.reloadData()
    }
    
    @IBAction func retenir(_ sender: Any) {
        if((charTextField.text != "")&&(serviceTextField.text != "")&&(deviceName != "")){
            
            
            //Suppression de l'ancien lieu
            let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "Device"))
            do {
                try self.context.execute(DelAllReqVar)
                print("Supprimer")
            }
            catch {
                print(error)
                let errorAlert = UIAlertController(title: "Oops...", message: "Une erreur s'est produite", preferredStyle: .alert)
                let errorAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                }
                errorAlert.addAction(errorAction)
                self.present(errorAlert, animated: true,completion: nil)
            }
            
            //Sauvegarde dans le Core Data
            let appareil = Device(context: self.context)
            
            appareil.name = deviceName
            appareil.serviceUUID = serviceTextField.text!
            appareil.charUUID = charTextField.text!
            
            
            
            do{
                try self.context.save()
                print("sauvegarder")
                let SaveAlert = UIAlertController(title: "📟Vane enregistrer", message: "L'adresse vient d'être enregistrée, retournée sur votre carte", preferredStyle: .alert)
                let SaveAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                }
                SaveAlert.addAction(SaveAction)
                self.present(SaveAlert, animated: true,completion: nil)
                
            }catch{
                print("errreur")
            }
        }

    }
    
    
    

}
