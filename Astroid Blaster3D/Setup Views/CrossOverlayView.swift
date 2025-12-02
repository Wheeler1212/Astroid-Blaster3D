//
//  CrossOverlayView.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 19.11.25.
//

import SceneKit
import SpriteKit
import UIKit


    // Overlay mit Steuerkreuz + vertikaler Leiste + Lautstärke‑Slider (links oben)
    class CrossOverlayView: UIView {

        private let crossLayer    = CAShapeLayer()   // Kreuz unten rechts
        private let verticalLayer = CAShapeLayer()   // Vertikaler Balken unten links

        // MARK: ‑ Lautstärke‑Slider
        private let volumeSlider: UISlider = {
            let s = UISlider()
            s.minimumValue = 0
            s.maximumValue = 1
            s.value        = 0.7         // Start‑Lautstärke
            s.transform    = CGAffineTransform(rotationAngle: -.pi/2) // vertikal
            s.tintColor    = .white.withAlphaComponent(0.9)
            return s
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isMultipleTouchEnabled = true
            setupOverlay()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = .clear
            isMultipleTouchEnabled = true
            setupOverlay()
        }

        // MARK: ‑ Overlay‑Aufbau
        private func setupOverlay() {
            drawControlCross()          // unten rechts
            drawVerticalBar()           // unten links
            addVolumeSlider()           // links oben
        }

        // MARK: – Einzelteile
        private func drawControlCross() {
            let path = UIBezierPath()

            // Position unten rechts
            let center = CGPoint(
                x: bounds.maxX - DeviceConfig.crossSize - DeviceConfig.margin,
                y: bounds.maxY - DeviceConfig.crossSize - DeviceConfig.margin
            )

            // horizontaler Balken
            let hRect = CGRect(
                x: center.x - DeviceConfig.crossSize/2,
                y: center.y - DeviceConfig.lineWidth/2,
                width: DeviceConfig.crossSize,
                height: DeviceConfig.lineWidth
            )
            // vertikaler Balken
            let vRect = CGRect(
                x: center.x - DeviceConfig.lineWidth/2,
                y: center.y - DeviceConfig.crossSize/2,
                width: DeviceConfig.lineWidth,
                height: DeviceConfig.crossSize
            )

            path.append(UIBezierPath(roundedRect: hRect, cornerRadius: DeviceConfig.cornerRadius))
            path.append(UIBezierPath(roundedRect: vRect, cornerRadius: DeviceConfig.cornerRadius))

            crossLayer.path = path.cgPath
            crossLayer.fillColor = UIColor.white.withAlphaComponent(0.2).cgColor
            layer.addSublayer(crossLayer)
        }

        private func drawVerticalBar() {
            // Vertikale Steuerleiste unten links
            let vPath = UIBezierPath()
            let center = CGPoint(
                x: DeviceConfig.margin + DeviceConfig.crossSize*0.5,
                y: bounds.maxY - DeviceConfig.crossSize - DeviceConfig.margin
            )
            let rect = CGRect(
                x: center.x - DeviceConfig.lineWidth/2,
                y: center.y - DeviceConfig.crossSize/2,
                width: DeviceConfig.lineWidth,
                height: DeviceConfig.crossSize
            )
            vPath.append(UIBezierPath(roundedRect: rect, cornerRadius: DeviceConfig.cornerRadius))

            verticalLayer.path = vPath.cgPath
            verticalLayer.fillColor = UIColor.white.withAlphaComponent(0.2).cgColor
            layer.addSublayer(verticalLayer)
        }

        private func addVolumeSlider() {
            // Slider nach LINKS OBEN legen
            let sliderHeight: CGFloat = 140   // sichtbare Länge
            let sliderWidth : CGFloat = 30    // Breite des Daumens

            volumeSlider.frame = CGRect(
                x: DeviceConfig.margin,                   // Abstand von linker Kante
                y: DeviceConfig.margin + 20,              // etwas unter StatusBar
                width: sliderWidth,
                height: sliderHeight
            )
            volumeSlider.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
            volumeSlider.addTarget(self, action: #selector(volumeChanged(_:)), for: .valueChanged)
            addSubview(volumeSlider)
        }

        @objc private func volumeChanged(_ sender: UISlider) {
            SoundManager.shared.setMusicVolume(sender.value)
        }
    }
