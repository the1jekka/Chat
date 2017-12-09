//
//  ColorExtension.swift
//  Chat
//
//  Created by Eugene Korotky on 08.12.17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }
}
