//
//  InputManager.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 22.04.25.
//

import SceneKit


extension GameViewController {
    
// MARK: Touch Steuerung
    // --------- Wenn du den Finger auf das Display legst -----------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGamePaused else { return }
        
        if let touch = touches.first {
            lastTouchPosition = touch.location(in: self.view)
            
            if bonusState == .enabled {    
                // Feuereingabe nur am linken Rand
                if lastTouchPosition!.x < DeviceConfig.layout.fireBorderLeft {
                    // Animation der Feuersteuerung
                    animateFire()
                    SoundManager.shared.playFireShot()                }
                // Für touchesEnd um Schiff zurückzudrehen
                touchActive = true
            } else {
                // Feuereingabe nur am linken Rand
                if lastTouchPosition!.x < DeviceConfig.layout.fireBorderLeft {
                    // Animation der Feuersteuerung
                    animateFire()
                    SoundManager.shared.playFireShot()                }
                // Für touchesEnd um Schiff zurückzudrehen
                touchActive = true
            }

        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGamePaused else { return }
        // For LevelRound
        if let lastPosition = lastTouchPosition {
            
            let screenHeight = scnView.bounds.height
            rightViewCamera = cameraNode.simdWorldRight  // X-Achse der Kamera
            upViewCamera = cameraNode.simdWorldUp        // Y-Achse der Kamera
            
            var totalAcceleration: Float = 0
            var totalDeltaTouchPositionX: Float = 0
            var totalDeltaTouchPositionY: Float = 0
            
            
            for touch in touches {
                let currentPosition = touch.location(in: scnView)
                let previousPosition = touch.previousLocation(in: scnView)
                let deltaX = Float(currentPosition.x - lastPosition.x) * 0.5
                let deltaY = Float(lastPosition.y - currentPosition.y) * 0.5
                activeTouches[touch] = currentPosition  // Speichere Touch-Positionen
                
                let touchPositionX = currentPosition.x
                let touchPositionY = currentPosition.y
                
                let deltaTouchPositionX = Float(previousPosition.x - touchPositionX) * -0.5
                let deltaTouchPositionY = Float(previousPosition.y - touchPositionY) * 0.5
                
                if bonusState == .active {    //###
                    if touchPositionX < 400 {
                        // 🚀 Links: Beschleunigung
                        let acceleration = Float((previousPosition.y - currentPosition.y) / screenHeight) * 4.0
                        totalAcceleration += acceleration
                    } else {
                        // 🎮 Rechts: Bewegung (X/Y)
                        totalDeltaTouchPositionX += deltaTouchPositionX
                        totalDeltaTouchPositionY += deltaTouchPositionY
                    }
                } else {
                    // Bewegung in X-Richtung (links/rechts)
                    if deltaX != 0 {
                        moveShipInXLevelRound(deltaX: deltaX)
                        velocity.x = deltaX
                    }
                    
                    // Bewegung in Y-Richtung (hoch/runter)
                    if deltaY != 0 {
                        moveShipInYLevelRound(deltaY: deltaY)
                        velocity.y = deltaY
                    }
                    
                    // Speichere die letzte Position
                    lastTouchPosition = currentPosition
                }
            }
            
            // **Bonusrunde: Bewegung anwenden**
            if bonusState == .active {    //###
                if totalAcceleration != 0 {
                    moveShipAccelerationBonusRound(acceleration: totalAcceleration)
                }
                if totalDeltaTouchPositionX != 0 {
                    moveShipLeftRightBonusRound(deltaX: totalDeltaTouchPositionX)
                }
                if totalDeltaTouchPositionY != 0 {
                    moveShipUpDownBonusRound(deltaY: totalDeltaTouchPositionY)
                }
                
                // Kamera mit Dämpfung bewegen
                let movement = (rightViewCamera * totalDeltaTouchPositionX) + (upViewCamera * totalDeltaTouchPositionY)
                lastCameraMovement = mix(lastCameraMovement, movement, t: cameraDampingFactor)
                
                isTouching = true
                lastDelta = SIMD3<Float>(0, totalDeltaTouchPositionY, totalDeltaTouchPositionX)
            }
        }
    }
    
    // -------------- Wenn du den Finger vom Display nimmst --------------
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            activeTouches.removeValue(forKey: touch)
        }
        
        shipSpeed = 0
            // Bewegung in Y ist gestoppt
        shipDirectionY = 0
        startShipOrientation = true  // Aktiviere Rücksetzung, wenn Touch endet
        
            // Bewegung in X ist gestoppt
        shipDirectionX = 0
        
            // Particel Ausstoß nach hinten einschalten
        // Versuch fireBoost.birthRate = 1000
        
            // Für die Zurückdrehung des Shiffes
        touchActive = false
        lastTouchPosition = nil
        
        // Chatty neu
        isTouching = false  // Finger wurde losgelassen
        isTouchingX = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    //MARK: Funktionen
    
    // Level Runde - Bewegung in Y-Richtung getriegert von  touchesMoved
    func moveShipInYLevelRound(deltaY: Float) {
        let maxValueLeftTurn: Float = -0.766  // Maximale Neigung nach links
        let maxValueRightTurn: Float = 0.766  // Maximale Neigung nach rechts
        let dynamicTurnStep = abs(deltaY) * 0.05 // Drehgeschwindigkeit dynamisch
        let currentQuaternion = twinShipNode.simdOrientation

        // **Extrahiere den aktuellen Drehwinkel um die X-Achse**
        let currentAngleX = 2 * acos(currentQuaternion.real) // Winkel in Radiant

        // **Fix: `sign` auf `Float` setzen**
        let sign: Float = currentQuaternion.imag.x >= 0 ? 1.0 : -1.0
        let signedCurrentAngleX = sign * currentAngleX

        if deltaY > 0 { // Bewege nach oben (Linksneigung)
            var newAngle = signedCurrentAngleX - dynamicTurnStep // INCREMENTAL ändern
            if newAngle < maxValueLeftTurn { newAngle = maxValueLeftTurn } // Begrenzung einbauen

            let rotationQuaternion = simd_quatf(angle: newAngle, axis: SIMD3(1, 0, 0))

            twinShipNode.simdOrientation = rotationQuaternion

            if twinShipNode.position.y < DeviceConfig.layout.shipMoveBorderY {
                twinShipNode.position.y += deltaY
            }

        } else if deltaY < 0 { // Bewege nach unten (Rechtsneigung)
            var newAngle = signedCurrentAngleX + dynamicTurnStep // INCREMENTAL ändern
            if newAngle > maxValueRightTurn { newAngle = maxValueRightTurn } // Begrenzung einbauen

            let rotationQuaternion = simd_quatf(angle: newAngle, axis: SIMD3(1, 0, 0))

            twinShipNode.simdOrientation = rotationQuaternion

            if twinShipNode.position.y > -DeviceConfig.layout.shipMoveBorderY {
                twinShipNode.position.y += deltaY
            }
        }
    }
    
    // Funktion: Bewegung in X-Richtung - nicht benutzt
    func moveShipInXLevelRound(deltaX: Float) {

        // Bewege das Schiff nur, wenn es innerhalb der Grenzen ist
        if deltaX > 0, twinShipNode.position.x < DeviceConfig.layout.shipMoveBorderX {
            twinShipNode.position.x += deltaX
            fireBoost.birthRate = 1000
        } else if deltaX < 0, twinShipNode.position.x > -DeviceConfig.layout.shipMoveBorderX {
            twinShipNode.position.x += deltaX
            fireBoost.birthRate = 100
        }
    }
    
    /// Bewegt das Schiff links/rechts in Z-Richtung und kippt es um die X-Achse basierend auf Touch-Delta
    /// - Parameter deltaX: Bewegungswert von der Touch-Eingabe (positiv = rechts, negativ = links)
    func moveShipLeftRightBonusRound(deltaX: Float) {
        // Maximale Rotationsgrenze um die X-Achse (~39°)
        let maxRotationX: Float = 0.68
        // Rotationsschritt basierend auf Touch-Bewegung, begrenzt für sanftere Änderungen
        let dynamicTurnStep = abs(deltaX) * 0.05
        // Aktuelle Orientierung und Position des Schiffes
        let currentQuaternion = twinShipBonusNode.simdOrientation
        let currentPosition = twinShipBonusNode.simdPosition

        // Berechne aktuelle X-Rotation (Euler-Winkel) aus dem Quaternion
        let qw = Double(currentQuaternion.vector.w)
        let qx = Double(currentQuaternion.vector.x)
        let qy = Double(currentQuaternion.vector.y)
        let qz = Double(currentQuaternion.vector.z)
        let term1 = 2.0 * (qw * qx - qy * qz)
        let term2 = 1.0 - 2.0 * (qx * qx + qy * qy)
        let currentXRotation = Float(atan2(term1, term2))

        // Bestimme den Rotationsschritt mit Begrenzung
        let angleStep: Float
        if deltaX > 0 {
            angleStep = currentXRotation > maxRotationX ? 0 : dynamicTurnStep  // Rechtskippen
        } else {
            angleStep = currentXRotation < -maxRotationX ? 0 : -dynamicTurnStep  // Linkskippen
        }

        // Erstelle Quaternion für Rotation um X-Achse (Winken)
        let rotationQuaternion = simd_quatf(angle: angleStep, axis: SIMD3<Float>(1, 0, 0))
        // Wende gedämpfte Rotation an (slerp für smooth Übergang)
        let interpolatedRotation = simd_slerp(currentQuaternion, rotationQuaternion * currentQuaternion, shipDampingFactor)
        twinShipBonusNode.simdOrientation = interpolatedRotation

        // Bewege das Schiff in Z-Richtung (links/rechts) basierend auf deltaX, halbiert für weniger starke Bewegung
        let targetPosition = currentPosition + SIMD3<Float>(0, 0, deltaX * 0.5)  // Z-Bewegung halbiert
        // Wende gedämpfte Position an (mix für smooth Übergang)
        twinShipBonusNode.simdPosition = mix(currentPosition, targetPosition, t: shipDampingFactor)
    }
    
    /// Bewegt das Schiff hoch/runter in Y-Richtung, kippt es um die Z-Achse und dreht es proportional um die Y-Achse basierend auf Touch-Delta
    /// - Parameter deltaY: Bewegungswert von der Touch-Eingabe (positiv = hoch, negativ = runter)
    func moveShipUpDownBonusRound(deltaY: Float) {
        // Maximale Rotationsgrenze um die Z-Achse (~39°)
        let maxRotationZ: Float = 0.68
        // Rotationsschritt für Z basierend auf Touch-Bewegung, begrenzt für sanftere Änderungen
        let dynamicTurnStep = abs(deltaY) * 0.05
        // Aktuelle Orientierung und Position des Schiffes
        let currentQuaternion = twinShipBonusNode.orientation   // Start-Quaternion
        let currentPosition = twinShipBonusNode.simdPosition    // Position

        // Berechne aktuelle Z-Rotation (Euler-Winkel) aus dem Quaternion
        let q = currentQuaternion
        let currentZRotation = atan2(2.0 * (q.w * q.z + q.x * q.y),
                                     1.0 - 2.0 * (q.y * q.y + q.z * q.z))

        // Bestimme den Rotationsschritt für Z mit Begrenzung
        let angleStep = deltaY < 0
            ? (currentZRotation > maxRotationZ ? 0 : dynamicTurnStep)
            : (currentZRotation < -maxRotationZ ? 0 : -dynamicTurnStep)

        // Erstelle Quaternion für Rotation um Z-Achse
        let rotationQuaternion = createQuaternion(axis: SCNVector3(0, 0, 1),
                                                  angleInRadians: angleStep)

        // Wende gedämpfte Rotation an (lerp für smooth Übergang)
        let interpolatedRotation = SCNQuaternion.lerp(from: currentQuaternion,
                                                      to: combineQuaternions(q1: currentQuaternion,
                                                                             q2: rotationQuaternion),
                                                      factor: shipDampingFactor)
        twinShipBonusNode.orientation = interpolatedRotation

        // Bewege das Schiff in Y-Richtung (Höhe) basierend auf deltaY
        let targetPosition = currentPosition + SIMD3<Float>(0, deltaY, 0)
        
        // Wende gedämpfte Position an (mix für smooth Übergang)
        twinShipBonusNode.simdPosition = mix(currentPosition, targetPosition, t: shipDampingFactor)
    }
    
    func moveShipAccelerationBonusRound(acceleration: Float) {
        
        let forwardViewCamera = SIMD3<Float>(1, 0, 0) // Lokale Richtung in X+
        let maxSpeed: Float = 10.0                  // Maximale Geschwindigkeit
        // Beschleunigung entlang der X-Achse
        let accelerationVector = forwardViewCamera * acceleration * accelerationFactor

        //  Geschwindigkeit aktualisieren
        twinShipBonusVelocity += accelerationVector

        //  Begrenzung der Geschwindigkeit mit `min` und `max`
        twinShipBonusVelocity.x = max(-maxSpeed, min(maxSpeed, twinShipBonusVelocity.x))

        // Dämpfung anwenden, um Geschwindigkeit langsam abzubremsen
        twinShipBonusVelocity *= dampingFactor
       
        let velocityLength: CGFloat
        if twinShipBonusVelocity.x >= 0 {
            velocityLength = CGFloat(max(0, min(1000, 1000 * length(twinShipBonusVelocity))))  // Bereich 0-1000
        } else {
            velocityLength = 0  // Rückwärtsfliegen -> keine Partikel
        }
        
        fireBoost.birthRate = velocityLength
        
        // Dynamische Anpassung des shipDampingFactor basierend auf birthRate (0 -> 0.9, 1000 -> 0.2)
        let minDamping: Float = 0.2   // Bei max birthRate (1000)
        let maxDamping: Float = 0.9   // Bei min birthRate (0)
        let dampingRange = maxDamping - minDamping
        let birthRateFactor = Float(velocityLength) / 1000.0  // Normalisiere birthRate auf 0-1
        shipDampingFactor = maxDamping - (dampingRange * birthRateFactor)  // Linear interpolieren
    }
    
    func animateFire() {
        if bonusState == .enabled {
            
            // Erzeuge zwei Feuerkugeln – rechts und links am Schiff
            createFire(side: .right, yOffset: FireConfig.fireOffsetRightYToShip)
            createFire(side: .left, yOffset: FireConfig.fireOffsetLeftYToShip)
            
            // Hole die zuletzt erzeugten Feuerkugeln (jeweils links/rechts)
            if let fireBulletRight = fireNodeRight.last, let fireBulletLeft = fireNodeLeft.last {
                
                // Orientation = Rotation des Schiffs im 3D-Raum
                let orientation = twinShipBonusNode.simdOrientation
                
                // Aktiviere die lokale X-Achse (nach vorne) in Weltkoordinaten
                // Das heißt: wohin das Schiff gerade "schaut"
                let forwardDirection = orientation.act(SIMD3<Float>(1, 0, 0))
                
                // Zielposition = 2010 Einheiten nach vorne (plus etwas Puffer)
                let distance: Float = 2010
                let targetOffset = forwardDirection * distance
                let targetPositionRight = fireBulletRight.simdPosition + targetOffset
                let targetPositionLeft = fireBulletLeft.simdPosition + targetOffset
                
                // Bewegung: Kugel fliegt nach vorne über 4 Sekunden
                let moveActionForwardRight = SCNAction.move(to: SCNVector3(targetPositionRight), duration: 4.0)
                let moveActionForwardLeft = SCNAction.move(to: SCNVector3(targetPositionLeft), duration: 4.0)
                
                // Danach sanft ausblenden (0.5s) und aus der Szene entfernen
                let fadeOutAction = SCNAction.fadeOut(duration: 0.5)
                let removeAction = SCNAction.removeFromParentNode()
                
                // Aktion: Bewegung → Ausblenden → Löschen
                let sequenceRight = SCNAction.sequence([moveActionForwardRight, fadeOutAction, removeAction])
                let sequenceLeft = SCNAction.sequence([moveActionForwardLeft, fadeOutAction, removeAction])
                
                // Unterschiedliche Logik je nach Feuerstufe (1 = normal, 2 = Upgrade)
                // FIXME: Delta in 3D nicht inbegriffen?
                if fireType == .single {
                    fireBulletRight.runAction(sequenceRight)
                    fireBulletLeft.runAction(sequenceLeft)
                } else if fireType == .double {
                    fireBulletRight.runAction(sequenceRight)
                    fireBulletLeft.runAction(sequenceLeft)
                }
            }
        } else {
            // --------------------
            // 🎮 LEVELRUNDE (2D)
            // --------------------
            
            // Erzeuge Feuerkugeln (links & rechts)
            createFire(side: .right, yOffset: FireConfig.fireOffsetRightYToShip)
            createFire(side: .left, yOffset: FireConfig.fireOffsetLeftYToShip)
            
            // Position des Schiffs holen (für Startposition)
            let twinShipPositionX = floor(twinShipNode.presentation.position.x) + 80
            let twinShipPositionY = floor(twinShipNode.presentation.position.y)
            
            // Wenn die Kugeln existieren...
            if let fireBulletRight = fireNodeRight.last, let fireBulletLeft = fireNodeLeft.last {
                
                // Delta-Bewegung, 0.2s für fireType = .single
                let moveActionDeltaRight = SCNAction.move(to: SCNVector3(twinShipPositionX, twinShipPositionY, 0), duration: 0.2)
                let moveActionDeltaLeft = SCNAction.move(to: SCNVector3(twinShipPositionX, twinShipPositionY, 0), duration: 0.2)
                
                // Für beide fireBullet gerade Bahn nach links für fireType = .double
                let moveActionBorderX = SCNAction.move(to: SCNVector3(fireMoveBorderX + 10, twinShipPositionY, 0), duration: 1.0)
                
                // Die linke fireBullet nach Delta-Bewegung sofort nach BorderX (Ausserhalb Display)
                let moveParkingPlace = SCNAction.run { [self] _ in
                    fireBulletLeft.position = SCNVector3(x: fireMoveBorderX + 10, y: 0, z: 0)
                }
                
                // Für fireType = .single die Bewegung vom Delta - Zusammenfassende Sequenz mit der geraden Schussbahn ...
                let sequenceDeltaRight = SCNAction.sequence([moveActionDeltaRight, moveActionBorderX])
                //... dem setzten auf die Position ausserhalb des Displays
                let sequenceDeltaLeft = SCNAction.sequence([moveActionDeltaLeft, moveParkingPlace])
                
                // Je nach Level: andere Bewegungslogik
                if fireType == .single {
                    //Eine Kugel
                    fireBulletRight.runAction(sequenceDeltaRight)
                    fireBulletLeft.runAction(sequenceDeltaLeft)
                    //Zwei Kugeln
                } else if fireType == .double {
                    fireBulletRight.runAction(moveActionBorderX)
                    fireBulletLeft.runAction(moveActionBorderX)
                }
            }
        }
    }
}
