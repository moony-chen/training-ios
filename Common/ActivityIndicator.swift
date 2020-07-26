//
//  ActivityIndicator.swift
//  Common
//
//  Created by Fang Chen on 7/26/20.
//  Copyright © 2020 Moony Chen. All rights reserved.
//

import SwiftUI

public struct ActivityIndicator: UIViewRepresentable {
  public init() {}

  public func makeUIView(context: Context) -> UIActivityIndicatorView {
    let view = UIActivityIndicatorView()
    view.startAnimating()
    return view
  }

  public func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {}
}
