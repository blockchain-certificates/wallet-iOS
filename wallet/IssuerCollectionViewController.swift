//
//  IssuerCollectionViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/11/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

private let reuseIdentifier = "Cell"
private let segueToViewIssuer = "ShowIssuerDetail"

class IssuerCollectionViewController: UICollectionViewController {
    private let archiveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Issuers")
    
    // TODO: Should probably be AttributedIssuer, once I make up that model.
    var issuers = [Issuer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Set up the Collection View
        let cellNib = UINib(nibName: "IssuerCollectionViewCell", bundle: nil)
        self.collectionView?.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.delegate = self

        // Style this bad boy
        self.navigationController?.navigationBar.barTintColor = Colors.translucentBrandColor
        self.navigationController?.navigationBar.tintColor = Colors.tintColor
        
        // Load any existing issuers.
        loadIssuers();
    }

    // MARK: - Actions
    
    @IBAction func accountTapped(_ sender: UIBarButtonItem) {
        let controller = AccountViewController()
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Add Issuer", style: .default, handler: { [weak self] _ in
            let controller = AddIssuerViewController()
            controller.delegate = self
            
            self?.present(controller, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: "Import Certificate from File", style: .default, handler: { [weak self] _ in
            
            let controller = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
            controller.delegate = self
            controller.modalPresentationStyle = .formSheet
            
            self?.present(controller, animated: true, completion: nil)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return issuers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! IssuerCollectionViewCell

        let issuer = issuers[indexPath.item]
        cell.imageView.image = UIImage(data: issuer.image)
        cell.titleLabel.text = issuer.name
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    func loadIssuers() {
        let codedIssuers = NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? [[String: Any]] ?? []
        issuers = codedIssuers.flatMap({ Issuer(dictionary: $0) })
            
        OperationQueue.main.addOperation {
            self.collectionView?.reloadData()
        }
    }
    
    func saveIssuers() {
        let issuersCodingList: [[String : Any]] = issuers.map({ $0.toDictionary() })
        NSKeyedArchiver.archiveRootObject(issuersCodingList, toFile: archiveURL.path)
    }
    
    func add(issuer: Issuer) {
        issuers.append(issuer)
        saveIssuers()
        OperationQueue.main.addOperation {
            self.collectionView?.reloadData()
        }
    }
    
    func importCertificate(from data: Data?) {
        guard let data = data else {
            let alertController = UIAlertController(title: "Couldn't read file", message: "Something went wrong trying to open the file.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] action in
                alertController?.dismiss(animated: true, completion: nil)
                }))
            present(alertController, animated: true, completion: nil)
            return
        }
        guard let certificate = try? CertificateParser.parse(data: data) else {
            let alertController = UIAlertController(title: "Invalid Certificate", message: "That doesn't appear to be a valid Certificate file.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] action in
                alertController?.dismiss(animated: true, completion: nil)
                }))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        // At this point, data is totally a valid certificate. Let's save that to the documents directory.
//        let filename = certificate.assertion.uid
//        let success = save(certificateData: data, withFilename: filename)
//        let isCertificateInList = certificates.contains(where: { $0.assertion.uid == certificate.assertion.uid })
//        
//        if isCertificateInList {
//            let alertController = UIAlertController(title: "File already imported", message: "You've already imported that file.", preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            present(alertController, animated: true, completion: nil)
//        } else if !success {
//            let alertController = UIAlertController(title: "Failed to save file", message: "Try importing the file again. ", preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            present(alertController, animated: true, completion: nil)
//        } else {
//            certificates.append(certificate)
//            
//            // Issue #20: We should do an insert animation rather than a full table reload.
//            // https://github.com/blockchain-certificates/cert-wallet/issues/20
//            tableView.reloadData()
//        }
    }
}

extension IssuerCollectionViewController { //  : UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedIssuer = issuers[indexPath.item]
        let issuerController = IssuerTableViewController()
        issuerController.issuer = selectedIssuer
        
        self.navigationController?.pushViewController(issuerController, animated: true)
    }
}

extension IssuerCollectionViewController : AddIssuerViewControllerDelegate {
    func added(issuer: Issuer) {
        self.add(issuer: issuer)
    }
}

extension IssuerCollectionViewController : UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let data = try? Data(contentsOf: url)
        
        importCertificate(from: data)
    }
}
