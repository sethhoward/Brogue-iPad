 //
 //  BrogueViewController.swift
 //  iBrogue_iPad
 //
 //  This file is part of Brogue.
 //
 //  This program is free software: you can redistribute it and/or modify
 //  it under the terms of the GNU Affero General Public License as
 //  published by the Free Software Foundation, either version 3 of the
 //  License, or (at your option) any later version.
 //
 //  This program is distributed in the hope that it will be useful,
 //  but WITHOUT ANY WARRANTY; without even the implied warranty of
 //  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 //  GNU Affero General Public License for more details.
 //
 //  You should have received a copy of the GNU Affero General Public License
 //  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 //
 
 import UIKit
 import SpriteKit
 
 fileprivate let kESC_Key: UInt8 = 27
 fileprivate let kEnterKey = "\n"
 
 private func synchronized<T>(_ lock: Any, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try body()
 }
 
 fileprivate let COLS = 100
 fileprivate let ROWS = 34
 
 func getCellCoords(at point: CGPoint) -> CGPoint {
    let cellx = Int(CGFloat(COLS) * point.x / UIScreen.main.bounds.size.width)
    let celly = Int(CGFloat(ROWS) * point.y / UIScreen.main.bounds.size.height)
    
    return CGPoint(x: cellx, y: celly)
 }
 
 // TODO: switch to Character
 extension String {
    var ascii: UInt8 {
        return (unicodeScalars.map { UInt8($0.value) }).first!
    }
 }
 
 // MARK: - UIBrogueTouchEvent
 
 @objc class UIBrogueTouchEvent: NSObject, NSCopying {
    @objc let phase: UITouch.Phase
    @objc let location: CGPoint
    
    required init(phase: UITouch.Phase, location: CGPoint) {
        self.phase = phase
        self.location = location
    }
    
    required init(touchEvent: UIBrogueTouchEvent) {
        phase = touchEvent.phase
        location = touchEvent.location
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return type(of:self).init(touchEvent: self)
    }
 }
 
 // MARK: - BrogueGameEvent
 
 extension BrogueGameEvent {
    var canShowMagnifyingGlass: Bool {
        switch self {
        case .startNewGame, .inventoryItemAction, .confirmationComplete, .actionMenuClose, .closedInventory, .openGame:
            return true
        default:
            return false
        }
    }
 }
 
 class DirectionContainerView: UIView {
    func disable(with alpha: CGFloat = 0) {
        UIView.animate(withDuration: 0.2) {
            self.alpha = alpha
        }
        
        isUserInteractionEnabled = false
    }
    
    func enable() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
        isUserInteractionEnabled = true
    }
 }
 
 // MARK: - BrogueViewController
 
 final class BrogueViewController: UIViewController {
    fileprivate var touchEvents = [UIBrogueTouchEvent]()
    fileprivate var lastTouchLocation = CGPoint()
    @objc fileprivate var directionsViewController: DirectionControlsViewController?
    fileprivate var keyEvents = [UInt8]()
    fileprivate var magnifierTimer: Timer?
    fileprivate var inputRequestString: String?
    
    @IBOutlet var skViewPort: SKViewPort!
    @IBOutlet fileprivate weak var magView: SKMagView!
    @IBOutlet fileprivate weak var escButton: UIButton! {
        didSet {
            escButton.isHidden = true
        }
    }
    @IBOutlet fileprivate weak var inputTextField: UITextField! {
        didSet {
            inputTextField.delegate = self
        }
    }
    @IBOutlet fileprivate weak var showInventoryButton: UIButton!
    @IBOutlet fileprivate weak var leaderBoardButton: UIButton!
    @IBOutlet fileprivate weak var seedButton: UIButton!
    
    @IBOutlet weak var dContainerView: DirectionContainerView! {
        didSet {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
            panGesture.minimumNumberOfTouches = 2
            dContainerView.addGestureRecognizer(panGesture)
        }
    }
    @objc var seedKeyDown = false
    @objc var lastBrogueGameEvent: BrogueGameEvent = .showTitle {
        didSet {
            DispatchQueue.main.async {
                switch self.lastBrogueGameEvent {
                case .keyBoardInputRequired:
                    self.inputTextField.becomeFirstResponder()
                case .showTitle, .openGameFinished:
                    self.inputTextField.resignFirstResponder()
                    self.showInventoryButton.isHidden = true
                    self.leaderBoardButton.isHidden = false
                    self.seedButton.isHidden = false
                    self.escButton.isHidden = true
                case .startNewGame, .openGame, .beginOpenGame:
                    self.leaderBoardButton.isHidden = true
                    self.seedButton.isHidden = true
                    self.seedKeyDown = false
                case .messagePlayerHasDied:
                    self.showInventoryButton.isHidden = false
                case .playerHasDiedMessageAcknowledged:
                    self.showInventoryButton.isHidden = true
                default: ()
                }
                
                // Hide/Show the directions.
                switch self.lastBrogueGameEvent {
                case .waitingForConfirmation, .actionMenuOpen, .openedInventory, .showTitle, .openGameFinished, .playRecording, .showHighScores, .playBackPanic, .messagePlayerHasDied, .playerHasDiedMessageAcknowledged, .keyBoardInputRequired, .beginOpenGame:
                    self.dContainerView.disable()
                default:
                    self.dContainerView.isHidden = false
                    self.dContainerView.enable()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RogueDriver.sharedInstance(with: skViewPort, viewController: self)
        
        // Up the stack size or we'll overflow.
        let thread = Thread(target: self, selector: #selector(BrogueViewController.playBrogue), object: nil)
        thread.stackSize = 400 * 8192
        thread.start()
        
        magView.viewToMagnify = skViewPort
        magView.hideMagnifier()
        
        GameCenterManager.sharedInstance()?.authenticateLocalUser()
    }
    
    @objc func handleDirectionTouch(_ sender: UIPanGestureRecognizer) {
        directionsViewController?.cancel()
    }
    
    @objc func draggedView(_ sender: UIPanGestureRecognizer) {
        directionsViewController?.cancel()
        let translation = sender.translation(in: view)
        dContainerView.center = CGPoint(x: dContainerView.center.x + translation.x, y: dContainerView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: view)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DirectionControlsViewController {
            directionsViewController = segue.destination as? DirectionControlsViewController
            addObserver(self, forKeyPath: #keyPath(directionsViewController.directionalButton), options: [.new], context: nil)
        }
    }
    
    @objc private func playBrogue() {
        rogueMain()
    }
 }
 
 extension BrogueViewController {
    @IBAction func escButtonPressed(_ sender: Any) {
        addKeyEvent(event: kESC_Key)
        inputTextField.resignFirstResponder()
    }
    
    @IBAction func showInventoryButtonPressed(_ sender: Any) {
        addKeyEvent(event: "i".ascii)
    }
    
    @IBAction func showLeaderBoardButtonPressed(_ sender: Any) {
        rgGCshowLeaderBoard(withCategory: kBrogueHighScoreLeaderBoard)
    }
    
    @IBAction func seedButtonPressed(_ sender: Any) {
        seedKeyDown = !seedKeyDown
        
        if seedKeyDown {
            let image = UIImage(named: "brogue_sproutedseed.png")
            seedButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(named: "brogue_seed.png")
            seedButton.setImage(image, for: .normal)
        }
    }
 }
 
 extension BrogueViewController {
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        addKeyEvent(event: kESC_Key)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard dContainerView.hitTest(touches.first!.location(in: dContainerView), with: event) == nil else { return }
        
        for touch in touches {
            let location = touch.location(in: view)
            // handle double tap on began.
            if touch.tapCount >= 2 && pointIsInPlayArea(point: location) {
                // double tap in the play area
                addTouchEvent(event: UIBrogueTouchEvent(phase: .stationary, location: lastTouchLocation))
                addTouchEvent(event: UIBrogueTouchEvent(phase: .moved, location: lastTouchLocation))
                addTouchEvent(event: UIBrogueTouchEvent(phase: .ended, location: lastTouchLocation))
            }
            else {
                let brogueEvent = UIBrogueTouchEvent(phase: touch.phase, location: location)
                addTouchEvent(event: brogueEvent)
                showMagnifier(at: location)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard dContainerView.hitTest(touches.first!.location(in: dContainerView), with: event) == nil else { return }
        
        dContainerView.disable(with: 0.3)
        
        if let touch = touches.first {
            let location = touch.location(in: view)
            let brogueEvent = UIBrogueTouchEvent(phase: touch.phase, location: location)
            
            addTouchEvent(event: brogueEvent)
            showMagnifier(at: location)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard dContainerView.hitTest(touches.first!.location(in: dContainerView), with: event) == nil else { return }

        dContainerView.enable()
        
        if let touch = touches.first {
            let location = touch.location(in: view)
            
            if pointIsInSideBar(point: location) && lastBrogueGameEvent != .openedInventory {
                // side bar
                if touch.tapCount >= 2 {
                    addTouchEvent(event: UIBrogueTouchEvent(phase: .ended, location: lastTouchLocation))
                } else {
                    addTouchEvent(event: UIBrogueTouchEvent(phase: .moved, location: location))
                }
            } else {
                // other touch
                addTouchEvent(event: UIBrogueTouchEvent(phase: .stationary, location: lastTouchLocation))
                addTouchEvent(event: UIBrogueTouchEvent(phase: .ended, location: lastTouchLocation))
                // TODO: got to be a better way. A better way.
                if pointIsInPlayArea(point: location) && lastBrogueGameEvent != .openedInventory && lastBrogueGameEvent != .inventoryItemAction && lastBrogueGameEvent != .showTitle && lastBrogueGameEvent != .waitingForConfirmation && lastBrogueGameEvent != .actionMenuOpen {
                    addTouchEvent(event: UIBrogueTouchEvent(phase: .ended, location: lastTouchLocation))
                }
            }
        }
        
        hideMagnifier()
    }
    
    private func pointIsInPlayArea(point: CGPoint) -> Bool {
        let cellCoord = getCellCoords(at: point)
        if cellCoord.x > 20 && cellCoord.y < 32 && cellCoord.y > 3 {
            return true
        }
        
        return false
    }
    
    private func pointIsInSideBar(point: CGPoint) -> Bool {
        let cellCoord = getCellCoords(at: point)
        if cellCoord.x <= 20 {
            return true
        }
        
        return false
    }
    
    private func addTouchEvent(event: UIBrogueTouchEvent) {
        lastTouchLocation = event.location
        synchronized(touchEvents) {
            // only want the last moved event, no point caching them all
            if let lastEvent = touchEvents.last, lastEvent.phase == .moved && hasTouchEvent() {
                _ = touchEvents.removeLast()
            }
            
            touchEvents.append(event)
        }
    }
    
    private func clearTouchEvents() {
        synchronized(touchEvents) {
            touchEvents.removeAll()
        }
    }
    
    @objc func dequeTouchEvent() -> UIBrogueTouchEvent? {
        var event: UIBrogueTouchEvent?
        
        synchronized(touchEvents) {
            if !touchEvents.isEmpty {
                event = touchEvents.removeFirst()
                event = event?.copy() as? UIBrogueTouchEvent
            }
        }
        
        return event
    }
    
    @objc func hasTouchEvent() -> Bool {
        return !touchEvents.isEmpty
    }
 }
 
 extension BrogueViewController {
    @objc private func handleMagnifierTimer() {
        if canShowMagnifier(at: lastTouchLocation) {
            magView.showMagnifier(at: lastTouchLocation)
        }
    }
    
    private func canShowMagnifier(at point: CGPoint) -> Bool {
        return lastBrogueGameEvent.canShowMagnifyingGlass && pointIsInPlayArea(point: point)
    }
    
    fileprivate func showMagnifier(at point: CGPoint) {
        guard canShowMagnifier(at: point) else {
            magView.hideMagnifier()
            return
        }
        
        if magView.isHidden {
            magnifierTimer?.invalidate()
            magnifierTimer = nil
            magnifierTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(BrogueViewController.handleMagnifierTimer), userInfo: nil, repeats: false)
            // Need to go iOS 10
            //            magnifierTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            //                self.magView.showMagnifier(at: self.lastTouchLocation)
            //            }
        } else {
            magView.updateMagnifier(at: point)
        }
    }
    
    fileprivate func hideMagnifier() {
        magnifierTimer?.invalidate()
        magnifierTimer = nil
        DispatchQueue.main.async {
            self.magView.hideMagnifier()
        }
    }
 }
 
 extension BrogueViewController {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(directionsViewController.directionalButton) else { return }
        
        if let tag = directionsViewController?.directionalButton?.tag, let direction = ControlDirection(rawValue: tag) {
            var key: String
            switch direction {
            case .up:
                key = kUP_Key
            case .right:
                key = kRIGHT_key
            case .down:
                key = kDOWN_key
            case .left:
                key = kLEFT_key
            case .upLeft:
                key = kUPLEFT_key
            case .upRight:
                key = kUPRight_key
            case .downRight:
                key = kDOWNRIGHT_key
            case .downLeft:
                key = kDOWNLEFT_key
            case .catchAll:
                return
            }
            
            addKeyEvent(event: key.ascii)
        }
    }
    
    fileprivate func addKeyEvent(event: UInt8) {
        synchronized(touchEvents) {
            keyEvents.append(event)
        }
    }
    
    // cannot be optional for backward compat
    @objc func dequeKeyEvent() -> UInt8 {
        var event: UInt8!
        
        synchronized(keyEvents) {
            if !keyEvents.isEmpty {
                event = keyEvents.removeFirst()
            } else {
                fatalError("Deque Key, queue is empty")
            }
        }
        
        return event
    }
    
    @objc func hasKeyEvent() -> Bool {
        return !keyEvents.isEmpty
    }
 }
 
 extension BrogueViewController: UITextFieldDelegate {
    @objc func requestTextInput(for string: String) {
        inputRequestString = string
        DispatchQueue.main.async {
            self.inputTextField.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        inputTextField.resignFirstResponder()
        addKeyEvent(event: "\n".ascii)
        escButton.isHidden = true
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        inputTextField.text = inputRequestString ?? ""
        escButton.isHidden = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isBackSpace = strcmp(string.cString(using: .utf8), "\\b")
        
        if (isBackSpace == -92) {
            addKeyEvent(event: 127)
        } else {
            addKeyEvent(event: string.ascii)
        }
        
        return true
    }
 }
 
 
 // MARK: Keyboard
 
 private let keys: [UIKeyCommand]? = {
    let lower = (UnicodeScalar("a").value...UnicodeScalar("z").value).map{ String(UnicodeScalar($0)!) }
    let upper = (UnicodeScalar("A").value...UnicodeScalar("Z").value).map{ String(UnicodeScalar($0)!) }
    let alpha = lower + upper + [">", "<", " ", "\\", "]", "?", "~", "&", "\r", "\t", "."]
    var keys = (alpha.map {
        UIKeyCommand(input: $0, modifierFlags: [], action: #selector(BrogueViewController.executeKeyCommand))
    })
    keys.append(UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(BrogueViewController.executeKeyCommand)))
    keys.append(UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(BrogueViewController.executeKeyCommand)))
    keys.append(UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(BrogueViewController.executeKeyCommand)))
    keys.append(UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(BrogueViewController.executeKeyCommand)))
    keys.append(UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(BrogueViewController.executeKeyCommand)))
    
    return keys
 }()
 
 extension BrogueViewController {
    override var keyCommands: [UIKeyCommand]? {
        return keys
    }
    
    @objc fileprivate func executeKeyCommand(keyCommand: UIKeyCommand) {
        if let key = keyCommand.input?.ascii {
            addKeyEvent(event: key)
        }
    }
 }

