//
//  CertificateVerificationView.swift
//  certificates
//
//  Created by Michael Shin on 9/12/18.
//  Copyright © 2018 Learning Machine, Inc. All rights reserved.
//

import UIKit

class CertificateVerificationView: UIView {
    
    let labelLeftMargin: CGFloat = 53.0
    let stepLabelVerticalMargin: CGFloat = 14.0
    let substepLabelVerticalMargin: CGFloat = 7.0
    let trackWidth: CGFloat = 12.0
    let trackCenterX: CGFloat = 14.0
    let trackSubstepPadding: CGFloat = 12.0
    let trackEndPadding: CGFloat = 17.0
    let substepDotDiameter: CGFloat = 6.0
    
    var allSteps: [VerificationStep]?
    var stepLabels: [String: UILabel] = [:]
    var substepLabels: [String: UILabel] = [:]
    var stepIcons: [String: UIImageView] = [:]
    var parentStepCodes: [String: String] = [:]
    var substepFailIcon: UIImageView?
    var substepFailCode: String?
    var substepFailLabel: UILabel?
    var successLabel: UILabel?
    var successIcon: UIImageView?
    var trackHeight: CGFloat = 0.0
    var trackProgressHeight: CGFloat = 0.0
    var currentSubstepCode: String?
    
    func setSteps(steps: [VerificationStep]) {
        allSteps = steps
        
        for step in allSteps! {
            let stepIcon = UIImageView(image: UIImage(named: "verify_step_pending"))
            addSubview(stepIcon)
            stepIcons[step.code] = stepIcon
            
            let stepLabel = LabelC7T3S()
            stepLabel.text = step.label
            stepLabel.numberOfLines = 0
            stepLabel.sizeToFit()
            addSubview(stepLabel)
            stepLabels[step.code] = stepLabel
            
            for substep in step.substeps {
                let substepLabel = LabelC7T2R()
                substepLabel.text = substep.label
                substepLabel.numberOfLines = 0
                substepLabel.sizeToFit()
                addSubview(substepLabel)
                substepLabels[substep.code] = substepLabel
                parentStepCodes[substep.code] = substep.parentStep
            }
        }
        setNeedsDisplay()
    }
    
    func setSubstepComplete(substep: VerificationSubstep) {
        currentSubstepCode = substep.code
        
        let stepCode = parentStepCodes[substep.code]!
        let stepLabel = stepLabels[stepCode]!
        stepLabel.font = Style.Font.T3B
        stepLabel.textColor = Style.Color.C6
        
        let substepLabel = substepLabels[substep.code]!
        substepLabel.font = Style.Font.T2S
        
        if substep.status == .success {
            substepLabel.textColor = Style.Color.C6
        } else {
            substepLabel.textColor = Style.Color.C9
            
            substepFailCode = substep.code
            substepFailIcon = UIImageView(image: UIImage(named: "verify_substep_fail"))
            addSubview(substepFailIcon!)
            
            substepFailLabel = LabelC9T2B()
            substepFailLabel!.text = substep.errorMessage
            substepFailLabel!.sizeToFit()
            addSubview(substepFailLabel!)
        }
        
        if isLastSubstep(stepCode: stepCode, substepCode: substep.code) {
            let stepIcon = stepIcons[stepCode]!
            
            if substep.status == .success {
                stepIcon.image = UIImage(named: "verify_step_success")
            } else {
                stepIcon.image = UIImage(named: "verify_step_fail")
            }
            
            // Credential is successfully verified
            if substep.status == .success, stepCode == allSteps![allSteps!.count - 1].code {
                successIcon = UIImageView(image: UIImage(named: "verify_success"))
                addSubview(successIcon!)
                
                successLabel = LabelC6T3B()
                successLabel!.text = Localizations.Verified
                successLabel!.sizeToFit()
                addSubview(successLabel!)
            }
        }
    }
    
    func isLastSubstep(stepCode: String, substepCode: String) -> Bool {
        for step in allSteps! {
            if step.code == stepCode {
                for (i, substep) in step.substeps.enumerated() {
                    if substep.code == substepCode {
                        return i == (step.substeps.count - 1)
                    }
                }
                break
            }
        }
        return false
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Draw track
        context.setStrokeColor(Style.Color.C8.cgColor)
        context.setLineWidth(trackWidth)
        context.setLineCap(.round)
        context.beginPath()
        context.move(to: CGPoint(x: trackCenterX, y: 0))
        context.addLine(to: CGPoint(x: trackCenterX, y: trackHeight))
        context.strokePath()
        
        // Draw progress on track
        context.setStrokeColor(Style.Color.C4.cgColor)
        context.setLineWidth(trackWidth)
        context.setLineCap(.round)
        context.beginPath()
        context.move(to: CGPoint(x: trackCenterX, y: 0))
        context.addLine(to: CGPoint(x: trackCenterX, y: trackProgressHeight))
        context.strokePath()
        
        // Draw substep dots
        for substepLabels in substepLabels.values {
            context.setFillColor(Style.Color.C1.cgColor)
            context.fillEllipse(in: CGRect(x: trackCenterX - substepDotDiameter / 2,
                                           y: substepLabels.center.y - substepDotDiameter / 2,
                                           width: substepDotDiameter,
                                           height: substepDotDiameter))
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let allSteps = allSteps else {
            return
        }
        
        var y: CGFloat = 0.0
        var substepLabelsIndex = 0
        
        for (i, step) in allSteps.enumerated() {
            
            if i > 0 {
                y += stepLabelVerticalMargin
            }
            
            // Position step label
            let stepLabel = stepLabels[step.code]!
            stepLabel.frame = CGRect.init(x: labelLeftMargin,
                                          y: y,
                                          width: frame.size.width - labelLeftMargin,
                                          height: stepLabel.frame.size.height)
            y += stepLabel.frame.size.height + stepLabelVerticalMargin
            
            // Position step icons
            let stepIcon = stepIcons[step.code]!
            stepIcon.center = CGPoint(x: trackCenterX,
                                      y: stepLabel.center.y)
            
            
            // Position substep labels
            for (j, substep) in step.substeps.enumerated() {
                let substepLabel = substepLabels[substep.code]!
                substepLabelsIndex += 1
                
                substepLabel.frame = CGRect.init(x: labelLeftMargin,
                                                 y: y,
                                                 width: frame.size.width - labelLeftMargin,
                                                 height: substepLabel.frame.size.height)
                
                y += substepLabel.frame.size.height
                
                if let currentSubstepCode = currentSubstepCode, currentSubstepCode == substep.code {
                    trackProgressHeight = substepLabel.center.y + trackSubstepPadding
                }
                
                // Position substep fail icon and label
                if let substepFailCode = substepFailCode, substepFailCode == substep.code {
                    if let substepFailIcon = substepFailIcon {
                        substepFailIcon.center = CGPoint(x: trackCenterX, y: stepLabel.center.y)
                    }
                    
                    if let errorLabel = substepFailLabel {
                        y += substepLabelVerticalMargin
                        
                        errorLabel.frame = CGRect.init(x: labelLeftMargin,
                                                       y: y,
                                                       width: frame.size.width - labelLeftMargin,
                                                       height: errorLabel.frame.size.height)
                    }
                }
                
                if j != (step.substeps.count - 1) {
                    y += substepLabelVerticalMargin
                }
            }
            
            // Position success icon
            if i == (allSteps.count - 1) {
                trackHeight = y + trackEndPadding
                
                if let successIcon = successIcon, let successLabel = successLabel {
                    y += stepLabelVerticalMargin
                    
                    successLabel.frame = CGRect.init(x: labelLeftMargin,
                                                     y: y,
                                                     width: frame.size.width - labelLeftMargin,
                                                     height: successLabel.frame.size.height)
                    
                    successIcon.center = CGPoint(x: trackCenterX, y: successLabel.center.y)
                    y += successIcon.frame.size.height
                    
                    trackProgressHeight = trackHeight
                }
            }
        }
        
        //Re-draw track
        var newFrame = frame
        newFrame.size.height = trackHeight + 8.0
        frame = newFrame
        setNeedsDisplay()
    }
}
