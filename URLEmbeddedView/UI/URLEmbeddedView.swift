//
//  URLEmbeddedView.swift
//  URLEmbeddedView
//
//  Created by Taiki Suzuki on 2016/03/06.
//
//

import UIKit

@objc open class URLEmbeddedView: UIView {
    private typealias ATP = AttributedTextProvider
    //MARK: - Static constants
    private struct Const {
        static let faviconURL = "http://www.google.com/s2/favicons?domain="
    }
    
    //MARK: - Properties
    private let alphaView = UIView()
    
    let imageView = URLImageView()
    private var imageViewWidthConstraint: NSLayoutConstraint?
    
    private let titleLabel = UILabel()
    private var titleLabelHeightConstraint: NSLayoutConstraint?
    private let descriptionLabel = UILabel()
    
    private let domainConainter = UIView()
    private var domainContainerHeightConstraint: NSLayoutConstraint?
    private let domainLabel = UILabel()
    private let domainImageView = URLImageView()
    private var domainImageViewToDomainLabelConstraint: NSLayoutConstraint?
    private var domainImageViewWidthConstraint: NSLayoutConstraint?
    
    private let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private lazy var linkIconView: LinkIconView = {
        return .init(frame: self.bounds)
    }()
    
    private var url: URL?
    private var task: Task?
    @objc open let textProvider: AttributedTextProvider = .shared
    
    @objc open var didTapHandler: ((URLEmbeddedView, URL?) -> Void)?
    @objc open var shouldContinueDownloadingWhenCancel = true {
        didSet {
            domainImageView.shouldContinueDownloadingWhenCancel = shouldContinueDownloadingWhenCancel
            imageView.shouldContinueDownloadingWhenCancel = shouldContinueDownloadingWhenCancel
        }
    }
    
    private let dataProvider: OGDataProvider = .shared
    
    @objc public convenience init() {
        self.init(frame: .zero)
    }
    
    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        setInitialiValues()
        configureViews()
    }
    
    @objc public convenience init(url: String) {
        self.init(url: url, frame: .zero)
    }
    
    @objc public init(url: String, frame: CGRect) {
        super.init(frame: frame)
        self.url = URL(string: url)
        setInitialiValues()
        configureViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setInitialiValues()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }
    
    open func prepareViewsForReuse() {
        cancelLoading()
        imageView.image = nil
        titleLabel.attributedText = nil
        descriptionLabel.attributedText = nil
        domainLabel.attributedText = nil
        domainImageView.image = nil
        linkIconView.isHidden = true
    }
    
    fileprivate func setInitialiValues() {
        borderColor = .lightGray
        borderWidth = 1
        cornerRaidus = 8
    }
    
    fileprivate func configureViews() {
        setNeedsDisplay()
        layoutIfNeeded()
        
        textProvider.didChangeValue = { [weak self] style, attribute, value in
            self?.handleTextProviderChanged(style, attribute: attribute, value: value)
        }

        addSubview(linkIconView)
        addConstraints(with: linkIconView,
                       edges: .init(top: 0, left: 0, bottom: 0))
        addConstraint(.init(item: linkIconView,
                            attribute: .width,
                            relatedBy: .equal,
                            toItem: linkIconView,
                            attribute: .height,
                            multiplier: 1,
                            constant: 0))
        linkIconView.clipsToBounds = true
        linkIconView.isHidden = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        addConstraints(with: imageView,
                       edges: .init(top: 0, left: 0, bottom: 0))
        changeImageViewWidthConstrain(nil)
        
        titleLabel.numberOfLines = textProvider[.title].numberOfLines
        addSubview(titleLabel)
        addConstraints(with: titleLabel,
                       edges: .init(top: 8, right: -12))
        addConstraint(.init(item: titleLabel,
                            attribute: .left,
                            relatedBy: .equal,
                            toItem: imageView,
                            attribute: .right,
                            multiplier: 1,
                            constant: 12))
        changeTitleLabelHeightConstraint()
        
        addSubview(domainConainter)
        addConstraints(with: domainConainter,
                       edges: .init(right: -12, bottom: -10))
        addConstraint(.init(item: domainConainter,
                            attribute: .left,
                            relatedBy: .equal,
                            toItem: imageView,
                            attribute: .right,
                            multiplier: 1,
                            constant: 12))
        changeDomainContainerHeightConstraint()
        
        descriptionLabel.numberOfLines = textProvider[.description].numberOfLines
        addSubview(descriptionLabel)
        addConstraints(with: descriptionLabel, edges: .init(right: -12))
        addConstraints(with: descriptionLabel,
                       size: .init(height: 0),
                       relatedBy: .greaterThanOrEqual)
        addConstraints([
            .init(item: descriptionLabel,
                  attribute: .top,
                  relatedBy: .equal,
                  toItem: titleLabel,
                  attribute: .bottom,
                  multiplier: 1,
                  constant: 2),
            .init(item: descriptionLabel,
                  attribute: .bottom,
                  relatedBy: .lessThanOrEqual,
                  toItem: domainConainter,
                  attribute: .top,
                  multiplier: 1,
                  constant: 4),
            .init(item: descriptionLabel,
                  attribute: .left,
                  relatedBy: .equal,
                  toItem: imageView,
                  attribute: .right,
                  multiplier: 1,
                  constant: 12)
        ])
        
        domainImageView.activityViewHidden = true
        domainConainter.addSubview(domainImageView)
        domainConainter.addConstraints(with: domainImageView,
                                       edges: .init(top: 0, left: 0, bottom: 0))
        changeDomainImageViewWidthConstraint(nil)
        
        domainLabel.numberOfLines = textProvider[.domain].numberOfLines
        domainConainter.addSubview(domainLabel)
        domainConainter.addConstraints(with: domainLabel,
                                       edges: .init(top: 0, right: 0, bottom: 0))
        changeDomainImageViewToDomainLabelConstraint(nil)
        
        activityView.hidesWhenStopped = true
        addSubview(activityView)
        addConstraints(with: activityView, center: .zero)
        addConstraints(with: activityView, size: .init(width: 30, height: 30))
        
        alphaView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        alphaView.alpha = 0
        addSubview(alphaView)
        addConstraints(with: alphaView, edges: .zero)
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        alphaView.alpha = 1
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        alphaView.alpha = 0
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        alphaView.alpha = 0
        didTapHandler?(self, url)
    }

    //MARK: - Image layout
    private func changeImageViewWidthConstrain(_ constant: CGFloat?) {
        if let constraint = imageViewWidthConstraint {
            removeConstraint(constraint)
        }
        let constraint: NSLayoutConstraint
        if let constant = constant {
            constraint = NSLayoutConstraint(item: imageView,
                                            attribute: .width,
                                            relatedBy: .equal,
                                            toItem: nil,
                                            attribute: .notAnAttribute,
                                            multiplier: 1,
                                            constant: constant)
        } else {
            constraint = NSLayoutConstraint(item: imageView,
                                            attribute: .width,
                                            relatedBy: .equal,
                                            toItem: imageView,
                                            attribute: .height,
                                            multiplier: 1,
                                            constant: 0)
        }
        addConstraint(constraint)
        imageViewWidthConstraint = constraint
    }
    
    private func changeDomainImageViewWidthConstraint(_ constant: CGFloat?) {
        if let constraint = domainImageViewWidthConstraint {
            removeConstraint(constraint)
        }
        let constraint: NSLayoutConstraint
        if let constant = constant {
            constraint = NSLayoutConstraint(item: domainImageView,
                                            attribute: .width,
                                            relatedBy: .equal,
                                            toItem: nil,
                                            attribute: .notAnAttribute,
                                            multiplier: 1,
                                            constant: constant)
        } else {
            constraint = NSLayoutConstraint(item: domainImageView,
                                            attribute: .width,
                                            relatedBy: .equal,
                                            toItem: domainConainter,
                                            attribute: .height,
                                            multiplier: 1,
                                            constant: 0)
        }
        addConstraint(constraint)
        domainImageViewWidthConstraint = constraint
    }
    
    private func changeDomainImageViewToDomainLabelConstraint(_ constant: CGFloat?) {
        let constant = constant ?? (textProvider[.domain].font.lineHeight / 5)
        if let constraint = domainImageViewToDomainLabelConstraint {
            if constant == constraint.constant { return }
            removeConstraint(constraint)
        }
        let constraint = NSLayoutConstraint(item: domainLabel,
                                            attribute: .left,
                                            relatedBy: .equal,
                                            toItem: domainImageView,
                                            attribute: .right,
                                            multiplier: 1,
                                            constant: constant)
        addConstraint(constraint)
        domainImageViewToDomainLabelConstraint = constraint
    }
    
    private func changeTitleLabelHeightConstraint() {
        let constant = textProvider[.title].font.lineHeight
        if let constraint = titleLabelHeightConstraint {
            if constant == constraint.constant { return }
            removeConstraint(constraint)
        }
        let constraint = NSLayoutConstraint(item: titleLabel,
                                            attribute: .height,
                                            relatedBy: .greaterThanOrEqual,
                                            toItem: nil,
                                            attribute: .notAnAttribute,
                                            multiplier: 1,
                                            constant: constant)
        addConstraint(constraint)
        titleLabelHeightConstraint = constraint
    }
    
    private func changeDomainContainerHeightConstraint() {
        let constant = textProvider[.domain].font.lineHeight
        if let constraint = domainContainerHeightConstraint {
            if constant == constraint.constant { return }
            removeConstraint(constraint)
        }
        let constraint = NSLayoutConstraint(item: domainConainter,
                                            attribute: .height,
                                            relatedBy: .equal,
                                            toItem: nil,
                                            attribute: .notAnAttribute,
                                            multiplier: 1,
                                            constant: constant)
        addConstraint(constraint)
        domainContainerHeightConstraint = constraint
    }
    
    //MARK: - Attributes
    private func handleTextProviderChanged(_ style: AttributeManager.Style, attribute: AttributeManager.Attribute, value: Any) {
        switch style {
        case .title:       didChangeTitleAttirbute(attribute, value: value)
        case .domain:      didChangeDomainAttirbute(attribute, value: value)
        case .description: didChangeDescriptionAttirbute(attribute, value: value)
        case .noDataTitle: didChangeNoDataTitleAttirbute(attribute, value: value)
        }
    }
    
    private func didChangeTitleAttirbute(_ attribute: AttributeManager.Attribute, value: Any) {
        switch attribute {
        case .font: changeDomainContainerHeightConstraint()
        case .fontColor: break
        case .numberOfLines: break
        }
    }
    
    private func didChangeDomainAttirbute(_ attribute: AttributeManager.Attribute, value: Any) {
        switch attribute {
        case .font: changeDomainContainerHeightConstraint()
        case .fontColor: break
        case .numberOfLines: break
        }
    }
    
    private func didChangeDescriptionAttirbute(_ attribute: AttributeManager.Attribute, value: Any) {
        switch attribute {
        case .font: break
        case .fontColor: break
        case .numberOfLines: break
        }
    }
    
    private func didChangeNoDataTitleAttirbute(_ attribute: AttributeManager.Attribute, value: Any) {
        switch attribute {
        case .font: changeTitleLabelHeightConstraint()
        case .fontColor: break
        case .numberOfLines: break
        }
    }
    
    //MARK: - Load
    @objc public func load(withURLString urlString: String, completion: ((Error?) -> Void)? = nil) {
        load(withURLString: urlString) { completion?($0.error) }
    }
    
    @nonobjc public func load(withURLString urlString: String, completion: ((Result<Void>) -> Void)? = nil) {
        guard let url = URL(string: urlString) else {
            completion?(.failure(URLEmbeddedViewError.invalidURLString(urlString)))
            return
        }
        self.url = url
        load(completion)
    }
    
    @objc public func load(_ completion: ((Error?) -> Void)? = nil) {
        load { completion?($0.error) }
    }
    
    @nonobjc public func load(_ completion: ((Result<Void>) -> Void)? = nil) {
        guard let url = url else { return }
        prepareViewsForReuse()
        activityView.startAnimating()
        task = dataProvider.fetchOGData(withURLString: url.absoluteString) { [weak self] ogData, error in
            DispatchQueue.main.async {
                self?.activityView.stopAnimating()
                if let error = error {
                    self?.imageView.image = nil
                    self?.titleLabel.attributedText = self?.textProvider[.noDataTitle].attributedText(url.absoluteString)
                    self?.descriptionLabel.attributedText = nil
                    self?.domainLabel.attributedText = self?.textProvider[.domain].attributedText(url.host ?? "")
                    self?.changeDomainImageViewWidthConstraint(0)
                    self?.changeDomainImageViewToDomainLabelConstraint(0)
                    self?.changeImageViewWidthConstrain(nil)
                    self?.linkIconView.isHidden = false
                    self?.layoutIfNeeded()
                    completion?(.failure(error))
                    return
                }
                
                self?.linkIconView.isHidden = true
                if let pageTitle = ogData.pageTitle {
                    self?.titleLabel.attributedText = self?.textProvider[.title].attributedText(pageTitle)
                } else {
                    self?.titleLabel.attributedText = self?.textProvider[.noDataTitle].attributedText(url.absoluteString)
                }
                if let pageDescription = ogData.pageDescription {
                    self?.descriptionLabel.attributedText = self?.textProvider[.description].attributedText(pageDescription)
                } else {
                    self?.descriptionLabel.attributedText = nil
                }
                if let imageUrl = ogData.imageUrl {
                    self?.imageView.loadImage(urlString: imageUrl.absoluteString) {
                        switch $0 {
                        case .success:
                            self?.changeImageViewWidthConstrain(nil)
                        case .failure:
                            self?.changeImageViewWidthConstrain(0)
                        }
                        self?.layoutIfNeeded()
                    }
                } else {
                    self?.changeImageViewWidthConstrain(0)
                    self?.imageView.image = nil
                }
                let host = url.host ?? ""
                self?.domainLabel.attributedText = self?.textProvider[.domain].attributedText(host)
                let faciconURL = Const.faviconURL + host
                self?.domainImageView.loadImage(urlString: faciconURL) {
                    switch $0 {
                    case .success:
                        self?.changeDomainImageViewWidthConstraint(nil)
                        self?.changeDomainImageViewToDomainLabelConstraint(nil)
                    case .failure:
                        self?.changeDomainImageViewWidthConstraint(0)
                        self?.changeDomainImageViewToDomainLabelConstraint(0)
                    }
                    self?.layoutIfNeeded()
                }
                self?.layoutIfNeeded()
                completion?(.success(()))
            }
        }
    }
    
    @objc public func cancelLoading() {
        domainImageView.cancelLoadingImage()
        imageView.cancelLoadingImage()
        activityView.stopAnimating()
        if let task = task {
            dataProvider.cancelLoading(task, shouldContinueDownloading: shouldContinueDownloadingWhenCancel)
        }
    }
}