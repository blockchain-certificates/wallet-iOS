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
    
    @IBAction func addIssuerTapped(_ sender: UIBarButtonItem) {
        let controller = AddIssuerViewController()
        controller.delegate = self
        present(controller, animated: true, completion: nil)
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
}

extension IssuerCollectionViewController { //  : UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: segueToViewIssuer, sender: nil)
    }
}

extension IssuerCollectionViewController : AddIssuerViewControllerDelegate {
    func added(issuer: Issuer) {
        self.add(issuer: issuer)
    }
}
