//
//  UIComponents.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 18.11.25.
//

import SceneKit
import SpriteKit
import AudioToolbox
import UIKit
import Foundation
import CoreGraphics
import AVFoundation

extension GameViewController {
    
    
    // MARK: Timer UpdateHUD
    func startTimerUpdateHUD() {
        DispatchQueue.main.async { [self] in
            timerUpdateHUD = Timer.scheduledTimer(
                withTimeInterval: 1.0,
                repeats: true) { [self] _ in
                    secondsCounter += 1 // Spielzeit
                    updateHUD() // Und dann auch gleich am Schirm korrigieren
                }
        }
    }
    
    // Funktion zum Erstellen der Settings-Ansicht
    func setupSettingsView() {
        //Position und Größe der aufgesetzten View für die Einstellungen. Position (0,0) ist links oben
        let settingsView = UIView(frame: CGRect(x: DeviceConfig.screenWidth,
                                                y: DeviceConfig.layout.switchPositionOffsetY, //DeviceConfig.screenHeight - 400,
                                                width: 250,
                                                height: 400))
        settingsView.backgroundColor = .clear
        settingsView.layer.cornerRadius = 10
        self.view.addSubview(settingsView)
        self.settingsView = settingsView
        
        // FIXME: Benamung und Funktion anpassen
        // Array von Tupeln ([(String, Selector, CGPoint)]).
        let switchData = [
            ("Debug Axis", #selector(showDebugAxisToggled(_:)), CGPoint(x: 50, y: 20)),
            ("Music", #selector(musicToggled(_:)), CGPoint(x: 50, y: 100)),
            ("Start Animation", #selector(startAnimationToggled(_:)), CGPoint(x: 50, y: 180)),
            ("Sound", #selector(SoundToggled(_:)), CGPoint(x: 50, y: 260))
        ]
        
        for (labelText, selector, position) in switchData {
            let switchContainer = createSwitchContainer(labelText: labelText, position: position, action: selector)
            settingsView.addSubview(switchContainer)
        }
    }
    
    func setupCanvasView() {
        let canvasView = UIView(frame: CGRect(x: DeviceConfig.screenWidth,
                                              y: DeviceConfig.screenHeight - 400,
                                              width: 250,
                                              height: 400))
        canvasView.backgroundColor = .clear
        canvasView.layer.cornerRadius = 10
        self.view.addSubview(canvasView)
        self.canvasView = canvasView
        
        let switchData = [
            ("ShadowAurora", 0, CGPoint(x: 50, y: 20)),
            ("NebulaDreams", 1, CGPoint(x: 50, y: 100)),
            ("VoidSerenity", 2, CGPoint(x: 50, y: 180)),
            ("OblivionSky", 3, CGPoint(x: 50, y: 260))
        ]
        
        for (labelText, tag, position) in switchData {
            let switchContainer = createSwitchContainer(labelText: labelText, position: position, action: #selector(changeGameSceneBackground(_:)))
            
            if let switchControl = switchContainer.subviews.compactMap({ $0 as? UISwitch }).first {
                switchControl.tag = tag
            }
            canvasView.addSubview(switchContainer)
            switchContainers.append(switchContainer)    // Versuch
        }
    }
    
    @objc func changeGameSceneBackground(_ sender: UISwitch) {
        guard let scene = gameScene else { return }
        
        let backgroundImages = [
            "ShadowAurora",
            "NebulaDreams",
            "VoidSerenity",
            "OblivionSky"
        ]
        
        // Prüfen, welcher Switch umgelegt wurde
        if sender.isOn {
            let selectedIndex = sender.tag // Jeder Switch hat einen eindeutigen Tag (0 bis 3)
            if selectedIndex < backgroundImages.count {
                let imageName = backgroundImages[selectedIndex]
                // iPad oder iPhone
                changeBackgroundImage(for: startImageView, baseName: imageName)
                selectedBackgroundImage = startImageView.image
            }
            
            // Andere Switches ausschalten, damit immer nur ein Bild aktiv ist
            for subview in canvasView?.subviews ?? [] {
                if let switchControl = subview.subviews.compactMap({ $0 as? UISwitch }).first, switchControl != sender {
                    switchControl.setOn(false, animated: true)
                }
            }
        } else {
            // TODO: Falls kein Bild aktiv ist, Standardhintergrund setzen
            scene.background.contents = UIImage(named: "DefaultSky.png") // 🔄 Optional: Standardbild
        }
    }
    
    private func createSwitchContainer(labelText: String, position: CGPoint, action: Selector) -> UIView {
        
        let containerWidth: CGFloat = 250
        let switchControl = UISwitch()
        switchControl.sizeToFit()
        switchControl.frame.origin = CGPoint(
            x: containerWidth - switchControl.bounds.width - 16,
            y: (50 - switchControl.bounds.height) / 2
        )
        
        let label = UILabel(frame: CGRect(x: 16, y: 10, width: containerWidth - switchControl.bounds.width - 32 - 16, height: 30))
        
        let container = UIView(frame: CGRect(x: position.x, y: position.y, width: 250, height: 50))
        container.backgroundColor = UIColor.clear
        container.layer.cornerRadius = 10
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.white.cgColor
        
        //let label = UILabel(frame: CGRect(x: 100, y: 10, width: 150, height: 30))
        label.text = labelText
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = UIColor.white
        
        //let switchControl = UISwitch(frame: CGRect(x: 20, y: 10, width: 0, height: 0))
        switchControl.isOn = false
        switchControl.addTarget(self, action: action, for: .valueChanged)
        
        // 🧠 SWITCH SPEICHERN, abhängig vom Label
        switch labelText {
        case "Music":
            self.musicSwitch = switchControl
        case "Sound":
            self.soundSwitch = switchControl
        case "Debug Axis":
            self.debugAxesSwitch = switchControl
        case "Start Animation":
            self.startAnimationSwitch = switchControl
        default:
            break
        }
        
        // Tap-Gesture hinzufügen (optional, wenn Du damit später was machst)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(switchContainerTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        
        container.addSubview(label)
        container.addSubview(switchControl)
        
        return container
    }
    
    // Damit der komplette Container als Klickbereich gewertet wird
    @objc private func switchContainerTapped(_ sender: UITapGestureRecognizer) {
        guard let container = sender.view else { return }
        
        // Suche den UISwitch im Container
        if let switchControl = container.subviews.compactMap({ $0 as? UISwitch }).first {
            switchControl.setOn(!switchControl.isOn, animated: true)  // Umschalten
            
            // Manuelles Senden des Events, falls notwendig
            switchControl.sendActions(for: .valueChanged)
        }
    }
    
    func difficultyText(for level: LevelType) -> String {
        switch level {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    //MARK: Next Level Button
    func setupNextLevelButton() {
        nextLevelButton = UIButton(type: .system)
        nextLevelButton.frame = CGRect(x: scnView.bounds.size.width / 2 - 100, y: scnView.bounds.size.height / 2 + 100, width: 200, height: 50)
        nextLevelButton.setTitle(" Next Level ", for: .normal)
        nextLevelButton.addTarget(self, action: #selector(nextLevelButtonTapped), for: .touchUpInside)
        
        // Rahmen hinzufügen
        nextLevelButton.layer.borderColor = UIColor.white.cgColor
        nextLevelButton.layer.borderWidth = 2.0
        
        // Schriftgröße und -farbe anpassen
        nextLevelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        nextLevelButton.setTitleColor(UIColor.white, for: .normal)
        
        // Ecken abrunden
        nextLevelButton.layer.cornerRadius = 10.0
        nextLevelButton.clipsToBounds = true
        
        // Schattierung hinzufügen
        nextLevelButton.layer.shadowColor = UIColor.black.cgColor
        nextLevelButton.layer.shadowOpacity = 0.5
        nextLevelButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        nextLevelButton.layer.shadowRadius = 5
        
        nextLevelButton.setTitleColor(UIColor.gray, for: .highlighted)
        nextLevelButton.isEnabled = false
        nextLevelButton.isHidden = true
        
        view.addSubview(nextLevelButton)
    }
    
    
    // Overlay (Steuerkreuz + Lautstärke) sanft einblenden und skalieren
    func showOverlay() {
        crossOverlay?.alpha = 0
        crossOverlay?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)  // Start: leicht kleiner
        crossOverlay?.isHidden = false
        
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: [],
                       animations: {
            self.crossOverlay?.alpha = 1
            self.crossOverlay?.transform = .identity  // Zur Originalgröße skalieren
        })
    }
    
    // Overlay (Steuerkreuz + Lautstärke) ausblenden und zurückskalieren
    func hideOverlay() {
        
        DispatchQueue.main.async { [self] in
            UIView.animate(withDuration: 0.3,
                           animations: {
                self.crossOverlay?.alpha = 0
                self.crossOverlay?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)  // Leicht zusammenschrumpfen
            }, completion: { _ in
                self.crossOverlay?.isHidden = true
            })
        }
    }
    
    // Button "Next Level" wurde gedrückt
    @objc func nextLevelButtonTapped() {
        secondsCounter = 0     // Zeitzähler
        asteroidCountActive = 0
        // Wieder Kollisionen für TwinShip
        twinShipNode.physicsBody?.collisionBitMask = combineBitMasks([
                                                                .colorfullStars,
                                                                .ballWall,
                                                                .asteroid])
        // Enemies und Asteroiden ausblenden
        despawnAllEnemies()
        nextLevelUpdate() // Zuweisung der restlichen let/var und Level let/var
        levelClear = false
        gameState = .running
        //Overlays
        showCollisionDisplay()
        if currentMode.contains(.overlay) {
            showOverlay()
        }
        
        //NextLevelButton ausblenden
        UIView.animate(withDuration: 1.0, delay: 1.0, options: .curveEaseInOut, animations: { [self] in
            nextLevelButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            // Wenn angezeigt: BonusButton auch scalieren
            if bonusState == .reached {
                bonusRoundButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        }, completion:{ [self] _ in
            // Button nach der Animation verstecken und deaktivieren
            nextLevelButton.isHidden = true
            nextLevelButton.isEnabled = false
            // Originalgröße sofort wiederherstellen
            nextLevelButton.transform = .identity
            
            // Wenn Button für Bonus Runde auch angezeigt wird
            if bonusState == .reached {
                bonusRoundButton.isHidden = true
                bonusRoundButton.isEnabled = false
                bonusRoundButton.transform = .identity
            }
            // Wenn Next Level Button gedrückt
            startGameDisplay() // Level starten
        })
    }
    
    // MARK: Clear Level und Update HUD
    @objc func updateHUD() {    // Wird im Sekunden Takt durch Timer aufgerufen
        // Wenn alle Asteroids zerstört dann levelClear und HUD update stoppen
        DispatchQueue.main.async { [self] in
            if asteroidCountMax == 0 {      // Level beendet
                levelClear = true
                if timerUpdateHUD != nil {  // HUD Update (mit Sekunden) stoppen
                    timerUpdateHUD!.invalidate()
                    timerUpdateHUD = nil
                }
            }
            
            DispatchQueue.main.async { [self] in
                debugHUD.setValue(String(format: "%.0f", bigFlashOnScreenDuration), for: "bigFlashOnScreenDuration")
                debugHUD.setValue("\(currentEnemy)", for: "currentEnemy")
                debugHUD.setValue("\(spaceInvaderState)", for: "spaceInvaderState")
                debugHUD.setValue("\(spaceProbeState)", for: "spaceProbeState")
                debugHUD.setValue("\(colorfullStarsState)", for: "colorfullStarsState")
                debugHUD.setValue("\(bigFlashState)", for: "bigFlashState")
                debugHUD.setValue("\(ballWallState)", for: "ballWallState")
            }
            
            // HUD aktualisieren
            numberCounterAsteroidsLabel.text = "Asteroids:"
            numberCounterAsteroidsLabelValue.text = "\(asteroidCountMax)"
            
            scoreLabel.text = "Score:"
            scoreLabelValue.text = "\(Int(floor(score)))"
            
            timeCounterLabel.text = "Time:"
            timeCounterLabelValue.text = "\(secondsCounter)"
            
            labelGameLevel.text = "Level:"
            labelGameLevelValue.text = "\(LevelManager.shared.levelCount)"
            
            labelRemainingLives.text = "Lives"
            labelRemainingLivesValue.text = "\(playerLives)"
        }
    }
    
    
    
    func levelClearDisplay() {
        
        hideCollisionDisplay() // Collisions Display Animiert ausblenden
        hideOverlay() // Steuerkreuz ausblenden
        
        twinShipNode.physicsBody?.collisionBitMask = CollisionCategory.none.bitMask
        gameState = .paused
        
        // TODO: Berechnung der Bonuspunkte muss eventuell noch angepasst werden
        //pointsUpdateCount = 10000
        pointsUpdateCount = asteroidMaxNumberOnScreen * 100 / secondsCounter
        bonusLabel.text = "Level Clear - Bonuspoints: \(pointsUpdateCount)"
        
        if pointsUpdateCount > 1 {
            bonusState = .reached
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            // Animation Level Clear sichtbar machen und vergrößern
            scaleLevelClearLabels()
            // Texte setzen basierend auf den Punkten
            setLevelClearMotivationText(for: pointsUpdateCount)
        }
        
        // Damit es im neuen Level nicht zu hektisch wird
        stopAllAsteroidsRotation(asteroidNode)
        
        // Konstante für Bonuspunkte zum Score verrechnen
        let interval = 0.05 // Intervall für den Timer
        let decayFactor = 0.05 // Steuerung des "Abklingens"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
            bonusPointsTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [self] _ in
                // Exponentielle Abnahme der Punkte
                let pointsDifferenz = max(1, Int(Double(pointsUpdateCount) * decayFactor))
                
                // Punkte abziehen
                pointsUpdateCount -= pointsDifferenz
                score += Float(pointsDifferenz)
                
                // Timer stoppen, wenn Punkte auf 0
                if pointsUpdateCount <= 0 {
                    pointsUpdateCount = 0
                    bonusPointsTimer?.invalidate()
                    bonusPointsTimer = nil
                }
                updateHUD()
                bonusLabel.text = "Level Clear - Bonuspoints: \(pointsUpdateCount)"
            }
        }
        
        // Nach 10 Sekunden "Next Level Button" einblenden
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [self] in
            
            // Kleine Hilfsfunktion: Button vorbereiten & animiert einblenden
            func showButton(_ button: UIButton, duration: TimeInterval = 1.0) {
                button.isEnabled = true
                button.isHidden = false
                button.alpha = 0.0
                
                UIView.animate(withDuration: duration) {
                    button.alpha = 1.0
                }
            }
            
            //if bonusState == .reached
            if bonusState == .reached {
                showButton(bonusRoundButton)
            }
            
            showButton(nextLevelButton)
            
            // Level-Clear-Labels ausblenden
            UIView.animate(withDuration: 1.0) { [self] in
                centerLabel1.alpha = 0.0
                centerLabel2.alpha = 0.0
                bonusLabel.alpha = 0.0
                
            }
        }
    }
    
    @objc func bonusRoundButtonTapped() {
        // Für Next Level bestimmte Variable zurücksetzten
        secondsCounter = 0      // Zeitzähler
        gameState = .paused     
        invalidateTimer()       // Alle Timer löschen
        despawnAllEnemies()     // Alle Objekte verschwinden lassen
        
        // Eventuell noch vorhandene Asteroids ausblenden
        for asteroid in asteroidNode.prefix(20) {
            asteroid.runAction(SCNAction.fadeOut(duration: 2))
        }
        
        // Buttons ausblenden und danach verstecken und die Bonus-Runde starten
        UIView.animate(withDuration: 1.0, delay: 1.0, options: .curveEaseInOut, animations: { [self] in
            nextLevelButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            bonusRoundButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }, completion:{ [self] _ in
            // Button nach der Animation verstecken und deaktivieren
            nextLevelButton.isHidden = true
            nextLevelButton.isEnabled = false
            nextLevelButton.transform = .identity // Originalgröße sofort wiederherstellen
            
            bonusRoundButton.isHidden = true
            bonusRoundButton.isEnabled = false
            bonusRoundButton.transform = .identity
            
            bonusState = .enabled
            // BonusRunde mit Animation starten
            animateTwinShipForBonusRound()
        })
    }
    
    private func setLevelClearMotivationText(for points: Int) {
        
        let bonusMessages = [
            "Bonus Round Unlocked, \(player1)!",
            "Get Ready, \(player1)! Time for a Bonus Round!",
            "Bonus Round Achieved, \(player1)!",
            "Impressive, \(player1)! Bonus Stage Unlocked!"
        ]
        
        let lowScoreMessages = [
            "Come on, \(player1)! You can do better!",
            "Don't give up, \(player1)! The next round is yours!",
            "Keep trying, \(player1)! You're almost there!"
        ]
        
        let midScoreMessages = [
            "Great effort, \(player1)!",
            "Nice work, \(player1)! You're getting better!",
            "You're on fire, \(player1)! Keep it up!"
        ]
        
        let highScoreMessages = [
            "Good Job, \(player1)! You're crushing it!",
            "Outstanding performance, \(player1)!",
            "Legendary, \(player1)! Is there anything you can't do?"
        ]
        
        let epicScoreMessages = [
            "Unbelievable, \(player1)! This is next level!",
            "Wow, \(player1)! You just broke the game!",
            "Is this even possible, \(player1)? You're a legend!"
        ]
        
        switch points {
        case ..<0:
            centerLabel1.text = lowScoreMessages.randomElement()
            centerLabel2.text = "You're on the right track, but there's room to improve!"
            
        case 0...500_000:
            centerLabel1.text = bonusMessages.randomElement()
            centerLabel2.text = midScoreMessages.randomElement()
            
        case 500_001...1_000_000:
            centerLabel1.text = highScoreMessages.randomElement()
            centerLabel2.text = "There's really nothing left for me to say."
            
        default:
            centerLabel1.text = epicScoreMessages.randomElement()
            centerLabel2.text = "Wow, who would have guessed that could happen?"
        }
    }
    
    // Animation Level Clear sichtbar machen und vergrößern
    private func scaleLevelClearLabels() {
        // Label zur Wiederverwendung zuerst sichtbar machen
        centerLabel1.alpha = 1.0
        centerLabel2.alpha = 1.0
        bonusLabel.alpha = 1.0
        // Animation erstellen hochscalen
        let scaleAction = SKAction.scale(to: 1.0, duration: 1.0)
        
        // "LevelClear"
        configureLabel(centerLabel1, fontColor: .red, fontName: "Menlo", isHidden: false)
        // "Good Job Player1
        configureLabel(centerLabel2, fontColor: .red, fontName: "Menlo", isHidden: false)
        // " Level Clear - BonusPoints: xxxx"
        configureLabel(bonusLabel, fontColor: .white, fontName: "Menlo", isHidden: false)
        
        // Animation starten
        centerLabel1.run(scaleAction)
        centerLabel2.run(scaleAction)
        bonusLabel.run(scaleAction)
    }
    
    private func configureLabel(_ label: SKLabelNode, fontColor: UIColor, fontName: String, isHidden: Bool) {
        label.xScale = 0
        label.yScale = 0
        label.fontColor = fontColor
        label.fontName = fontName
        label.isHidden = isHidden
    }
    
    @objc func showDebugAxisToggled(_ sender: UISwitch) {
        print("Debug Axes: \(sender.isOn ? "is On" : "Don't show")")
        addDebugAxesIsOn = sender.isOn  // Neues Flag
        UserDefaults.standard.set(addDebugAxesIsOn, forKey: "addDebugAxesIsOn")
        
        if sender.isOn {
            addDebugAxes(to: twinShipNode)
            addDebugAxes(to: twinShipStartNode)
            addDebugAxes(to: twinShipBonusNode)
        }
    }
    
    @objc func musicToggled(_ sender: UISwitch) {
        print("Music: \(sender.isOn ? "is on" : "is off")")
        isMusicOn = sender.isOn  // Speichert den Zustand
        UserDefaults.standard.set(isMusicOn, forKey: "isMusicOn")
        
        if sender.isOn {
            SoundManager.shared.playBackgroundMusic()
        } else {
            SoundManager.shared.stopBackgroundMusic()
        }
    }
    
    @objc func startAnimationToggled(_ sender: UISwitch) {
        print("Startanimation: \(sender.isOn ? "Ist eingeschaltet" : "Ist ausgeschaltet")")
        startAnimation = sender.isOn ? true : false
        UserDefaults.standard.set(startAnimation, forKey: "startAnimation")
    }
    
    @objc func SoundToggled(_ sender: UISwitch) {
        print("Sound: \(sender.isOn ? "is on" : "is OFF")")
        SoundManager.shared.isSoundOn = sender.isOn
        UserDefaults.standard.set(SoundManager.shared.isSoundOn, forKey: "isSoundOn")
    }
    
    //MARK: LABEL
    func setupLabel() {
        let BorderFromUp: CGFloat = 70
        let BorderFromBottom: CGFloat = 30
        
        // Erstelle eine SKScene für das HUD
        hudScene = SKScene(size: CGSize(width: scnView.bounds.size.width, height: scnView.bounds.size.height))
        
        // Obere Reihe
        //---------- SCORE
        createLabel(inScene: hudScene,
                    label: &scoreLabel,
                    position: CGPoint(x: 100, y: hudScene.size.height - BorderFromUp),
                    labelText: "Score:",
                    fontColor: UIColor.blue,
                    alpha: CGFloat(0.8)
        )
        //-------------------------------
        
        createLabel(inScene: hudScene,
                    label: &scoreLabelValue,
                    position: CGPoint(x: 200, y: hudScene.size.height - BorderFromUp),
                    fontName:  "Menlo",
                    labelText: "\(Int(floor(score)))"
                    //fontStyle: .traitBold, // Hier wird der Font fett gemacht
        )
        //---------- TimeCounter
        createLabel(inScene: hudScene,
                    label: &timeCounterLabel,
                    position: CGPoint(x: hudScene.size.width/2 - 90 , y: hudScene.size.height - BorderFromUp),
                    labelText: "Time:",
                    fontColor: UIColor.blue,
                    alpha: CGFloat(0.8)
        )
        //-------------------------------
        
        createLabel(inScene: hudScene,
                    label: &timeCounterLabelValue,
                    position: CGPoint(x: hudScene.size.width/2 , y: hudScene.size.height - BorderFromUp),
                    fontName:  "Menlo",
                    labelText: "\(secondsCounter)"
        )
        //---------- Asteroid
        // Untere Reihe
        createLabel(inScene: hudScene,
                    label: &numberCounterAsteroidsLabel,
                    //            position: CGPoint(x: hudScene.size.width - 250 , y: hudScene.size.height - 50),
                    position: CGPoint(x: hudScene.size.width/2 - 80 , y: BorderFromBottom),
                    labelText: "Asteroid:",
                    fontColor: UIColor.blue,
                    alpha: CGFloat(0.8)
        )
        //-------------------------------
        
        createLabel(inScene: hudScene,
                    label: &numberCounterAsteroidsLabelValue,
                    //           position: CGPoint(x: hudScene.size.width - 100 , y: hudScene.size.height - 50),
                    position: CGPoint(x: hudScene.size.width/2 + 70 , y: BorderFromBottom),
                    fontName: "Menlo",
                    labelText: "\(asteroidCountMax)"
        )
        //-------------------------------
        
        createLabel(inScene: hudScene,
                    label: &labelGameLevel,
                    position: CGPoint(x: 100, y: BorderFromBottom),
                    labelText: "Level:",
                    fontColor: UIColor.blue,
                    alpha: CGFloat(0.8)
        )
        //-------------------------------
        
        createLabel(inScene: hudScene,
                    label: &labelGameLevelValue,
                    position: CGPoint(x: 200, y: BorderFromBottom),
                    fontName: "Menlo",
                    labelText: "\(LevelManager.shared.levelCount)")
        //-------------------------------
        createLabel(inScene: hudScene,
                    label: &labelRemainingLives,
                    position: CGPoint(x: hudScene.size.width - 250 , y: BorderFromBottom),
                    labelText: "Lives:",
                    fontColor: UIColor.blue,
                    alpha: CGFloat(0.8)
        )
        //-------------------------------
        createLabel(inScene: hudScene,
                    label: &labelRemainingLivesValue,
                    position: CGPoint(x: hudScene.size.width - 160 , y: BorderFromBottom),
                    fontName: "Menlo",
                    //labelText: getLivesText(lives: playerLives))
                    labelText: "\(playerLives)")
        //-------------------------------
        // Spezial Labels. Sind ausgeblendet für ihren Einsatz
        createLabel(inScene: hudScene,
                    label: &centerLabel1,
                    position: CGPoint(x: scnView.bounds.size.width / 2 , y: hudScene.size.height / 2),
                    labelText: "Level Clear",
                    alignment: SKLabelHorizontalAlignmentMode.center,
                    isHidden: true,
                    alpha: CGFloat(1.0)
        )
        //-------------------------------
        
        createLabel(inScene: hudScene,
                    label: &centerLabel2,
                    position: CGPoint(x: scnView.bounds.size.width / 2,
                                      y: hudScene.size.height / 2 - 50),
                    labelText: "Good Job: \(player1)",
                    alignment: SKLabelHorizontalAlignmentMode.center,
                    isHidden: true,
                    alpha: CGFloat(1.0)
        )
        //-------------------------------
        createLabel(inScene: hudScene,
                    label: &bonusLabel,
                    position: CGPoint(x: DeviceConfig.screenWidth / 2,
                                      y: DeviceConfig.screenHeight / 2 + 50),
                    labelText: "Level Clear - Bonuspoints: \(pointsUpdateCount)",
                    alignment: SKLabelHorizontalAlignmentMode.center,
                    isHidden: true,
                    alpha: CGFloat(1.0)
        )
        // Standartposition setzten
        //        bonusLabel.position = CGPoint(
        //            x: calculateLabelXPosition(for: bonusLabel.text ?? "",
        //                                       fontSize: bonusLabel.fontSize,
        //                                       offset: -50),
        //            y: DeviceConfig.screenHeight / 2 + 50
        //        )
        //-------------------------------
        createLabel(inScene: hudScene,
                    label: &startLevelXLabel,
                    position: CGPoint(x: scnView.bounds.size.width / 2,
                                      y: hudScene.size.height / 2 - 25),
                    fontName: "PressStart2P-Regular",
                    labelText: "Start Level: \(LevelManager.shared.levelCount)",
                    fontSize: CGFloat(25),
                    alignment: SKLabelHorizontalAlignmentMode.center,
                    isHidden: true
        )
        // Muster für Modifizierungen über die Closure
        //                                      { label in
        //                                        label.fontSize = 40
        //                                        label.zPosition = 10
        //                                      }
        
        createLabel(inScene: hudScene,
                    label: &readyLabel,
                    position: CGPoint(x: scnView.bounds.size.width / 2, y: hudScene.size.height / 2 + 25),
                    fontName: "PressStart2P-Regular",
                    labelText: "Ready",
                    fontSize: CGFloat(25),
                    alignment: SKLabelHorizontalAlignmentMode.center,
                    isHidden: true)
        
        // Füge die HUD-Szene als Overlay hinzu
        scnView.overlaySKScene = hudScene
        scnView.overlaySKScene?.scaleMode = .resizeFill
    }
    
    func setupLabelContainer() {
        // Container-Node erstellen
        labelContainerInfo = [scoreLabel,
                              scoreLabelValue,
                              timeCounterLabel,
                              timeCounterLabelValue,
                              numberCounterAsteroidsLabel,
                              numberCounterAsteroidsLabelValue,
                              labelGameLevel,
                              labelGameLevelValue,
                              labelRemainingLives,
                              labelRemainingLivesValue
        ]
    }
    
    func createLabel(inScene scene: SKScene,
                     label: inout SKLabelNode?,
                     position: CGPoint,
                     fontName: String = "Helvetica",
                     labelText: String = "Default",
                     fontSize: CGFloat = 30,
                     fontStyle: UIFontDescriptor.SymbolicTraits? = nil, // Symbolische Font-Stile
                     alignment: SKLabelHorizontalAlignmentMode = .left,
                     fontColor: UIColor = .white,
                     isHidden: Bool = true,
                     alpha: CGFloat = 0.5,
                     modifiers: ((SKLabelNode) -> Void)? = nil // Optionaler Closure
    ){
        
        label = SKLabelNode(text: labelText)
        
        guard let unwrappedLabel = label else {
            return // Sollte nie passieren, aber Vorsicht ist besser
        }
        
        // Erstelle und konfiguriere das Label
        unwrappedLabel.position = position
        unwrappedLabel.fontName = fontName
        unwrappedLabel.fontSize = fontSize
        unwrappedLabel.horizontalAlignmentMode = alignment
        unwrappedLabel.fontColor = fontColor
        unwrappedLabel.isHidden = isHidden
        unwrappedLabel.alpha = alpha
        
        // Font-Stil anwenden (z. B. bold oder italic)
        if let fontStyle = fontStyle {
            let descriptor = UIFontDescriptor(name: fontName,
                                              size: fontSize).withSymbolicTraits(fontStyle)
            unwrappedLabel.fontName = UIFont(descriptor: descriptor!,
                                             size: fontSize).fontName
        } else {
            // Modifizierer anwenden, falls angegeben
            modifiers?(unwrappedLabel)
        }
        
        // Füge das Label zur übergebenen Szene hinzu
        hudScene.addChild(unwrappedLabel)
        hudScene.isUserInteractionEnabled = false
        //return label
    }
    
    //MARK: BonusRound Button
    func setupBonusRoundButton() {
        bonusRoundButton = UIButton(type: .system)
        bonusRoundButton.frame = CGRect(x: scnView.bounds.size.width / 2 - 110, y: scnView.bounds.size.height / 2, width: 220, height: 50)
        bonusRoundButton.setTitle(" Bonus Round ", for: .normal)
        bonusRoundButton.addTarget(self, action: #selector(bonusRoundButtonTapped), for: .touchUpInside)
        
        // Rahmen hinzufügen
        bonusRoundButton.layer.borderColor = UIColor.white.cgColor
        bonusRoundButton.layer.borderWidth = 2.0
        
        // Schriftgröße und -farbe anpassen
        bonusRoundButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        bonusRoundButton.setTitleColor(UIColor.white, for: .normal)
        
        // Ecken abrunden
        bonusRoundButton.layer.cornerRadius = 10.0
        bonusRoundButton.clipsToBounds = true
        
        // Schattierung hinzufügen
        bonusRoundButton.layer.shadowColor = UIColor.black.cgColor
        bonusRoundButton.layer.shadowOpacity = 0.5
        bonusRoundButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        bonusRoundButton.layer.shadowRadius = 5
        
        bonusRoundButton.setTitleColor(UIColor.gray, for: .highlighted)
        bonusRoundButton.isEnabled = false
        bonusRoundButton.isHidden = true
        
        view.addSubview(bonusRoundButton)
    }
    
    // MARK: Collision Display
    func setupCollisionDisplay() {
        
        displayScene = SCNScene()
        displayScene.physicsWorld.contactDelegate = self
        
        // Über struct DeviceConfig deklariert
        displayView = SCNView(frame: DeviceConfig.layout.displayViewFrame)
        //displayView.debugOptions = [.showCameras, .showPhysicsShapes] // Physik-Darstellung aktivieren
        displayView.allowsCameraControl = false // Kamera zur Ansichtsteuerung
        displayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        displayView.isHidden = true
        displayView.scene = displayScene
        
        // Abgerundete Ecken hinzufügen
        displayView.layer.cornerRadius = 20 // Hier die gewünschte Rundung (in Punkten)
        displayView.layer.masksToBounds = true // Aktiviert das Abschneiden des Inhalts an den Rändern
        
        // Rahmen
        displayView.layer.borderWidth = 0.5
        displayView.layer.borderColor = UIColor.green.cgColor
        
        self.view.addSubview(displayView)
        
        //Kamera erstellen und konfigurieren
        cameraDisplayNode = SCNNode()
        cameraDisplayNode.camera = SCNCamera()
        cameraDisplay = cameraDisplayNode.camera!
        cameraDisplayNode.camera?.zNear = 0.1  // Nahe Clipping-Ebene (muss > 0 sein)
        cameraDisplayNode.camera?.zFar = 800
        cameraDisplayNode.position = SCNVector3(x: -180, y: 0, z: 0)     //World
        
        displayScene.rootNode.addChildNode(cameraDisplayNode)
        
        // CameraDisplay ausrichten
        setCameraDisplayDirection()
        
        // Die Wireframe Ansicht für CollisionDisplay setzen
        displayView.debugOptions.insert(.showCameras)
        displayView.debugOptions.insert(.showPhysicsShapes)
        // Ein kleines rotes Fadenkreuz setzten
        addCollisionDisplayCross()
    }
    
    // Rotes Kreuz innerhalb CollisionDisplay
    func addCollisionDisplayCross() {
        let crossNode = SCNNode()
        
        // Horizontale Linie
        let horizontalBox = SCNBox(width: 10, height: 0.5, length: 1, chamferRadius: 0)
        horizontalBox.firstMaterial?.diffuse.contents = UIColor.red
        let horizontalNode = SCNNode(geometry: horizontalBox)
        
        // Vertikale Linie
        let verticalBox = SCNBox(width: 0.5, height: 10, length: 1, chamferRadius: 0)
        verticalBox.firstMaterial?.diffuse.contents = UIColor.red
        let verticalNode = SCNNode(geometry: verticalBox)
        
        // Beides zur Mitte setzen
        crossNode.addChildNode(horizontalNode)
        crossNode.addChildNode(verticalNode)
        
        // Damit es immer in der mitte des Displays ist
        cameraDisplayNode.addChildNode(crossNode)
        crossNode.position = SCNVector3(0, 0, -50)
    }

    // MARK: Animiertes ein- und ausblenden des Collision Displays
    func showCollisionDisplay() {
        DispatchQueue.main.async { [self] in
            displayView.transform = CGAffineTransform(scaleX: 0, y: 0) // Start: Null Höhe
            displayView.isHidden = false
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) { [self] in
                displayView.transform = CGAffineTransform.identity // Rückkehr zur normalen Größe
            }
        }
    }
    
    func hideCollisionDisplay() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) { [self] in
                displayView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            } completion: { [self] _ in
                displayView.isHidden = true  // Erst am Ende wirklich unsichtbar machen
            }
        }
    }
    
    // Wegen der unterschiedlichen Ausrichtung der Level und Bonus Round Camera
    func setCameraDisplayDirection() {
        // Blickrichtung für die Timer-Sync
        if bonusState == .active {
            cameraDisplayNode.simdOrientation = simd_quatf(angle: .pi / 2 , axis: SIMD3(0, -1, 0))
        } else {
            cameraDisplayNode.simdOrientation = simd_quatf(angle: .pi / 2, axis: SIMD3(0, -1, 0))
            cameraDisplayNode.simdOrientation *= simd_quatf(angle: .pi / 2, axis: SIMD3(0, 0, -1))
        }
        
        // Speichere Ausgangsausrichtung auch für die Timer-Sync
        cameraBaseOrientation = cameraDisplayNode.simdOrientation
    }
    
    func changeBackgroundImage(
        for imageView: UIImageView,
        baseName: String,
        applyToScene scene: SCNScene? = nil
    ) {
        let suffix = DeviceConfig.isIPad ? "Pad" : "Phone"
        let fullImageName = baseName + suffix
        
        if let image = UIImage(named: fullImageName) {
            imageView.image = image
            scene?.background.contents = image
        } else {
            print("❌ Bild nicht gefunden: \(fullImageName)")
        }
    }
    
    // Label ausblenden
    func welcomeLabelFadeOut() {
        UIView.animate(withDuration: 1.5, delay: 0, options: [.curveEaseInOut]) {
            self.welcomeLabel.alpha = 0
        } completion: { _ in
            self.welcomeLabel.removeFromSuperview()
        }
    }
    
    // View zentrieren mit definierter Größe
    func positionLabelTopCentered(_ label: UILabel, in container: UIView, size: CGSize, topOffset: CGFloat) {
        label.frame = CGRect(origin: .zero, size: size)
        label.center.x = container.center.x
        label.frame.origin.y = topOffset
    }
    
    //MARK: class DebugHUD - Ab hier nur zum Debuggen
    class DebugHUD: UIView {
        
        private let stack = UIStackView()
        private var labelMap: [String: UILabel] = [:]
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setup()
        }
        
        private func setup() {
            backgroundColor = UIColor.black.withAlphaComponent(0.6)
            layer.cornerRadius = 12
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.cgColor
            
            stack.axis = .vertical
            stack.spacing = 4
            stack.alignment = .leading
            stack.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(stack)
            
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
            ])
        }
        
        /// Setzt oder aktualisiert eine Zeile im HUD.
        func setValue(_ value: String, for label: String) {
            if let existingLabel = labelMap[label] {
                existingLabel.text = "\(label): \(value)"
            } else {
                let newLabel = UILabel()
                newLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
                newLabel.textColor = .cyan
                newLabel.text = "\(label): \(value)"
                labelMap[label] = newLabel
                stack.addArrangedSubview(newLabel)
            }
        }
    }
    
    // Für DebugHUD zum Anzeigen der aktuellen FPS
    func calculateCurrentFPS(_ time: TimeInterval) -> Int {
        let delta = time - lastUpdateTime
        lastUpdateTime = time
        if delta > 0 {
            return Int(1.0 / delta)
        } else {
            return 0
        }
    }
    
    //MARK: - Tasten starten Enemys
    // Keyboard Taste gedrückt
    //     override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    //         if presses.first?.key?.charactersIgnoringModifiers == "d" {
    //             toggleDebugHUD() // Sanftes ein und ausblenden
    //         }
    //     }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }
        
        switch key.charactersIgnoringModifiers {
            
        case "d":
            toggleDebugHUD()
            
        case "b":   // BallWall
            currentEnemy = .ballWall
            startBallWall()
            
        case "i":   // SpaceInvader
            currentEnemy = .spaceInvader
            spawnNextEnemy()
            
        case "p":   // SpaceProbe
            currentEnemy = .spaceProbe
            spawnNextEnemy()
            
        case "f":   // BigFlash
            currentEnemy = .bigFlash
            spawnNextEnemy()
        default:
            break
        }
    }
    
    
    // Sanftes ein und ausblenden des debugHUDs
    func toggleDebugHUD() {
        let targetAlpha: CGFloat = debugHUD.alpha == 0 ? 1 : 0
        
        UIView.animate(withDuration: 0.3) {
            self.debugHUD.alpha = targetAlpha
        }
    }
    
    // Farbige Hilfspfeile für die Achsen des TwinShips
    func addDebugAxes(to node: SCNNode) {
        
        let xAxis = SCNNode(geometry: SCNCylinder(radius: 1.0, height: 75)) // Stab
        let arrowXAxis = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 3, height: 10))  // Pfeilspitze
        // Materialien setzten
        xAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        arrowXAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        // Position und Orientierung anpassen
        xAxis.eulerAngles.z = -.pi / 2
        arrowXAxis.eulerAngles.y = -.pi / 2
        arrowXAxis.position = SCNVector3(x: 0, y: 40, z: 0)
        // Beide Nodes zur Szene hinzufügen - Der Arrow ist ein Child des Stabes (xAxis)
        xAxis.addChildNode(arrowXAxis)
        node.addChildNode(xAxis)
        
        let yAxis = SCNNode(geometry: SCNCylinder(radius: 1.0, height: 75))
        let arrowYAxis = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 3, height: 10))
        yAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        arrowYAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        arrowYAxis.position = SCNVector3(x: 0, y: 40, z: 0)
        yAxis.addChildNode(arrowYAxis)
        node.addChildNode(yAxis)
        
        let zAxis = SCNNode(geometry: SCNCylinder(radius: 1.0, height: 75))
        let arrowZAxis = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 3, height: 10))
        zAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        zAxis.eulerAngles.x = .pi / 2
        zAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        arrowZAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        arrowZAxis.eulerAngles.y = -.pi / 2
        arrowZAxis.position = SCNVector3(x: 0, y: 40, z: 0)
        zAxis.addChildNode(arrowZAxis)
        node.addChildNode(zAxis)
    }
    
    // Log-Ausgabe mit Zeit
    func logEvent(_ message: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(time)] \(message)")
        //print (String(format: "%.0f", spawnDelay),  "spawnDelay")
//        print (String(format: "%.0f", bigFlashOnScreenDuration),  "bigFlashOnScreenDuration")
//        print ("\(currentEnemy)",  "currentEnemy")
//        print ("\(spaceInvaderState)",  "spaceInvaderState")
//        print ("\(spaceProbeState)",  "spaceProbeState")
//        print ("\(bigFlashState)",  "bigFlashState")
//        print ("\(ballWallState)",  "ballWallState")
        counter += 1
        print ("counter: \(counter)")
        print("")
    }
    
    
    // LogAusgabe für die Aufrufende Funktion
//    func logCaller(message: String = "", file: String = #file, line: Int = #line, function: String = #function) {
//        print("[\(function)] \(message) - in \(file):\(line)")
//    }
}
