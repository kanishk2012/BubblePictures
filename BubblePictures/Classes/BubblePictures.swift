//
//  BubblePicturesController.swift
//  Pods
//
//  Created by Kevin Belter on 1/2/17.
//
//

import UIKit

public class BubblePictures: NSObject {
    
    public init(collectionView: UICollectionView, configFiles: [BPCellConfigFile], layoutConfigurator: BPLayoutConfigurator = BPLayoutConfigurator()) {
        self.configFiles = configFiles
        self.collectionView = collectionView
        self.layoutConfigurator = layoutConfigurator
        super.init()
        setCollectionViewAlignment()
        registerForNotifications()
        registerCells()
        truncateCells(configFiles: configFiles)
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public var delegate: BPDelegate?
    
    internal func rotated() {
        self.configFilesTruncated = []
        truncateCells(configFiles: configFiles)
        self.collectionView.reloadData()
    }
    
    private func setCollectionViewAlignment() {
        if layoutConfigurator.alignment == .right {
            collectionView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        } else {
            collectionView.transform = .identity
        }
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    private func registerCells() {
        let nib = UINib(nibName: BPCollectionViewCell.className, bundle: BubblePictures.bubblePicturesBundle)
        self.collectionView.register(nib, forCellWithReuseIdentifier: BPCollectionViewCell.className)
    }
    
    private func truncateCells(configFiles: [BPCellConfigFile]) {
        defer {
            if layoutConfigurator.alignment == .right {
                configFilesTruncated = configFilesTruncated.reversed()
            }
        }
        
        if configFiles.count < maxNumberOfBubbles {
            configFilesTruncated = configFiles
            return
        }
        
        for (index, configFile) in configFiles.enumerated() {
            if index + 1 == maxNumberOfBubbles {
                let remainingCells = (configFiles.count + 1) - maxNumberOfBubbles
                let truncatedCell = BPCellConfigFile(
                    imageType: BPImageType.color(layoutConfigurator.backgroundColorForTruncatedBubble),
                    title: "+\(layoutConfigurator.numberForTruncatedCell ?? remainingCells)"
                )
                configFilesTruncated.append(truncatedCell)
                break
            }
            
            configFilesTruncated.append(configFile)
        }
    }
    
    fileprivate weak var collectionView: UICollectionView!
    fileprivate var configFiles: [BPCellConfigFile]
    fileprivate var configFilesTruncated: [BPCellConfigFile] = []
    fileprivate var layoutConfigurator: BPLayoutConfigurator
    fileprivate var negativeInsetWidth: CGFloat {
        return layoutConfigurator.distanceInterBubbles ?? (self.collectionView.bounds.height / 3.0)
    }
    fileprivate var maxNumberOfBubbles: Int {
        let calculationMaxNumberOfBubbles = Int(floor((self.collectionView.bounds.width - negativeInsetWidth) / (self.collectionView.bounds.height - negativeInsetWidth)))
        guard let maxNumberPreferredByUser = layoutConfigurator.maxNumberOfBubbles else {
            return calculationMaxNumberOfBubbles
        }
        return min(maxNumberPreferredByUser + 1, calculationMaxNumberOfBubbles)
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

extension BubblePictures: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.configFilesTruncated.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BPCollectionViewCell.className, for: indexPath) as! BPCollectionViewCell

        let isTruncatedCell: Bool
        if layoutConfigurator.alignment == .right {
            isTruncatedCell = indexPath.item == 0 && configFiles.count > maxNumberOfBubbles - 1
        } else {
            isTruncatedCell = indexPath.item == configFilesTruncated.count - 1 && configFiles.count > maxNumberOfBubbles - 1
        }
        cell.configure(configFile: configFilesTruncated[indexPath.item], layoutConfigurator: layoutConfigurator, isTruncatedCell: isTruncatedCell)
        
        if layoutConfigurator.alignment == .right {
            cell.layer.zPosition = CGFloat(-indexPath.item)
            cell.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        } else {
            cell.layer.zPosition = CGFloat(indexPath.item)
            cell.transform = .identity
        }
        return cell
    }
}

extension BubblePictures: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
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
        if layoutConfigurator.alignment == .right {
            if indexPath.item == 0 && configFilesTruncated.count != configFiles.count {
                delegate?.didSelectTruncatedBubble()
                return
            }
            delegate?.didSelectBubble(at: configFilesTruncated.count - 1 - indexPath.item)
        } else {
            if indexPath.item == configFilesTruncated.count - 1 && configFilesTruncated.count != configFiles.count {
                delegate?.didSelectTruncatedBubble()
                return
            }
            delegate?.didSelectBubble(at: indexPath.item)
        }
    }
}
