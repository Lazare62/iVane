//
//  ConnexionViewController.swift
//  vane
//
//  Created by Remy Krysztofiak on 03/06/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import UIKit
import CoreData

class AddDeviceViewController: UIViewController{
    
    @IBOutlet weak var nomTextField: UITextField!
    @IBOutlet weak var serviceTextField: UITextField!
    @IBOutlet weak var charTextField: UITextField!
    
    var context: NSManagedObjectContext! // Variable Core Data

    
    override func viewDidLoad() {
        super.viewDidLoad()
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    @IBAction func addDevice(_ sender: Any) {
        
        if((nomTextField.text != "")&&(serviceTextField.text != "")&&(charTextField.text != "")){
            
            
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
            
            appareil.name = nomTextField.text!
            appareil.serviceUUID = serviceTextField.text!
            appareil.charUUID = charTextField.text!
            
            
            
            do{
                try self.context.save()
                print("sauvegarder")
                let SaveAlert = UIAlertController(title: "📟Vane enregistrer", message: "L'adresse vient d'être enregistrer retourner sur votre carte", preferredStyle: .alert)
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
