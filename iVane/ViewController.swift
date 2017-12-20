//
//  ViewController.swift
//  vane
//
//  Created by Remy Krysztofiak on 13/05/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreBluetooth

class ViewController: UIViewController, UISearchBarDelegate, CBCentralManagerDelegate, CBPeripheralDelegate{
    
//    Declaration
    
    @IBOutlet weak var mapView: MKMapView!                  // mapView
    
    var context: NSManagedObjectContext!                    // Variable Core Data Récupère les données du CoreData
    
    var searchController:UISearchController!                // Barre de recherche de localisation
    var annotation:MKAnnotation!                            // annotation
    var localSearchRequest:MKLocalSearchRequest!            // Requete de recherche de localisation
    var localSearch:MKLocalSearch!                          // Point de recherche
    var localSearchResponse:MKLocalSearchResponse!          // Variable de localisation
    var error:NSError!                                      // Erreur
    var pointAnnotation:MKPointAnnotation!                  // Point d'annotation
    var pinAnnotationView:MKPinAnnotationView!// ----------------------
    
    @IBOutlet weak var directionLabel: UILabel! // Label de direction (degrès)
    @IBOutlet weak var vitesseLabel: UILabel!   // Label de vitesse du vent
    @IBOutlet weak var tempLabel: UILabel!      // Label de température
    @IBOutlet weak var stateLabel: UILabel!
    
    
    var weather = Meteo(pDirection: 0, pSpeed: 0, pTemp: 0, pEtat: "")
    
    var timer = Timer()
    var minuteur = 10
    var locations = [Lieu]()
    var devices = [Device]()
    var longitude = ""
    var latitude = ""
    var nom = ""
    
    // declarations Variables BLUETOOTH
    var manager:CBCentralManager!
    var connectedPeripheral:CBPeripheral!
    var vaneCharacteristic:CBCharacteristic?
    
    
    var deviceName = ""
    var serviceUUID = CBUUID(string: "FFE0")
    var charUUID = CBUUID(string: "FFE1")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stateLabel.text = ""
        self.stateLabel.layer.masksToBounds = true
        self.stateLabel.layer.cornerRadius = 12
        
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        loadLieu()
        loadDevice()
        
        for location in locations{
            self.nom = location.nom!
            self.longitude = location.longitude!
            self.latitude = location.latitude!
        }
        if(locations.isEmpty){
            
        }else{
            self.weather.forcast(long: self.longitude, lat: self.latitude)
        }
        
        
        for device in devices{
            self.deviceName = device.name!
            self.serviceUUID = CBUUID(string: device.serviceUUID!)
            self.charUUID = CBUUID(string: device.charUUID!)
        }
        if(deviceName != ""){
            manager = CBCentralManager(delegate: self, queue: nil)
        }
        
        
        callMap()
        intervalMeteo()
    }
    
    
    func intervalMeteo(){
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(minuteur), target: self, selector: #selector(self.findMeteo), userInfo: nil, repeats: true)
    }
    
    @IBAction func showSearchBar(_ sender: Any) {
        searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringfPresentation = false
        self.searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){                                                                                        
        
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        if self.mapView.annotations.count != 0{
            annotation = self.mapView.annotations[0]
            self.mapView.removeAnnotation(annotation)
        }
        
        localSearchRequest = MKLocalSearchRequest()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (localSearchResponse, error) -> Void in
            
            if localSearchResponse == nil{
                let alertController = UIAlertController(title: nil, message: "Lieu inconnu", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Rejeter", style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            self.pointAnnotation = MKPointAnnotation()
            self.pointAnnotation.title = searchBar.text
            self.pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: localSearchResponse!.boundingRegion.center.latitude, longitude: localSearchResponse!.boundingRegion.center.longitude)
            
            self.longitude = String(self.pointAnnotation.coordinate.longitude)
            self.latitude = String(self.pointAnnotation.coordinate.latitude)

            
            self.pinAnnotationView = MKPinAnnotationView(annotation: self.pointAnnotation, reuseIdentifier: nil)
            self.mapView.centerCoordinate = self.pointAnnotation.coordinate
            self.mapView.addAnnotation(self.pinAnnotationView.annotation!)
            let span = MKCoordinateSpanMake(0.050, 0.050)
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: self.pointAnnotation.coordinate.latitude, longitude: self.pointAnnotation.coordinate.longitude), span: span)
            self.mapView.setRegion(region, animated: true)
            
            //Suppression de l'ancien lieu
            let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "Lieu"))
            do {
                try self.context.execute(DelAllReqVar)
                print("Supprimer")
            }
            catch {
                print(error)
            }
            
            
            //Sauvegarde dans le Core Data
            let endroit = Lieu(context: self.context)
            endroit.nom = self.pointAnnotation.title!
            endroit.latitude = self.latitude
            endroit.longitude = self.longitude
            
            do{
                try self.context.save()
                print("sauvegarder")
            }catch{
                print("errreur")
            }
            

        
        }
        
    }
    
    func findMeteo(){
        
        if(self.connectedPeripheral.state.rawValue == 0){
            stateLabel.backgroundColor = UIColor(red: 255/255, green: 95/255, blue: 87/255, alpha: 1)
            stateLabel.text = "Aucune Connexion📡"
        }
        
        if((self.longitude != "")&&(self.latitude != "")){
            self.weather.forcast(long: self.longitude, lat: self.latitude)
            directionLabel.text = "Direction : \(weather.direction) degrés"
            vitesseLabel.text = "Vitesse: \(weather.speed) km/h"
            tempLabel.text = "Température: \(weather.temp) °C"
            
            var sendData = "V\(weather.speed)T\(weather.temp)D\(weather.direction)F"
            print(sendData)
            do {
                if(vaneCharacteristic != nil){
                    sendMessageToDevice(value: sendData)
                }
                
            }catch{
                print(error.localizedDescription)
            }
            
        }
        
    }
    
    func loadLieu(){
        let locationRequest:NSFetchRequest<Lieu> = Lieu.fetchRequest()
        
        do{
           locations = try context.fetch(locationRequest)
        }catch{
            print("erreur")
        }
    }
    
    func loadDevice(){
        let deviceRequest:NSFetchRequest<Device> = Device.fetchRequest()
        
        do{
            devices = try context.fetch(deviceRequest)
        }catch{
            print("erreur")
        }
    }

    
    func callMap(){
        if(locations.isEmpty){
            
        }else {
            self.pointAnnotation = MKPointAnnotation()
            self.pointAnnotation.title = self.nom
            self.pointAnnotation.coordinate.longitude = Double(self.longitude)!
            self.pointAnnotation.coordinate.latitude = Double(self.latitude)!
            self.pinAnnotationView = MKPinAnnotationView(annotation: self.pointAnnotation, reuseIdentifier: nil)
            self.mapView.centerCoordinate = self.pointAnnotation.coordinate
            self.mapView.addAnnotation(self.pinAnnotationView.annotation!)
            let span = MKCoordinateSpanMake(0.050, 0.050)
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: self.pointAnnotation.coordinate.latitude, longitude: self.pointAnnotation.coordinate.longitude), span: span)
            self.mapView.setRegion(region, animated: true)
        }
        
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
            print("Appareil: \(device)")
            if(deviceName.isEmpty){
            
            }else {
                if (device) == deviceName{
                
                    self.manager.stopScan()
                    do {
                        self.connectedPeripheral = try peripheral
                    }catch {
                        print("Erreur")
                    }
                
                    self.connectedPeripheral.delegate = self
                    manager.connect(peripheral, options: nil)
                    print("connecter")
                    stateLabel.backgroundColor = UIColor(red: 30/255, green: 215/255, blue: 95/255, alpha: 1)
                    self.stateLabel.text = "connecté à \(deviceName)"
                }
            }
        }
        
    }
    
    //MARK:- get services on devices
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.discoverServices(nil)
        
    }
    
    //MARK:- get characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            print("service : \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
            if(serviceUUID.uuidString.isEmpty){
                
            }else{
                if service.uuid == serviceUUID {
                    
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            
        }
    }
    
    //MARK:- notification
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            print("Char : \(characteristic.uuid)")
            if(charUUID.uuidString.isEmpty){
                
            }else{
                if characteristic.uuid == charUUID {
                    
                    do {
                        vaneCharacteristic = try characteristic
                    }catch{
                        print("erreur")
                    }
                    
                    peripheral.readValue(for: characteristic)
                    
                }
            }
            
        }
        
        
    }
    
    //MARK:- characteristic change
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if(charUUID.uuidString.isEmpty){
            
        }else {
            if characteristic.uuid == charUUID {
                
                if let data = characteristic.value {
                    
                    if data[0] == 1 {
                        
                    }
                    
                }
            }
        }
        
    }
    
    
    
    //MARK:- disconnect
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    
    
    
    func sendMessageToDevice(value: String) {
        
        if(self.vaneCharacteristic != nil){
            do {
                let dataToSend = try value.data(using: String.Encoding.utf8)
                
                
                if (connectedPeripheral != nil) {
                    connectedPeripheral?.writeValue(dataToSend!, for: vaneCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
                } else {
                    print("haven't discovered device yet")
                }
                
            } catch {
                print("erreur")
            }
        }
        
        
        
    }


    
    
    
    
    
    
    
    
    
    
    
    

}
