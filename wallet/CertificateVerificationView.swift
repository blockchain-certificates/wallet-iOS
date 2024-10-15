//
//  CertificateVerificationView.swift
//  certificates
//
//  Created by Michael Shin on 9/12/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit

class CertificateVerificationView: UIView {
    
    let animationKey = "rotationAnimation"
    
    let labelLeftMargin: CGFloat = 53.0
    let stepLabelVerticalMargin: CGFloat = 14.0
    let suiteLabelVerticalTopMargin: CGFloat = 12.0
    let suiteLabelVerticalBottomMargin: CGFloat = 8.0
    let substepLabelVerticalMargin: CGFloat = 7.0
    let trackWidth: CGFloat = 12.0
    let trackCenterX: CGFloat = 14.0
    let trackSubstepPadding: CGFloat = 10.0
    let trackEndPadding: CGFloat = 17.0
    let substepDotDiameter: CGFloat = 6.0
    
    var allSteps: [VerificationStep]?
    var stepLabels: [String: UILabel] = [:]
    var suitesLabels: [String: UILabel] = [:]
    var substepLabels: [String: UILabel] = [:]
    var stepIcons: [String: UIImageView] = [:]
    var parentStepCodes: [String: String] = [:]
    var flatSubstepsCodesByParentStep: [String: [String]] = [:]
    var substepFailIcon: UIImageView?
    var substepFailCode: String?
    var substepFailLabel: UILabel?
    var successLabel: UILabel?
    var successIcon: UIImageView?
    var trackHeight: CGFloat = 0.0
    var trackProgressHeight: CGFloat = 0.0
    var currentSubstepCode: String?
    
    var delegate: CertificateVerificationViewDelegate?
    
    func setSteps(steps: [VerificationStep]) {
        allSteps = steps
        
        for step in allSteps! {
            let stepIcon = UIImageView(image: UIImage(named: "verify_step_pending"))
            addSubview(stepIcon)
            stepIcons[step.code] = stepIcon
            
            let stepLabel = LabelC7T3S()
            stepLabel.text = step.label
            stepLabel.numberOfLines = 0
            addSubview(stepLabel)
            stepLabels[step.code] = stepLabel
            
            setSubSteps(group: &substepLabels, parentStep: step.code, subSteps: step.substeps)
            
            for suite in step.suites {
                if suite.substeps.count > 0 && step.suites.count > 1 {
                    setSubStepSuiteTitle(parentStep: step.code, suite: suite)
                }
                setSubSteps(group: &substepLabels, parentStep: step.code, subSteps: suite.substeps)
            }
        }
        
        setNeedsDisplay()
    }
    
    func setSubStepSuiteTitle (parentStep: String, suite: VerificationSuite) {
        let suiteLabel = LabelC7T3S()
        let proofType : String = suite.proofType
        let parentStepSuiteCode : String = parentStep + suite.proofType
        suiteLabel.text = proofType
        suiteLabel.textColor = Style.Color.C12
        suiteLabel.numberOfLines = 0
        addSubview(suiteLabel)
        suitesLabels[parentStepSuiteCode] = suiteLabel
        parentStepCodes[proofType] = suite.substeps[0].parentStep
    }
    
    func setSubSteps (group: inout [String: UILabel], parentStep: String, subSteps: [VerificationSubstep], suiteProofType: String? = "") {
        for substep in subSteps {
            let substepLabel = LabelC7T2R()
            substepLabel.text = substep.label
            substepLabel.numberOfLines = 0
            addSubview(substepLabel)
            group[parentStep + substep.code] = substepLabel
            parentStepCodes[substep.code] = substep.parentStep
            
            if flatSubstepsCodesByParentStep[parentStep] == nil {
                flatSubstepsCodesByParentStep[parentStep] = []
            }
            flatSubstepsCodesByParentStep[parentStep]!.append(suiteProofType! + substep.code)
        }
    }
    
    func updateSubstepStatus(substep: VerificationSubstep) {
        let stepCode = parentStepCodes[substep.code]!
        let stepLabel = stepLabels[stepCode]!
        let substepLabel = substepLabels[substep.parentStep! + substep.code]!
        
        let stepIcon = stepIcons[stepCode]!
        
        if substep.status == .verifying {
            
            stepLabel.font = Style.Font.T3B
            stepLabel.textColor = Style.Color.C6
            stepIcon.image = UIImage(named: "verify_step_inprogress")
            animateStepIcon(stepIcon)
            
        } else {
            currentSubstepCode = substep.code
            
            substepLabel.font = Style.Font.T2S
            
            if substep.status == .success {
                substepLabel.textColor = Style.Color.C6
            } else {
                substepLabel.textColor = Style.Color.C9
                
                substepFailCode = substep.code
                substepFailIcon = UIImageView(image: UIImage(named: "verify_substep_fail"))
                addSubview(substepFailIcon!)
                
                substepFailLabel = LabelC9T2B()
                substepFailLabel!.numberOfLines = 0
                substepFailLabel!.text = substep.errorMessage
                addSubview(substepFailLabel!)
                
                stepIcon.layer.removeAllAnimations()
                stepIcon.image = UIImage(named: "verify_step_fail")
            }
            
            if isLastSubstepInStep(stepCode: stepCode, substepCode: substep.code) {
                if substep.status == .success {
                    stepIcon.layer.removeAllAnimations()
                    stepIcon.image = UIImage(named: "verify_step_success")
                }
                
                // Credential is successfully verified
                if substep.status == .success, stepCode == allSteps![allSteps!.count - 1].code {
                    successIcon = UIImageView(image: UIImage(named: "verify_success"))
                    addSubview(successIcon!)
                    
                    successLabel = LabelC6T3B()
                    successLabel!.text = Localizations.Verified
                    addSubview(successLabel!)
                }
            }
        }
        setNeedsLayout()
        setNeedsDisplay()
    }
    
    func animateStepIcon(_ stepIcon: UIImageView) {
        let animationKey = "rotationAnimation"
        
        if stepIcon.layer.animation(forKey: animationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.toValue = NSNumber(value: .pi * 2.0)
            rotationAnimation.duration = 1.2
            rotationAnimation.isCumulative = true
            rotationAnimation.repeatCount = .infinity
            stepIcon.layer.add(rotationAnimation, forKey: animationKey)
        }
    }
    
    func isLastSubstepInStep(stepCode: String, substepCode: String) -> Bool {
        let parentFlatSubsteps = flatSubstepsCodesByParentStep[stepCode]
        return parentFlatSubsteps?.firstIndex(where: {$0 == substepCode}) == parentFlatSubsteps!.count - 1
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Draw track
        if allSteps != nil {
            context.setStrokeColor(Style.Color.C8.cgColor)
            context.setLineWidth(trackWidth)
            context.setLineCap(.round)
            context.beginPath()
            context.move(to: CGPoint(x: trackCenterX, y: trackWidth / 2))
            context.addLine(to: CGPoint(x: trackCenterX, y: trackHeight))
            context.strokePath()
        }
        
        // Draw progress on track
        if currentSubstepCode != nil {
            context.setStrokeColor(Style.Color.C4.cgColor)
            context.setLineWidth(trackWidth)
            context.setLineCap(.round)
            context.beginPath()
            context.move(to: CGPoint(x: trackCenterX, y: trackWidth / 2))
            context.addLine(to: CGPoint(x: trackCenterX, y: trackProgressHeight))
            context.strokePath()
        }
        
        // Draw substep dots
        if allSteps != nil {
            for substepLabels in substepLabels.values {
                context.setFillColor(Style.Color.C1.cgColor)
                context.fillEllipse(in: CGRect(x: trackCenterX - substepDotDiameter / 2,
                                               y: substepLabels.center.y - substepDotDiameter / 2,
                                               width: substepDotDiameter,
                                               height: substepDotDiameter))
            }
        }
    }
    
    func layoutSubsteps (substeps: [VerificationSubstep], y: inout CGFloat, labelWidth: CGFloat, substepLabelsIndex: inout Int) {
        // Position substep labels
        for (j, substep) in substeps.enumerated() {
            
            let substepLabel = substepLabels[substep.parentStep! + substep.code]!
            substepLabelsIndex += 1
            
            substepLabel.frame = CGRect(x: labelLeftMargin,
                                        y: y,
                                        width: labelWidth,
                                        height: substepLabel.text!.height(withConstrainedWidth: labelWidth, font: substepLabel.font))
            
            y += substepLabel.frame.size.height
            
            if let currentSubstepCode = currentSubstepCode, currentSubstepCode == substep.code {
                trackProgressHeight = substepLabel.center.y + trackSubstepPadding
                delegate?.trackProgressChanged(y: trackProgressHeight)
            }
            
            // Position substep fail icon and label
            if let substepFailCode = substepFailCode, substepFailCode == substep.code {
                trackProgressHeight = substepLabel.center.y
                
                if let substepFailIcon = substepFailIcon {
                    substepFailIcon.center = CGPoint(x: trackCenterX, y: substepLabel.center.y)
                }
                
                if let errorLabel = substepFailLabel {
                    y += substepLabelVerticalMargin
                    
                    errorLabel.frame = CGRect(x: labelLeftMargin,
                                              y: y,
                                              width: labelWidth,
                                              height: errorLabel.text!.height(withConstrainedWidth: labelWidth, font: errorLabel.font))
                    y += errorLabel.frame.size.height
                }
            }
            
            if j != (substeps.count - 1) {
                y += substepLabelVerticalMargin
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let allSteps = allSteps else {
            return
        }
        
        var y: CGFloat = 0.0
        var substepLabelsIndex = 0
        let labelWidth = frame.size.width - labelLeftMargin
        
        for (i, step) in allSteps.enumerated() {
            
            if i > 0 {
                y += stepLabelVerticalMargin
            }
            
            // Position step label
            let stepLabel = stepLabels[step.code]!
            stepLabel.frame = CGRect(x: labelLeftMargin,
                                     y: y,
                                     width: labelWidth,
                                     height: stepLabel.text!.height(withConstrainedWidth: labelWidth, font: stepLabel.font))
            y += stepLabel.frame.size.height + stepLabelVerticalMargin
            
            // Position step icons
            let stepIcon = stepIcons[step.code]!
            stepIcon.center = CGPoint(x: trackCenterX,
                                      y: stepLabel.center.y)
            
            // Position substep labels
            layoutSubsteps(substeps: step.substeps, y: &y, labelWidth: labelWidth, substepLabelsIndex: &substepLabelsIndex)
            
            // Position suite labels
            if step.suites.count > 0 {
                for (_, suite) in step.suites.enumerated() {
                    if suite.substeps.count > 0 {
                        if step.suites.count > 1 {
                            y += suiteLabelVerticalTopMargin
                            
                            let parentStepSuiteCode : String = step.code + suite.proofType;
                            
                            let suiteLabel = suitesLabels[parentStepSuiteCode]!
                            suiteLabel.frame = CGRect(x: labelLeftMargin,
                                                     y: y,
                                                     width: labelWidth,
                                                     height: stepLabel.text!.height(withConstrainedWidth: labelWidth, font: suiteLabel.font))
                            y += suiteLabel.frame.size.height + suiteLabelVerticalBottomMargin
                        }
                        
                        // Position substep labels
                        layoutSubsteps(substeps: suite.substeps, y: &y, labelWidth: labelWidth, substepLabelsIndex: &substepLabelsIndex)
                    }
                }
            }
            
            // Position success icon
            if i == (allSteps.count - 1) {
                trackHeight = y + trackEndPadding
                
                if let successIcon = successIcon, let successLabel = successLabel {
                    y += stepLabelVerticalMargin
                    
                    successLabel.frame = CGRect(x: labelLeftMargin,
                                                y: y,
                                                width: labelWidth,
                                                height: successLabel.text!.height(withConstrainedWidth: labelWidth, font: successLabel.font))
                    
                    successIcon.center = CGPoint(x: trackCenterX, y: successLabel.center.y)
                    y += successIcon.frame.size.height
                    
                    trackProgressHeight = trackHeight
                    delegate?.trackProgressChanged(y: trackProgressHeight)
                }
            }
        }
        
        // Re-draw track
        var newFrame = frame
        newFrame.size.height = trackHeight + 8.0
        frame = newFrame
        setNeedsDisplay()
    }
}

protocol CertificateVerificationViewDelegate {
    func trackProgressChanged(y: CGFloat)
}
