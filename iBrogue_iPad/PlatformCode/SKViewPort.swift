//
//  SKViewPort.swift
//  iBrogue_iPad
//
//  Created by sehoward15 on 5/8/17.
//  Copyright © 2017 Seth howard. All rights reserved.
//

import UIKit
import SpriteKit

class SKViewPort: SKView {  
    var rogueScene: RogueScene!
    var hWindow = UIScreen.main.bounds.size.width
    var vWindow = UIScreen.main.bounds.size.height
    
    required init?(coder aDecoder: NSCoder) {
        let rect = UIScreen.main.bounds
        // go max retina on initial size or scaling of text is ugly
        let scale = UIScreen.main.scale
        rogueScene = RogueScene(size: CGSize(width: rect.size.width * scale, height: rect.size.height * scale), rows: (34), cols: 100)
        rogueScene.scaleMode = .fill
        super.init(coder: aDecoder)
        
        showsFPS = true
        showsNodeCount = true
        ignoresSiblingOrder = true
    }
    
    override func awakeFromNib() {
        presentScene(rogueScene)
    }
    
    public func setCell(x: Int, y: Int, code: UInt32, bgColor: CGColor, fgColor: CGColor) {
        rogueScene.setCell(x: x, y: y, code: code, bgColor: bgColor, fgColor: fgColor)
    }
}
