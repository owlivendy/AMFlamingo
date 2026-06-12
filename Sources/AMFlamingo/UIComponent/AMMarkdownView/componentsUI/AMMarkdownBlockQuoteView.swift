//
//  AMMarkdownBlockQuoteView.swift
//  ChinaHomelife247
//
//  Created by shenxiaofei on 2026/3/26.
//  Copyright © 2026 shenxiaofei. All rights reserved.
//

import UIKit

final class AMMarkdownBlockQuoteView: UIView {
    private let barView = UIView(frame: .zero)
    private let backgroundContainer = UIView(frame: .zero)
    private let textView = UITextView(frame: .zero)
    
    private let style: AMMarkdownViewStyle
    private var heightConstraint: NSLayoutConstraint?
    
    init(frame: CGRect, style: AMMarkdownViewStyle) {
        self.style = style
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .clear
        
        backgroundContainer.backgroundColor = style.blockQuoteBackgroundColor
        backgroundContainer.layer.cornerRadius = style.blockQuoteCornerRadius
        backgroundContainer.clipsToBounds = true
        
        barView.backgroundColor = style.blockQuoteBarColor
        barView.layer.cornerRadius = style.blockQuoteBarWidth / 2
        barView.clipsToBounds = true
        
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = []
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        addSubview(backgroundContainer)
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: topAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        backgroundContainer.addSubview(barView)
        backgroundContainer.addSubview(textView)
        barView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            barView.leadingAnchor.constraint(equalTo: backgroundContainer.leadingAnchor, constant: style.blockQuoteContentInset.left),
            barView.topAnchor.constraint(equalTo: backgroundContainer.topAnchor, constant: style.blockQuoteContentInset.top),
            barView.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor, constant: -style.blockQuoteContentInset.bottom),
            barView.widthAnchor.constraint(equalToConstant: style.blockQuoteBarWidth),
            
            textView.topAnchor.constraint(equalTo: backgroundContainer.topAnchor, constant: style.blockQuoteContentInset.top),
            textView.bottomAnchor.constraint(equalTo: backgroundContainer.bottomAnchor, constant: -style.blockQuoteContentInset.bottom),
            textView.leadingAnchor.constraint(equalTo: barView.trailingAnchor, constant: style.blockQuoteBarSpacing),
            textView.trailingAnchor.constraint(equalTo: backgroundContainer.trailingAnchor, constant: -style.blockQuoteContentInset.right),
        ])
        
        let hc = heightAnchor.constraint(equalToConstant: 0)
        hc.isActive = true
        heightConstraint = hc
    }
    
    func configure(text: NSAttributedString, width: CGFloat, delegate: UITextViewDelegate?) {
        textView.delegate = delegate
        textView.attributedText = text
        
        let contentWidth = max(
            1,
            width
            - style.blockQuoteContentInset.left
            - style.blockQuoteBarWidth
            - style.blockQuoteBarSpacing
            - style.blockQuoteContentInset.right
        )
        
        let size = AMMarkdownView.heightWithAttiribute(text, width: contentWidth, markdownStyle: style, addCommonPragraph: false)
        let totalHeight = ceil(size.height) + style.blockQuoteContentInset.top + style.blockQuoteContentInset.bottom
        heightConstraint?.constant = totalHeight
    }
    
    static func measuredHeight(text: NSAttributedString, width: CGFloat, style: AMMarkdownViewStyle) -> CGFloat {
        let contentWidth = max(
            1,
            width
            - style.blockQuoteContentInset.left
            - style.blockQuoteBarWidth
            - style.blockQuoteBarSpacing
            - style.blockQuoteContentInset.right
        )
        let size = AMMarkdownView.heightWithAttiribute(text, width: contentWidth, markdownStyle: style, addCommonPragraph: false)
        return ceil(size.height) + style.blockQuoteContentInset.top + style.blockQuoteContentInset.bottom
    }
}
