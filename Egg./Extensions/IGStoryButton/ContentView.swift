//
//  ContentView.swift
//  Egg.
//
//  Created by Jordan Wood on 7/12/22.
//


import UIKit

/// view located at center in IGStoryButton
final public class ContentView: UIImageView {
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 12
    }
}
