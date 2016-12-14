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
private let certificateCellReuseIdentifier = "CertificateTitleTableViewCell"
private let noCertificatesCellReuseIdentififer = "NoCertificateTableViewCell"

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
        
        tableView.register(UINib(nibName: "IssuerSummaryTableViewCell", bundle: nil), forCellReuseIdentifier: issuerSummaryCellReuseIdentifier)
        tableView.register(UINib(nibName: "NoCertificatesTableViewCell", bundle: nil), forCellReuseIdentifier: noCertificatesCellReuseIdentififer)
        tableView.register(UINib(nibName: "CertificateTitleTableViewCell", bundle: nil), forCellReuseIdentifier: certificateCellReuseIdentifier)
        
        tableView.estimatedRowHeight = 87
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 1
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        
        tableView.tableFooterView = UIView()
        
        tableView.separatorColor = UIColor(red:0.87, green:0.88, blue:0.90, alpha:1.0)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if certificates.isEmpty {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(confirmDeleteIssuer))
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.issuerSummary.rawValue {
            return 1
        } else if section == Sections.certificates.rawValue {
            if certificates.isEmpty {
                return 1
            } else {
                return certificates.count
            }
        }
        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let returnedCell : UITableViewCell!
        
        switch indexPath.section {
        case Sections.issuerSummary.rawValue:
            let summaryCell = tableView.dequeueReusableCell(withIdentifier: issuerSummaryCellReuseIdentifier) as! IssuerSummaryTableViewCell
            if let issuer = managedIssuer?.issuer {
                summaryCell.issuerImageView.image = UIImage(data: issuer.image)
            }
            returnedCell = summaryCell
        case Sections.certificates.rawValue:
            if certificates.isEmpty {
                returnedCell = tableView.dequeueReusableCell(withIdentifier: noCertificatesCellReuseIdentififer)
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: certificateCellReuseIdentifier) as! CertificateTitleTableViewCell
                let certificate = certificates[indexPath.row]
                cell.title = certificate.title
                cell.subtitle = certificate.subtitle
                
                returnedCell = cell
            }
        default:
            returnedCell = UITableViewCell()
        }
        
        return returnedCell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == Sections.certificates.rawValue else {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            
            let constraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
            NSLayoutConstraint.activate([ constraint ])
            
            return view
        }
        let containerView = UIView()
        containerView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        let label = UILabel()
        label.text = "CERTIFICATES"
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        let constraints = [
            NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .leftMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .rightMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .topMargin, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottomMargin, multiplier: 1, constant: 0),
        ]
        NSLayoutConstraint.activate(constraints)
        
        return containerView
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == Sections.certificates.rawValue {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Sections.certificates.rawValue else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let selectedCertificate = certificates[indexPath.row]
        let controller = CertificateViewController(certificate: selectedCertificate)
        controller.delegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: Key actions
    func confirmDeleteIssuer() {
        guard let issuerToDelete = self.managedIssuer else {
            return
        }
        
        let prompt = UIAlertController(title: "Are you sure you want to delete this issuer?", message: nil, preferredStyle: .alert)
        prompt.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            _ = self?.navigationController?.popToRootViewController(animated: true)
            if let rootController = self?.navigationController?.topViewController as? IssuerCollectionViewController {
                rootController.remove(managedIssuer: issuerToDelete)
            }
            
        }))
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil)
    }
}

extension IssuerTableViewController : CertificateViewControllerDelegate {
    func delete(certificate: Certificate) {
        let possibleIndex = certificates.index(where: { (cert) -> Bool in
            return cert.assertion.uid == certificate.assertion.uid
        })
        guard let index = possibleIndex else {
            return
        }
        
        let documentsDirectory = Paths.certificatesDirectory
        let certificateFilename = certificate.assertion.uid
        let filePath = URL(fileURLWithPath: certificateFilename, relativeTo: documentsDirectory)
        
        let coordinator = NSFileCoordinator()
        var coordinationError : NSError?
        coordinator.coordinate(writingItemAt: filePath, options: [.forDeleting], error: &coordinationError, byAccessor: { [weak self] (file) in
            
            do {
                try FileManager.default.removeItem(at: filePath)
                self?.certificates.remove(at: index)
                self?.tableView.reloadData()
            } catch {
                print(error)
                
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
}
