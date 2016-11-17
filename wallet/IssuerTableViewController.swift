//
//  IssuerTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/27/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

private let issuerSummaryCellReuseIdentifier = "IssuerSummaryTableViewCell"
private let certificateCellReuseIdentifier = "UITableViewCell +certificateCellReuseIdentifier"

fileprivate enum Sections : Int {
    case issuerSummary = 0
    case certificates
    case count
}

class IssuerTableViewController: UITableViewController {
    public var managedIssuer : ManagedIssuer? {
        didSet {
            self.title = managedIssuer?.issuer?.name
        }
    }
    public var certificates : [Certificate] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: certificateCellReuseIdentifier)
        tableView.register(UINib(nibName: "IssuerSummaryTableViewCell", bundle: nil), forCellReuseIdentifier: issuerSummaryCellReuseIdentifier)
        
        tableView.estimatedRowHeight = 87
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return Sections.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == Sections.issuerSummary.rawValue {
            return 1
        } else if section == Sections.certificates.rawValue {
            return certificates.count
        }
        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuseIdentifier = certificateCellReuseIdentifier
        if indexPath.section == Sections.issuerSummary.rawValue {
            reuseIdentifier = issuerSummaryCellReuseIdentifier
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        switch indexPath.section {
        case Sections.issuerSummary.rawValue:
            let summaryCell = cell as! IssuerSummaryTableViewCell
            if let issuer = managedIssuer?.issuer {
                summaryCell.issuerImageView.image = UIImage(data:issuer.image)
            }
            summaryCell.statusLabel.text = managedIssuer?.status
            summaryCell.actionButton.isHidden = true
        case Sections.certificates.rawValue:
            let certificate = certificates[indexPath.row]
            cell.textLabel?.text = certificate.title
            cell.detailTextLabel?.text = certificate.subtitle
            
        default:
            break;
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Sections.certificates.rawValue {
            return "Certificates"
        }
        return nil
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == Sections.certificates.rawValue {
            return true
        }
        return false
    }
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard indexPath.section == Sections.certificates.rawValue else {
            return nil
        }
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (action, indexPath) in
            let deletedCertificate : Certificate! = self?.certificates.remove(at: indexPath.row)
            
            let documentsDirectory = Paths.certificatesDirectory
            let certificateFilename = deletedCertificate.assertion.uid
            let filePath = URL(fileURLWithPath: certificateFilename, relativeTo: documentsDirectory)
            
            let coordinator = NSFileCoordinator()
            var coordinationError : NSError?
            coordinator.coordinate(writingItemAt: filePath, options: [.forDeleting], error: &coordinationError, byAccessor: { (file) in
                
                do {
                    try FileManager.default.removeItem(at: filePath)
                    tableView.reloadData()
                } catch {
                    print(error)
                    self?.certificates.insert(deletedCertificate, at: indexPath.row)
                    
                    let alertController = UIAlertController(title: "Couldn't delete file", message: "Something went wrong deleting that certificate.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alertController, animated: true, completion: nil)
                }
            })
            
            if let error = coordinationError {
                print("Coordination failed with \(error)")
            } else {
                print("Coordination went fine.")
            }
            
        }
        return [ deleteAction ]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Sections.certificates.rawValue else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let selectedCertificate = certificates[indexPath.row]
        let controller = CertificateViewController(certificate: selectedCertificate)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        if segue.identifier == segueToCertificate {
    //            print("Yes, segue")
    //        } else {
    //            print("Don't do it!")
    //        }
    //    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
