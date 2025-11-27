//
//  ButtonBuilder.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 23.04.25.
//

import UIKit

extension GameViewController {

    // MARK: - ButtonBuilder mit inout
    class ButtonBuilder {
        
        /// Blendet eine View mit sanfter Animation ein.
        static func fadeIn(_ view: UIView, delay: TimeInterval) {
            UIView.animate(withDuration: 1.0, delay: delay, options: .curveEaseInOut) {
                view.alpha = 1
            }
        }
        
        /// Erstellt einen einheitlich gestylten Button.
        static func makeStyledButton(title: String,
                                     fontSize: CGFloat,
                                     color: UIColor,
                                     tag: Int,
                                     frame: CGRect,
                                     target: Any,
                                     selector: Selector) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            button.setTitleColor(color, for: .normal)
            
            // Style: Rahmen, Ecken, Position
            button.layer.borderWidth = 2.0
            button.layer.borderColor = UIColor.white.cgColor
            button.layer.cornerRadius = 10
            button.frame = frame
            button.alpha = 0  // Wird später animiert eingeblendet
            
            // Identifikation & Interaktion
            button.tag = tag
            button.addTarget(target, action: selector, for: .touchUpInside)
            
            return button
        }
        
        /// Fügt die Hauptmenü-Buttons zur angegebenen View hinzu und speichert sie in `switchContainers`.
        static func addMainMenuButtons(to view: UIView,
                                       startingY: CGFloat,
                                       target: Any,
                                       switchContainers: inout [UIView]) {
            
            var currentY = startingY
            let buttonWidth: CGFloat = 250
            let buttonHeight: CGFloat = 50
            let spacing: CGFloat = 40
            let x: CGFloat = 100
            
            // 1. Start Game Button
            let startButton = makeStyledButton(
                        title: "Start Game",
                        fontSize: 24,
                        color: .yellow,
                        tag: ViewTags.startButton,
                        frame: CGRect(x: x, y: currentY, width: buttonWidth, height: buttonHeight),
                        target: target,
                        selector: #selector(GameViewController.startGameView))
            view.addSubview(startButton)
            fadeIn(startButton, delay: 0)
            switchContainers.append(startButton)
            currentY += buttonHeight + spacing
            
            // 2. Settings Button
            let settingsButton = makeStyledButton(
                        title: "Settings",
                        fontSize: 24,
                        color: .white,
                        tag: ViewTags.settingsButton,
                        frame: CGRect(x: x, y: currentY, width: buttonWidth, height: buttonHeight),
                        target: target,
                        selector: #selector(GameViewController.changeSettings))
            
            view.addSubview(settingsButton)
            fadeIn(settingsButton, delay: 0.2)
            switchContainers.append(settingsButton)
            currentY += buttonHeight + spacing
            
            // 3. Canvas Button (Nutzt denselben Selector wie Settings)
            let canvasButton = makeStyledButton(
                        title: "Canvas",
                        fontSize: 24,
                        color: .white,
                        tag: ViewTags.canvasButton,
                        frame: CGRect(x: x, y: currentY, width: buttonWidth, height: buttonHeight),
                        target: target,
                        selector: #selector(GameViewController.changeSettings))
            
            view.addSubview(canvasButton)
            fadeIn(canvasButton, delay: 0.3)
            switchContainers.append(canvasButton)
            currentY += buttonHeight + spacing
            
            // 4. Difficulty Button
            let difficultyButton = makeStyledButton(
                        title: "Difficulty",
                        fontSize: 24,
                        color: .white,
                        tag: ViewTags.difficultyButton,
                        frame: CGRect(x: x, y: currentY, width: buttonWidth, height: buttonHeight),
                        target: target,
                        selector: #selector(GameViewController.changeDifficulty))
            
            view.addSubview(difficultyButton)
            fadeIn(difficultyButton, delay: 0.4)
            switchContainers.append(difficultyButton)
            
            // 5. Anzeige für Schwierigkeitsgrad neben dem Button
            let difficultyLabel = UILabel()
            difficultyLabel.font = UIFont(name: "PressStart2P-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
            difficultyLabel.textColor = .white
            difficultyLabel.textAlignment = .center
            difficultyLabel.text = difficultyText(for: LevelManager.shared.difficulty)
            difficultyLabel.frame = CGRect(x: difficultyButton.frame.maxX + 36,
                                           y: difficultyButton.frame.minY,
                                           width: 200,
                                           height: buttonHeight)
            difficultyLabel.alpha = 0
            difficultyLabel.tag = ViewTags.difficultyLabel
            
            // Style für das Label
            difficultyLabel.layer.borderColor = UIColor.white.cgColor
            difficultyLabel.layer.borderWidth = 2
            difficultyLabel.layer.cornerRadius = 8
            difficultyLabel.layer.masksToBounds = true
            difficultyLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            
            view.addSubview(difficultyLabel)
            fadeIn(difficultyLabel, delay: 0.4)
            switchContainers.append(difficultyLabel)
        }
        
        /// Gibt den Text zum Schwierigkeitsgrad zurück.
        static func difficultyText(for level: LevelType) -> String {
            switch level {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }
    }
    
    @objc func changeDifficulty(_ sender: UIButton) {
        // Schwierigkeitsgrad wechseln
        switch LevelManager.shared.difficulty {
        case .easy:
            LevelManager.shared.difficulty = .medium
        case .medium:
            LevelManager.shared.difficulty = .hard
        case .hard:
            LevelManager.shared.difficulty = .easy
        }
        
        if let label = self.view.viewWithTag(ViewTags.difficultyLabel) as? UILabel {
            label.text = ButtonBuilder.difficultyText(for: LevelManager.shared.difficulty)
            
            // Farblich hervorheben je nach Schwierigkeit
            switch LevelManager.shared.difficulty {
            case .easy:
                label.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            case .medium:
                label.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.3)
            case .hard:
                label.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
            }
        }
        
        
        // Finde das zugehörige Label über den Tag
        if let label = self.view.viewWithTag(ViewTags.difficultyLabel) as? UILabel {
            label.text = ButtonBuilder.difficultyText(for: LevelManager.shared.difficulty)
        }
        
        //Damit auch der LevelManager informiert ist
        LevelManager.shared.nextLevel()
    }
    
    @objc func changeSettings(_ sender: UIButton) {
        guard let canvasView = canvasView, let settingsView = settingsView else { return }
        
        let isCanvasVisible = canvasView.frame.origin.x < DeviceConfig.screenWidth
        let isSettingsVisible = settingsView.frame.origin.x < DeviceConfig.screenWidth
        
        UIView.animate(withDuration: 0.6, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            if sender.tag == ViewTags.canvasButton { //103
                canvasView.frame.origin.x = isCanvasVisible ? DeviceConfig.screenWidth : DeviceConfig.screenWidth - 400
                settingsView.frame.origin.x = DeviceConfig.screenWidth
            } else if sender.tag == ViewTags.settingsButton { //102
                settingsView.frame.origin.x = isSettingsVisible ? DeviceConfig.screenWidth : DeviceConfig.screenWidth - 400
                canvasView.frame.origin.x = DeviceConfig.screenWidth
            }
        })
    }
}
