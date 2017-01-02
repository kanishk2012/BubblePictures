//
//  BubblePicturesController.swift
//  Pods
//
//  Created by Kevin Belter on 1/2/17.
//
//

import UIKit

public class BubblePicturesController: NSObject {
    
    init(collectionView: UICollectionView, configFiles: [BPCellConfigFile]) {
        self.configFiles = configFiles
        self.collectionView = collectionView
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        registerCells()
        truncateCells(configFiles: configFiles)
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var delegate: BPDelegate?
    
    internal func rotated() {
        self.configFilesTruncated = []
        truncateCells(configFiles: configFiles)
        self.collectionView.reloadData()
    }
    
    private func registerCells() {
        let nib = UINib(nibName: BPCollectionViewCell.className, bundle: BubblePicturesController.bubblePicturesBundle)
        self.collectionView.register(nib, forCellWithReuseIdentifier: BPCollectionViewCell.className)
    }
    
    private func truncateCells(configFiles: [BPCellConfigFile]) {
        if configFiles.count <= maxNumberOfBubbles {
            configFilesTruncated = configFiles
            return
        }
        
        for (index, configFile) in configFiles.enumerated() {
            if index == maxNumberOfBubbles - 1 {
                let remainingCells = configFiles.count - maxNumberOfBubbles + 1
                //TODO: The color should be injected.
                let truncatedCell = BPCellConfigFile(imageType: BPImageType.color(UIColor.red), title: "+\(remainingCells)")
                configFilesTruncated.append(truncatedCell)
                break
            }
            
            configFilesTruncated.append(configFile)
        }
    }
    
    fileprivate weak var collectionView: UICollectionView!
    fileprivate var configFiles: [BPCellConfigFile]
    fileprivate var configFilesTruncated: [BPCellConfigFile] = []
    fileprivate var negativeInsetWidth: CGFloat {
        return (self.collectionView.bounds.height / 3.0)
    }
    fileprivate var maxNumberOfBubbles: Int {
        return Int(floor((self.collectionView.bounds.width - negativeInsetWidth) / (self.collectionView.bounds.height - negativeInsetWidth)))
    }
    internal class var bubblePicturesBundle: Bundle? {
        let podBundle = Bundle(for: self)
        guard
            let bundleURL = podBundle.url(forResource: "BubblePictures", withExtension: "bundle"),
            let bundle = Bundle(url: bundleURL)
            else { return nil }
        
        return bundle
    }
}

extension BubblePicturesController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.configFilesTruncated.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BPCollectionViewCell.className, for: indexPath) as! BPCollectionViewCell
        
        cell.configure(configFile: configFilesTruncated[indexPath.item])
        cell.layer.zPosition = CGFloat(indexPath.item)
        return cell
    }
}

extension BubblePicturesController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.bounds.height, height: collectionView.bounds.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return -negativeInsetWidth
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == configFilesTruncated.count - 1 && configFilesTruncated.count != configFiles.count {
            delegate?.didSelectTruncatedBubble()
            return
        }
        delegate?.didSelectBubble(at: indexPath.item)
    }
}