//
//  PFStepper.swift
//  PFStepper
//
//  Created by Cee on 22/12/2015.
//  Copyright © 2015 Cee. All rights reserved.
//

import UIKit

open class PFStepper: UIControl {
    open var value: Double = 0 {
        didSet {
            value = min(maximumValue, max(minimumValue, value))
            
            let isInteger = floor(value) == value
            
            if showIntegerIfDoubleIsInteger && isInteger {
                topButton.setTitle(String(Int(value)), for: UIControl.State())
                bottomButton.setTitle(String(Int(value + stepValue)), for: UIControl.State())
            } else {
                topButton.setTitle(String(value), for: UIControl.State())
                bottomButton.setTitle(String(value + stepValue), for: UIControl.State())
            }
            
            if oldValue != value {
                sendActions(for: .valueChanged)
            }
            if value <= minimumValue {
                topButton.setTitle("", for: UIControl.State())
                topButton.backgroundColor = UIColor.white
            } else {
                topButton.backgroundColor = UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1)
                topButton.alpha = 0.5
            }
            if value >= maximumValue {
                bottomButton.setTitle("", for: UIControl.State())
            } else {
            }
        }
    }
    open var minimumValue: Double = 0
    open var maximumValue: Double = 24
    open var stepValue: Double = 1
    open var autorepeat: Bool = true
    open var showIntegerIfDoubleIsInteger: Bool = true
    open var topButtonText: String = ""
    open var bottomButtonText: String = "1"
    open var buttonsTextColor: UIColor =  UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    open var buttonsBackgroundColor: UIColor = UIColor.white
    open var buttonsFont = UIFont(name: "AvenirNext-Bold", size: 20.0)!
    lazy var topButton: UIButton = {
        let button = UIButton()
        button.setTitle(self.topButtonText, for: UIControl.State())
        button.setTitleColor(self.buttonsTextColor, for: UIControl.State())
        button.backgroundColor = self.buttonsBackgroundColor
        button.titleLabel?.font = self.buttonsFont
//        button.contentHorizontalAlignment = .Left
//        button.contentVerticalAlignment = .Top
//        button.titleEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 0.0, 0.0)
        button.addTarget(self, action: #selector(PFStepper.topButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(PFStepper.buttonTouchUp(_:)), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(PFStepper.buttonTouchUp(_:)), for: UIControl.Event.touchUpOutside)
        return button
    }()
    lazy var bottomButton: UIButton = {
        let button = UIButton()
        button.setTitle(self.bottomButtonText, for: UIControl.State())
        button.setTitleColor(self.buttonsTextColor, for: UIControl.State())
        button.backgroundColor = self.buttonsBackgroundColor
        button.titleLabel?.font = self.buttonsFont
        button.addTarget(self, action: #selector(PFStepper.bottomButtonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(PFStepper.buttonTouchUp(_:)), for: UIControl.Event.touchUpInside)
        button.addTarget(self, action: #selector(PFStepper.buttonTouchUp(_:)), for: UIControl.Event.touchUpOutside)
        return button
    }()
    
    enum StepperState {
        case stable, shouldIncrease, shouldDecrease
    }
    
    var stepperState = StepperState.stable {
        didSet {
            if stepperState != .stable {
                updateValue()
                if autorepeat {
                    scheduleTimer()
                }
            }
        }
    }
    
    let limitHitAnimationDuration = TimeInterval(0.1)
    var timer: Timer?
    
    /** When UIStepper reaches its top speed, it alters the value with a time interval of ~0.05 sec.
     The user pressing and holding on the stepper repeatedly:
     - First 2.5 sec, the stepper changes the value every 0.5 sec.
     - For the next 1.5 sec, it changes the value every 0.1 sec.
     - Then, every 0.05 sec.
     */
    let timerInterval = TimeInterval(0.05)
    
    /// Check the handleTimerFire: function. While it is counting the number of fires, it decreases the mod value so that the value is altered more frequently.
    var timerFireCount = 0
    var timerFireCountModulo: Int {
        if timerFireCount > 80 {
            return 1 // 0.05 sec * 1 = 0.05 sec
        } else if timerFireCount > 50 {
            return 2 // 0.05 sec * 2 = 0.1 sec
        } else {
            return 10 // 0.05 sec * 10 = 0.5 sec
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        addSubview(topButton)
        addSubview(bottomButton)
        
        backgroundColor = buttonsBackgroundColor
        NotificationCenter.default.addObserver(self, selector: #selector(PFStepper.reset), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    open override func layoutSubviews() {
        let buttonWidth = bounds.size.width
        
        topButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: bounds.size.height / 2)
        bottomButton.frame = CGRect(x: 0, y: bounds.size.height / 2, width: buttonWidth, height: bounds.size.height / 2)
    }
    
    func updateValue() {
        if stepperState == .shouldIncrease {
            value += stepValue
        } else if stepperState == .shouldDecrease {
            value -= stepValue
        }
    }
    
    deinit {
        resetTimer()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Button Events
extension PFStepper {
    @objc func reset() {
        stepperState = .stable
        resetTimer()
        
        topButton.isEnabled = true
        bottomButton.isEnabled = true
    }
    
    @objc func topButtonTouchDown(_ button: UIButton) {
        bottomButton.isEnabled = false
        resetTimer()
        
        if value == minimumValue {
            button.setTitle("", for: UIControl.State())
        } else {
            stepperState = .shouldDecrease
        }
        
    }
    
    @objc func bottomButtonTouchDown(_ button: UIButton) {
        topButton.isEnabled = false
        resetTimer()
        
        if value == maximumValue {
            button.setTitle("", for: UIControl.State())
        } else {
            stepperState = .shouldIncrease
        }
    }
    
    @objc func buttonTouchUp(_ button: UIButton) {
        reset()
    }
}

// MARK: - Timer
extension PFStepper {
    @objc func handleTimerFire(_ timer: Timer) {
        timerFireCount += 1
        
        if timerFireCount % timerFireCountModulo == 0 {
            updateValue()
        }
    }
    
    func scheduleTimer() {
        timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(PFStepper.handleTimerFire(_:)), userInfo: nil, repeats: true)
    }
    
    func resetTimer() {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
            timerFireCount = 0
        }
    }
}
