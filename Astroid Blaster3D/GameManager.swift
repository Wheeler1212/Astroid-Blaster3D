//
//  extension GameViewController.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 03.12.24.
//


//Ideen:
// FIXME: ToDo Liste:

// *** IDEEN
// Easter Egg "ChattyRocks"
// Farben des Particle-Stromes abändern
// Stars bei Start-Animation dem Screen entgegenfliegen lassen
// SpaceProbe holt die noch nicht vom TwinShip eingefangenen Stars wieder ab
// DebugShapes (Cubes) für Asteroiden die auf Kollisionskurs sind erstellen
// TwinShip kann nur von markierten Asteroiden zerstört (kollidieren) werden
// Wenn BigFlash die Bühne betritt die fireNodes spiralförmig und dann auch noch seitwärts ablenken
// Bei der Steuerung um die Z-Achse dreht sich nicht das TwinShip sondern die Asteroiden Welt

// *** Fehler bereinigen
// colorfullStars fadeIn funktioniert nicht
// PhysicBody CollisionMask umschreiben
// BigFlash mit Asteroid Kollision entpressen
// Bei LevelClear bleiben die Colorfull Stars ohne Rotation stehen
// Bei LevelClear bleibt der Invader an seiner Position stehen Animationen laufen weiter
// Die BallWall unterbricht den InvaderCircle
// Die SCNAction auf SpaceProbe addieren sich - removeAction schein nicht zu funktionieren
// Points Update Formel ???
// ColorfullStars nicht nur ausblenden sondern vom Parent nehmen (PhysicsBody) Warum????
// animateBigFlash reagiert nicht auf PhysicsWorld

import SceneKit
import SpriteKit
import AudioToolbox

extension GameViewController {

    
    class FunctionWatchdog {
        private var lastExecution: Date = .distantPast
        private var timer: Timer?
        private let interval: TimeInterval
        private let timeout: TimeInterval
        private let action: () -> Void

        init(checkInterval: TimeInterval = 10.0, timeout: TimeInterval = 120.0, action: @escaping () -> Void) {
            self.interval = checkInterval
            self.timeout = timeout
            self.action = action

            // Starte den Timer
            start()
        }

        func functionWasCalled() {
            lastExecution = Date()
        }

        private func start() {
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.check()
            }
        }

        private func check() {
            let now = Date()
            let elapsed = now.timeIntervalSince(lastExecution)
            if elapsed > timeout {
                print("Watchdog: Funktion wurde länger als \(timeout) Sekunden nicht aufgerufen. Führe sie jetzt aus.")
                lastExecution = now
                action()
            }
        }

        deinit {
            timer?.invalidate()
        }
    }

    // Diverse Werte die beim erreichen des NextLevel erhöht werden werden
    func nextLevelUpdate() {
        
        LevelManager.shared.nextLevel()

        levelCount += 1  // Level erhöhen
        switch levelCount {
            case 1:
                print("Game-Level 1")

            case 2:
                print("Game-Level 2")

            case 3:
                print("Game-Level 3")
                
            default:
                print("Game-Level default")
            }
    }
    
  // TODO: Geht noch nicht - Rotation TwinShip für den StartScreen
    func showAndRotateTwinShip() {
        twinShipNode.isHidden = false
        twinShipNode.position = SCNVector3(0, 0, -10)
        
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.fromValue = SCNVector4(1, 0, 0, 0) // X-Achse, Winkel = 0
        rotation.toValue = SCNVector4(1, 0, 0, CGFloat.pi * 2) // 360°
        rotation.duration = 5.0
        rotation.repeatCount = .infinity
        twinShipNode.addAnimation(rotation, forKey: "rotateX")
    }

    
// Alle Kollisionen von Fire mit was auch immer
    func fireHitEnemy(enemyName: String, enemyNode: SCNNode, fireNode: SCNNode) {
        var fireHitEnemy = false

        switch true {
        case enemyName.hasPrefix("SpaceInvader"):
            increaseSpinSpeedOnHit(nameOfNode: enemyName, fireNode: fireNode)
            fireHitEnemy = true
            
        case enemyName.hasPrefix("SpaceProbe"):
            guard ![.fadeIn, .fadeOut].contains(spaceProbeState) else { return }
                if starsCounter > 0 {
                    performStarRelease()
                } else {
                    probeSurprisedByHit()
                }
                fireHitEnemy = true
            
        case enemyName.hasPrefix("Asteroid"):
            fireHitAsteroid(enemyNameOfNode: enemyName, fireNode: fireNode)
            fireHitEnemy = true
            score += 200 / fireNode.scale.x  // Score erhöhen. Je kleiner der Asteroid desto mehr Punkte
            updateHUD()
            
        case enemyName.hasPrefix("BigFlash"):
            // FIXME: Was geschieht, wenn Fire den BigFlash trifft?
            fireHitEnemy = true
            
        case enemyName == "BallWallDoor":
            // Explosion und Position zurücksetzen
            createExplosion(for: enemyNode, newSize: 10)
            // BallWallDoor nach Explosion in die Parkposition
            enemyNode.removeAllActions()
            enemyNode.position = SCNVector3(-DeviceConfig.layout.ballWallMoveBorderX, 0, 0)
            fireHitEnemy = true
            score += 20_000
            updateHUD()
            
        case enemyName == "BallWall":
            // Explosion erstellen
            createExplosion(for: enemyNode, newSize: 10)
            fireHitEnemy = true
            
        default:
            break
        }
        
        // *** Abschließend Fire löschen
        if fireHitEnemy {
            fireNode.removeFromParentNode()
            fireHitEnemy = false
        }
    }   
    

    //--------------------------------------------------------------------------------------




    // FIXME: BigFlash HitByAsteroid
    // Für Kollision BigFlash und Asteroids
    func popUpAndDown(node: SCNNode, scaleUp: CGFloat, scaleDown: CGFloat) {
        
        //        let scaleUpAction = SCNAction.scale(to: scaleUp, duration: TimeInterval(0.3))
        //        let scaleDownAction = SCNAction.scale(to: scaleDown, duration: TimeInterval(0.5))
        //        let fadeAction = SCNAction.fadeOpacity(to: 0.0, duration: TimeInterval(0.3))
        //        let fadeActionDown = SCNAction.fadeIn(duration: TimeInterval(0.5))
        //        let rotateAction = SCNAction.rotate(by: .pi, around: SCNVector3(1, 1, 1), duration: TimeInterval(0.3))
        //        let goupActionUp = SCNAction.group([scaleUpAction, fadeAction,rotateAction])
        //        let groupActionDown = SCNAction.group([scaleDownAction, fadeActionDown, rotateAction])
        //
        //        let sequence = SCNAction.sequence([goupActionUp, groupActionDown])
        
        
        //        node.runAction(sequence) {
        //node.removeAllActions()
        //            node.removeFromParentNode()
        //            self.asteroidAktiv -= 1
        //            node.position.x = -250
        ////
        //        node.physicsBody = nil

        let impulsY = Float.random(in: -10...10)
        node.removeAllAnimations()
        node.physicsBody?.velocity = SCNVector3Zero
        node.physicsBody?.velocityFactor = SCNVector3Zero
            // Asteroid wird hier auf der agenblicklichen Position festgehalten und nur rotiert
        node.physicsBody?.applyForce(SCNVector3(x: 50, y: impulsY, z: 0), asImpulse: true)
        
    }
    //--------------------------------------------------------------------------------------

    
// MARK: Blink Shield
    // Vom Renderer bei "twinShipShieldBlink = true" gestartet
    func blinkShield() {
        
        if increasing {
            blinkShieldValue += 0.2
            if blinkShieldValue >= 2 {
                increasing = false // Richtung ändern
            }
        } else {
            blinkShieldValue -= 0.2
            if blinkShieldValue <= -0 {
                increasing = true // Richtung ändern
            }
        }
        // Position in Relation zum Raumschiff
        shieldNode.position = SCNVector3(0, 0, blinkShieldValue)
       }
    //--------------------------------------------------------------------------------------
    
// MARK: Clean Scene
    // Alle AsteroidsNodes die den Bildschirm verlassen auf Parkposition setzten
    func cleanAsteroids() {
        // Wenn "Asteroid" oder "Fire" den Bildschirm verlässt
        for node in gameScene.rootNode.childNodes {
            // Prüfung ob Node ein Asteroid ist und welche Nummer er hat
            if let nodeName = node.name, nodeName.hasPrefix("Asteroid"),
               let specificAsteroid = asteroidNodeDictionary[nodeName] {
                let numberAsteroid = Int(nodeName.suffix(4))!
                
                // Nur die großen Asteroiden wieder rechts einlaufen lassen
                if numberAsteroid < offsetNumber {
                    // Asteroids verlassen links den Bildschirm
                    if node.presentation.position.x < -asteroidParkPositionX - 1 {
                    // Asteroid rechts neu einlaufen lassen, ...
                        repositionAsteroid(asteroid: specificAsteroid,
                                           at: asteroidStartPositionX,
                                           withinYRange: -asteroidStartBorderY...asteroidStartBorderY,
                                           withinZRange: -asteroidStartBorderZ...asteroidStartBorderZ
                        )
                    }
                    
                    // Dito aber wenn sie oben oder unten den Schirm verlassen
                    if abs(node.presentation.position.y) > DeviceConfig.layout.asteroidMoveBorderY {
                        repositionAsteroid(asteroid: specificAsteroid,
                                           at: asteroidStartPositionX,
                                           withinYRange: -asteroidStartBorderY...asteroidStartBorderY,
                                           withinZRange: -asteroidStartBorderZ...asteroidStartBorderZ
                        )
                    }
                }
            }
        }
    }
    
    private func repositionAsteroid(asteroid: SCNNode,
                                    at positionX: Float,    // Startposition
                                    withinYRange yRange: ClosedRange<Float>,
                                    withinZRange zRange: ClosedRange<Float>
                                    ) {
        var positionZ: Float = Float.random(in: zRange)
        
        // Erst bei .hard werden die Asteroiden auch in Z verschoben
        if LevelManager.shared.difficulty == .hard {
            if !bonusRoundIsActive {
                if alternateZ {
                    positionZ = 0.0
                } else {
                    positionZ = Float.random(in: zRange)
                }
                alternateZ.toggle()
            }
            // Falls bonusRoundIsActive → positionZ bleibt bei dem initialen Zufallswert
        } else {
            positionZ = 0.0
        }


        // Neue Startposition (X-Wert) und Zufallsposition (Y-Wert)
        asteroid.position = SCNVector3(positionX, Float.random(in: yRange), positionZ)
        
        // Damit die Geschwindigkeit nicht zu groß wird
        if let physicsBody = asteroid.physicsBody {
            // Y-Bewegung entfernen
            physicsBody.velocity.y = 0
            // Rotation auf ein zehntel verlangsamen
            physicsBody.angularVelocity.x *= 0.4

            // Falls der Asteroid nach rechts (+X) fliegt, kehre die Richtung um
            if physicsBody.velocity.x > 0 {
                physicsBody.velocity.x = -physicsBody.velocity.x
            }
            let impulseX = Float(levelCount * 10)
            // Maximale Geschwindigkeitsschwelle
            let maxVelocityThreshold = max(Float(-levelCount) * 50 - 100, -300) // Maximal -300 m/s
            
            // Falls die Geschwindigkeit über einem bestimmten Wert liegt, keine neuen Impulse geben
            if physicsBody.velocity.x > maxVelocityThreshold {
                physicsBody.applyForce(SCNVector3(x: Float.random(in: -impulseX ... -10),   // Richtung
                                                  y: 0,
                                                  z: 0),
                                       at: SCNVector3(0.9, 0.5, 0.8),                       // Position
                                       asImpulse: true)
            }
        }
    }
    
    /// Löscht Feuerbälle aus fireNodeRight/fireNodeLeft, die die Bildgrenze (2D) oder Distanz (3D) überschreiten
    func cleanFire() {
        if !bonusRoundIsActive {
            // Levelrunde (2D): Löschen bei Überschreiten der X-Grenze minus 50
            let cleanBorderX = fireMoveBorderX
            var newFireNodeRight = [SCNNode]()
            for fire in fireNodeRight {
                if fire.presentation.position.x > cleanBorderX {
                    fire.removeFromParentNode()
                } else {
                    newFireNodeRight.append(fire)
                }
                fireNodeRight = newFireNodeRight
            }
            
            var newFireNodeLeft = [SCNNode]()
            for fire in fireNodeLeft {
                if fire.presentation.position.x > cleanBorderX {
                    fire.removeFromParentNode()
                } else {
                    newFireNodeLeft.append(fire)
                }
                fireNodeLeft = newFireNodeLeft
            }
        } else {
            // Bonusrunde (3D): Löschen bei Distanz > 2000 vom twinShipBonusNode
            let shipPosition = twinShipBonusNode.simdPosition
            let maxDistance: Float = 2000
            var newFireNodeRight = [SCNNode]()
            for fire in fireNodeRight {
                let firePosition = fire.simdPosition
                let distance = length(firePosition - shipPosition)
                if distance > maxDistance {
                    fire.removeFromParentNode()
                } else {
                    newFireNodeRight.append(fire)
                }
            }
            fireNodeRight = newFireNodeRight
            
            var newFireNodeLeft = [SCNNode]()
            for fire in fireNodeLeft {
                let firePosition = fire.simdPosition
                let distance = length(firePosition - shipPosition)
                if distance > maxDistance {
                    fire.removeFromParentNode()
                } else {
                    newFireNodeLeft.append(fire)
                }
            }
            fireNodeLeft = newFireNodeLeft
        }
    } //-----------------------------------------------------
        
    // FIXME: Größe für die unterschiedlichen Level ???
    /// Über "func startTimerAsteroid()" wiederkehrend gestartet
    @objc func setAsteroidToStart()  {
        guard asteroidCountActive <= asteroidMaxNumberOnScreen else { return }
        asteroidCountActive += 1 // Soviele Asteroiden im Spiel
        
        // Nur die Großen
        for (numberOfAsteroid, node) in asteroidNode.prefix(20).enumerated() {
            // Ist noch ein Asteroid in Parkposition?
            if node.position.x == -asteroidParkPositionX {
                let nameForAsteroid = String(format: "Asteroid%04d", numberOfAsteroid)
                // BonusRound Tiefe - LevelRound rechts ausserhalb Screen
                let positionX = bonusRoundIsActive ? Float.random(in: 50...1000) : 400
                
                let positionY = Float.random(in: -asteroidStartBorderY...asteroidStartBorderY)
                let positionZ = bonusRoundIsActive ? Float.random(in: -asteroidStartBorderZ...asteroidStartBorderZ) : 0
                
                // Startposition
                let asteroidPosition = SCNVector3(x: positionX,
                                                  y: positionY,
                                                  z: positionZ)
                // Position des Impulses für Drehung
                let rotationPosition = SCNVector3(x: Float.random(in: 2...5),
                                                  y: Float.random(in: 2...5),
                                                  z: Float.random(in: 2...5))
                // Asteroid aus Dictionary holen
                if let nodeForSetAsteroid = asteroidNodeDictionary[nameForAsteroid] {
                    nodeForSetAsteroid.position = asteroidPosition
                    // Geschwindigkeit
                    nodeForSetAsteroid.physicsBody?.velocity = SCNVector3(x: Float.random(in: -50 ... -10), y: 0,z: 0)
                    // Kraft
                    nodeForSetAsteroid.physicsBody?.applyForce(SCNVector3(x: Float.random(in: -50 ... -10), y: 0,z: 0), at: rotationPosition,asImpulse: true)
                    nodeForSetAsteroid.physicsBody?.categoryBitMask = combineBitMasks([.asteroid])
                    
                    break // Nur einen Asteroiden wegschicken
                    
                } else { print("Node mit dem Namen \(nameForAsteroid) wurde nicht gefunden.") }
            }
        }
     }
    //--------------------------------------------------------------------------------------
    
    func invalidateTimer() {
        // Und keine Enemies mehr schicken
        timerAsteroid?.invalidate()
        timerAsteroid = nil
        
        // Timer für NeuStart stoppen
        timerWaitForDelaySpaceProbe?.invalidate()
        timerWaitForDelaySpaceProbe = nil
        
        // Timer für Laufzeit stoppen
        timerOnScreenTimeSpaceProbe?.invalidate()
        timerOnScreenTimeSpaceProbe = nil
        
        // Timer für NeuStart stoppen
        timerSpaceInvader?.invalidate()
        timerSpaceInvader = nil
        
        // Timer für Animation stoppen
        timerAnimateSpaceInvader?.invalidate()
        timerAnimateSpaceInvader = nil
        
        // Timer für Laufzeit stoppen
        enemySegmentTimer?.invalidate()
        enemySegmentTimer = nil
               
        timerBallWall?.invalidate()
        timerBallWall = nil
        
        timerBigFlash?.invalidate()
        timerBigFlash = nil
    } //----------------------------------------------------------
  

    // TODO: TwinShip wird innerhalb des Bildschirms gehalten
    func viewBounding() {
        // Segelflug mit Gegenwind - Schwammig zum Steuern eventuell mit Bescheunigung
        cameraNode.simdPosition += lastCameraMovement

        // Bildschirmgrenzen definieren (angepasst an X als Tiefe, Z als Links/Rechts)
        let screenBounds = SCNVector3(
            x: 200,  // Nicht verwendet, aber für Klarheit beibehalten
            y: 80,   // Maximale Y-Abweichung (Hoch/Runter)
            z: 80    // Maximale Z-Abweichung (Links/Rechts)
        )

        // Relative Position des Schiffes zur Kamera
        let shipPosition = twinShipBonusNode.simdPosition
        let cameraPosition = cameraNode.simdPosition
        let relativePosition = shipPosition - cameraPosition

        // Kamerabewegung anpassen, wenn das Schiff die Grenzen erreicht
        var cameraAdjustment = SIMD3<Float>(0, 0, 0)

        // Y-Richtung (Hoch/Runter)
        if relativePosition.y > screenBounds.y {
            cameraAdjustment.y = relativePosition.y - screenBounds.y
        } else if relativePosition.y < -screenBounds.y {
            cameraAdjustment.y = relativePosition.y + screenBounds.y
        }

        // Z-Richtung (Links/Rechts)
        if relativePosition.z > screenBounds.z {
            cameraAdjustment.z = relativePosition.z - screenBounds.z
        } else if relativePosition.z < -screenBounds.z {
            cameraAdjustment.z = relativePosition.z + screenBounds.z
        }

        // Wende die Anpassung auf die Kamera an (mit Dämpfung kombinieren)
        cameraNode.simdPosition += cameraAdjustment * 0.1  // Gedämpfte Kamerabewegung
    }
    
    //--------------------------------------------------------------------------------------
    
    func calculateLabelXPosition(for labelText: String, fontSize: CGFloat, offset: CGFloat = 0) -> CGFloat {
        let tempLabel = SKLabelNode(text: labelText)
        tempLabel.fontSize = fontSize
        tempLabel.horizontalAlignmentMode = .left

        let textWidth = tempLabel.frame.width  // 🔍 Ermittelt die Breite des Textes
        let positionX = (DeviceConfig.screenWidth - textWidth) / 2 + offset

        return positionX
    }
    //--------------------------------------------------------------------------------------

    // Zufällige Bewegung von übergebenen Node
    func moveObjectRandomly(_ node: SCNNode,
                            _ xRange: ClosedRange<Float>,
                            _ yRange: ClosedRange<Float>,
                            _ zPosition: Float,
                            _ durationRange: ClosedRange<TimeInterval>) {
        
        // Erstelle eine zufällige Position innerhalb des definierten Bereichs
        let randomX = Float.random(in: xRange)
        let randomY = Float.random(in: yRange)
        
        // Zielposition
        let targetPosition = SCNVector3(x: randomX, y: randomY, z: zPosition)   // War z: 50
        
        // Erstelle eine Bewegung zur neuen Position
        let moveAction = SCNAction.move(to: targetPosition, duration: TimeInterval.random(in: durationRange))
        moveAction.timingMode = .easeInEaseOut
        
        // Rückrufaktion, um die Bewegung endlos zu wiederholen
        let moveAgainAction = SCNAction.run { _ in
            self.moveObjectRandomly(node, xRange, yRange, zPosition, durationRange)
        }
        
        // Sequenz von Aktionen: Bewegen und dann erneut aufrufen
        let sequence = SCNAction.sequence([moveAction, moveAgainAction])
        
        // Starte die Sequenz auf der Node
        node.runAction(sequence)
    }
    //--------------------------------------------------------------------------------------

    
    func rotateObjectRandomly(_ node: SCNNode, withFadeIn: Bool = false, fadeInDuration: TimeInterval = 1.0) {
        // Zufällige Rotationswerte – nur um Y-Achse
        let randomY = Float.random(in: -Float.pi...Float.pi)

        // Rotationsaktion
        let rotateAction = SCNAction.rotateBy(
            x: 0,
            y: CGFloat(randomY),
            z: 0,
            duration: TimeInterval.random(in: 1.0...3.0)
        )

        // Wiederhol-Callback
        let rotateAgainAction = SCNAction.run { [weak node] _ in
            guard let node = node else { return }
            self.rotateObjectRandomly(node) // Rekursion ohne fadeIn beim nächsten Durchlauf
        }

        // Rotationssequenz
        let sequence = SCNAction.sequence([rotateAction, rotateAgainAction])

        // Optional: fadeIn einbauen
        if withFadeIn {
            node.opacity = 0
            let fadeIn = SCNAction.fadeIn(duration: fadeInDuration)
            let group = SCNAction.group([fadeIn, sequence])
            node.runAction(group, forKey: "rotate")
        } else {
            node.runAction(sequence, forKey: "rotate")
        }
    }

    //FIXME: Ist aktuell deaktiviert
    func getLivesText(lives: Int) -> String {
        let lifeWord = lives == 1 ? "life" : "lives"
        return "Lives: \(lives) \(lifeWord)"
    }
    
    // Sterne bewegen
    func moveBackgroundStars() {
        guard startBackgroundStars else { return }
        
        var starSpeedFactor: Float
        
        // Sterne beschleunigen
        if accelerateStars {
            increaseSpeedFactor = min(increaseSpeedFactor + 0.005, 1)
            accelerateStars = increaseSpeedFactor < 1 //0.01
        }
        
        // Sterne abbremsen
        if slowDownStars {
            increaseSpeedFactor = max(increaseSpeedFactor - 0.005, 0)
            slowDownStars = increaseSpeedFactor > 0
        }
        
        // Kombinierte Indizes: Immer die ersten 50 + Bonus-Teil bei Bedarf
        let indices = bonusRoundIsEnabled
            ? (0..<pointNode.count)           //  Alle Sterne bewegen
            : (0..<50)                        //  Nur die ersten 50 Sterne

        for index in indices {
            let point = pointNode[index]
            starSpeedFactor = increaseSpeedFactor * starSpeed[index]
            point.position.x -= starSpeedFactor
            if point.position.x < -300 {
                point.position.x = 300
            }
        }
    }
    
     func poolNodesMoveToParkPosition() {
         
         // Erzeugte Asteroiden in Parkposition (-400) setzen (wegen Ruckler)
         for i in 0 ..< 120 {
             asteroidNode[i].position.x = -asteroidParkPositionX
         }
         // Erzeugte Stars in Parkposition setzen (-400,-50,0)
         starRedNode.position = parkPositionOfColorfullStars
         starGreenNode.position = parkPositionOfColorfullStars
         starYellowNode.position = parkPositionOfColorfullStars
         
         spaceProbeParentNode.position = parkPositionOfSpaceProbe
         shieldNode.position = parkPositionOfShield
         
         // Hintergrundaktualisierung kann starten
         isReadyToRender = true
     }
     
     func moveShipShieldToParkposition() {
         
         shieldNode.position = parkPositionOfShield
         shieldNode.isHidden = false
         shieldNode.opacity = 1.0
     }
}
