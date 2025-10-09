import UIKit

class AMLoadingToastView: AMToastView {
    private let activityIndicator: UIActivityIndicatorView
    
    override init(frame: CGRect) {
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
        } else {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        super.init(frame: frame)
        activityIndicator.startAnimating()
        customView = activityIndicator
    }
    
    required init?(coder: NSCoder) {
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
        } else {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        super.init(coder: coder)
        activityIndicator.startAnimating()
        customView = activityIndicator
    }
    
    deinit {
        activityIndicator.stopAnimating()
    }
} 
