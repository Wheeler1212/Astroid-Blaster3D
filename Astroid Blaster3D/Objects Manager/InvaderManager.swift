//
//  AnimateInvader.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 06.04.25.
//

import SceneKit

extension GameViewController {
    
    
    //Animate Invader (alle 1/60 Sekunden
    func startTimerAnimateSpaceInvader() {
        
        if timerAnimateSpaceInvader != nil {
            timerAnimateSpaceInvader?.invalidate()
        }
        
        spaceInvaderBase.opacity = 1.0
        
        DispatchQueue.main.async { [self] in
            timerAnimateSpaceInvader = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [self] timer in
                // Für die langsameren PopUp und FallDown Funktionen
                animationSlowDownInvader += 1
                if animationSlowDownInvader > 3 {
                    animationSlowDownInvader = 0
                }
                //Invader erscheint (Nur jeder dritte Timeraufruf)
                if spaceInvaderState == .popUp && animationSlowDownInvader == 0 {
                    animateCubePopUp()
                }
                //Invader im abgegrenzten Rechteck bewegen
                if isStartSpaceInvader && isStartToMoveInvader {
                    moveInvaderWithinRectangle()
                }
                // Vertikale Rotation des SpaceInvader
                if isStartSpaceInvader && isStartToRotateByFireHitInvader {
                   animateRotation()
                }
                // SpaceInvader ist beim Circle nach Break Down
                if isCircleSpaceInvader {
                    updateChaosFormation()
                }
                // Invader verschwindet (Nur jeder dritte Timeraufruf)
                if isCubeFallingDownInvader && animationSlowDownInvader == 0 {
                    animateCubeFallDown()
                }
                //Verfolgung von Shield zum TwinShip
                if isShieldStartToChaseTwinShip {
                    shieldStartToChaseTwinShip()
                }
            }
        }
    }
    
    // Timer für
    func startEnemySegmentTimer(_ state: SpaceInvaderState, duration: TimeInterval) {
        if enemySegmentTimer != nil {
            enemySegmentTimer?.invalidate()
        }
        
        DispatchQueue.main.async { [self] in
            enemySegmentTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [self] timer in
                
                manageEnemyDespawn(state)
            }
        }
    }

    // Wiederkehrender Aufruf durch Timer
    func animateRotation() {
        // FIXME: War mal 5.0 aber Schwierigkeitsgrad zu hoch (eventuell bei Level 20)
        if rotationSpeedInvader < 4.0 && !isStartChaosInvader {
            indexIsHitNodeNumber += 1 // Nächster Cube
            
            //Vertikale Rotation
            if isSpeedUpInvader {
                // Kombinierte lineare und exponentielle Beschleunigung (Eine Art EaseIn)
                rotationSpeedInvader += 0.01
                rotationSpeedInvader *= 1.1
                
                // Wenn MaxSpeed erreicht, keine Beschleunigung mehr
                if rotationSpeedInvader > rotationSpeedMaxInvader {
                    isSpeedUpInvader = false
                    isCollisionDebounced = false
                }
                
                score += rotationSpeedInvader * 100
                updateHUD()
                
            } else {
                // Nach MaxSpeed mit Art EaseIn langsamer werden
                rotationSpeedInvader -= 0.01
                rotationSpeedInvader *= 0.99
            }
            
            // Ab jetzt kein zeitgesteuertes Ende mehr
            if !isCubeFallDownCanceledInvader {
                enemySegmentTimer?.invalidate()
                enemySegmentTimer = nil
                
                isCubeFallDownCanceledInvader = true
            }
            
            // Fortschreitender Winkel im Kreis
            rotatenAngleRotation = 2.0 * Float.pi * rotationSpeedInvader
            
            // Vertikale Rotation des Invader
            animateExpansion()
            
            // Wird durchlaufen wenn Invader steht während State .rotate
            if rotationSpeedInvader < -0.5 {
                rotationSpeedInvader = -0.5
                if isSpaceInvaderEndTimerEnabled {
                    manageEnemyStateCycle(.spaceInvader, .rotate, duration: 10)
                    isSpaceInvaderEndTimerEnabled = false
                }
            }
            
            // Wenn er langsamer als Drehzahlmode 1 dreht dann mit Grunddrehzahl wieder beginnen
            if rotationSpeedInvader < 1.0 {
                rotationSpeedMaxInvader = 1.0
            }
        } else {
            // Invader fällt nach mehrfachem Beschuss zusammen
            if !isStartChaosInvader {
                initiateChaosCollapse()
            }
            isStartChaosInvader = true  // Nur einmal durchlaufen lassen
        }
    }
    
    //Initialisierung für .chaos
    private func initiateChaosCollapse() {
        spaceInvaderState = .chaos
        // Damit das Shield auch an der Position des Invader bleibt
        shieldNode.worldPosition = spaceInvaderBase.worldPosition
        shieldNode.isHidden = false
        shieldNode.opacity = 1.0
        // Alle eventuelle Actions stoppen
        spaceInvaderBase.removeAllActions()
        
        // Action für den Kollaps der Cupes nach 0,0,0 initiieren
        let breakDown = SCNAction.move(to: SCNVector3(x: 0, y: 0, z: 0), duration: 0.4)
        // Eine zufällige Positionen der einzelnen Cubes speichern
        for (index,node) in spaceInvaderArray.enumerated() where index > 0{
            
            circlePositionXArray[index] = Float.random(in: -50...50)
            circlePositionYArray[index] = Float.random(in: -50...50)
            circlePositionZArray[index] = Float.random(in: -50...50)
            // Start BreakDown der Invaders-Nodes
            node.runAction(breakDown) { [self] in
                
                if index == 46 {        // Der letzte Cube (Node 1 bis 46)
                    isCircleSpaceInvader = true // Circle im Timer starten
                    // Explosion nach dem auf einen Punkt zusammenfallen der Cubes
                    createExplosion(for: node, newSize: 10)
                }
            }
        }
    }
    
    // Vertikale Rotation des Invader
    private func animateExpansion() {
        for indexX in 0...10 { // Zeile
            for indexY in 1...8 { //Spalte
                // indexIsHitNodeNumber entspricht NodeNummber vom InvaderCube
                indexIsHitNodeNumber = spaceInvaderCubePositionNode[indexY][indexX]
                // Wenn Null dann kein Cube
                if indexIsHitNodeNumber != 0 {
                    
                    // Invader durch Zentrifugalkraft aufblähen
                    let node = spaceInvaderArray[indexIsHitNodeNumber]
                    let growthRateHorizontal = rotationSpeedInvader / 4
                    let growthRateVertical = rotationSpeedInvader / 7
                    
                    // Das Drehzentrum vom Invader
                    let PositionCenterInvader = spaceInvaderBase.position
                    
                    // Die gespeicherte Position der CubeNode mit Vergrößerung (*5)
                    let InvaderPositionX = Float(spaceInvaderCubePositionX[indexY][indexX]) * 5
                    let InvaderPositionY = Float(spaceInvaderCubePositionY[indexY][indexX]) * 5
                    
                    // Position in der vertikalen Ebene * Expansion durch Zentrifugalkraft
                    let InvaderPositionExpandX = InvaderPositionX + InvaderPositionX * growthRateHorizontal
                    let InvaderPositionExpandY = InvaderPositionY + InvaderPositionY * growthRateVertical
                    
                    //Kreisberechnung vom Mittelpunkt(spaceInvaderBase)
                    let newX = PositionCenterInvader.x + InvaderPositionExpandX * cos(rotatenAngleRotation)
                    let newZ = PositionCenterInvader.z + InvaderPositionExpandX * sin(rotatenAngleRotation)
                    let newY = PositionCenterInvader.y + InvaderPositionExpandY
                    
                    // Position endgültig schreiben
                    node.worldPosition = SCNVector3(newX, newY, newZ)  // Setzen der neuen Position
                    
                }
            }
        }
    }
    
    // Wiederkehrender Aufruf durch Timer
    func moveInvaderWithinRectangle() {
        // Invader innerhalb X-Wert
        if moveStepXDirection > moveObjectRangeX.upperBound ||
           moveStepXDirection < moveObjectRangeX.lowerBound {
            //Bewegung links/rechts
            moveLeftInvader = -moveLeftInvader
        }
        // Invader innerhalb Y-Wert
        if moveStepYDirection > moveObjectRangeY.upperBound ||
           moveStepYDirection < moveObjectRangeY.lowerBound {
            //Bewegung oben/unten
            moveDownInvader = -moveDownInvader
        }
        // Geschwindigkeit erhöhen
        if velosityMoveStepOfInvader < 2 && !isHitInvaderFirst {
            velosityMoveStepOfInvader += 0.01
        }
        // Position schreiben
        moveStepXDirection += moveLeftInvader * velosityMoveStepOfInvader
        moveStepYDirection += moveDownInvader * velosityMoveStepOfInvader
        spaceInvaderBase.position.x = moveStepXDirection
        spaceInvaderBase.position.y = moveStepYDirection
    }
    
    // *** Wird vom GameManager fireHitEnemy() aufgerufen ***
    /// Invader beschleunigt Rotation bis Max-Geschwindigkeit
    func increaseSpinSpeedOnHit(nameOfNode: String, fireNode: SCNNode) {
        // Entprellen und kein CubePopUP und kein CubeFall Down
        if !(isCollisionDebounced || spaceInvaderState == .popUp || isCubeFallingDownInvader) {
            
            score += 500
            updateHUD()
            // Wenn Invader sich bewegt
            if isStartToMoveInvader {
                // Bei jedem Treffer einen Schritt langsamer
                velosityMoveStepOfInvader -= 0.1
                // Mit jedem Treffer Bescheuningung stoppen
                isHitInvaderFirst = true
                // Wenn Invader komplett steht
                if velosityMoveStepOfInvader < 0 {
                    velosityMoveStepOfInvader = 0
                    isStartToMoveInvader = false
                    spaceInvaderState = .rotate
                }
            } else {    // Wenn Invader steht
                // Wird erst wieder freigeschaltet wenn SpaceInvader Max. Drehzahl hat
                isCollisionDebounced = true  // Entprellung
                isStartToRotateByFireHitInvader = true    // Auf Speed 0 ist Rotation freigegeben
                isSpeedUpInvader = true    // Nächster Treffer mit Rotation
                rotationSpeedInvader = 1     // Grunddrehzahl
                rotationSpeedMaxInvader += 1   // Max Drehzahl anheben
            }
        }   // Ende - !spaceInvaderKollisionRecognized
        nodeSpaceInvader = spaceInvaderNodeDictionary[nameOfNode]
        
        // Ausser im InvaderCircle Explosion an dem getroffenen Cube
        if !isCircleFinishedInvader {
            createExplosion(for: fireNode, newSize: 10)
        }
        // Erst bei fertiggestelltem Kreis Cube nach Beschuss ins Zentrum fallen lassen
        if isCircleFinishedInvader && isDoubleHitAvoid {
            
            shieldNode.scale = SCNVector3(0.001, 0.001, 0.001)
            cubeDidGetHitAndFallsToCenter()
        }
    }
    
    // Bei Circle CubeFallToCenter nach Feuerbeschuss
    private func cubeDidGetHitAndFallsToCenter() {
        score += 200    // Zusatzpunkte
        updateHUD()
        
        // Damit nicht zwei oder mehr Cubes getroffen werden
        spaceInvaderCubeCounter += 1
        isDoubleHitAvoid = false // Entprellen
        
        // Shield nach Treffer leicht vergrößern
        scaleTwinShipShield += 0.2  // Shieldgröße SOLL 10 durch 45 Cubes SOLL 0.2
        
        // Sonst wird der Cube mehrfach bearbeitet
        nodeSpaceInvader.physicsBody = nil
        
        // Cube vergrößern...
        let pumpUpAction = SCNAction.scale(by: 1.5, duration: 0.2)
        
        // ... Cube verkleinern, ausblenden und zum Mittelpunkt bewegen
        let pumpDown = SCNAction.scale(to: 0.01, duration: 0.5)
        let fadeOut = SCNAction.fadeOut(duration: 0.5)
        let moveDown = SCNAction.move(to: PositionCenterInvader, duration: 0.5)
        let groupAction = SCNAction.group([pumpDown, fadeOut, moveDown])
        
        // ShieldAction kurz aufpumpen (Scale +10) dann wieder verkleinern (Scale +=0.6)
        let pumpUpShield = SCNAction.scale(to: scaleTwinShipShield + 10, duration: 0.05)
        let pumpDownShield = SCNAction.scale(to: scaleTwinShipShield, duration: 0.1)
        let sequenceShield = SCNAction.sequence([pumpUpShield, pumpDownShield])
        let setDoubleHitAvoid = SCNAction.run { [self] _ in
            // Jetzt ist der mögliche Abschuss wieder frei
            isDoubleHitAvoid = true
        }
        
        // *** ScaleUp um 1.5 in 0.2 Sekunden dann zum Entprellen doubleHitAvoid = true dann verkleinern, ausblenden und in den Kreismittelpunkt bewegen
        let sequenceCube = SCNAction.sequence([pumpUpAction, setDoubleHitAvoid, groupAction])
        // *** (siehe oben) starten und dann erst das Shield Scale +10 in 0.1 Sekunden
        nodeSpaceInvader.runAction(sequenceCube) { [self] in
            shieldNode.runAction(sequenceShield)
        }
        
        // Sind alle Cubes abgeschossen worden
        if spaceInvaderCubeCounter == spaceInvaderArray.count {
            
            spaceInvaderState = .idle
            // Zwei Sekunden warten bis Shield den TwinShip verfolgt
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                //Routine für Verfolgung freigeben
                isShieldStartToChaseTwinShip = true
            }
        }
    }

    // Wiederkehrender Aufruf durch Timer
    func updateChaosFormation() {
        // Invader beginnt nach dem zusammenfallen sich für die Kreis-Rotation zu formieren
        rotationAngleInChaosState += 0.01
        
        // Rotationsmittelpunkt setzten
        // Die X und Y Werte werden hier Step by Step auf 30 (Radius) erhöht
        for (index,node) in spaceInvaderArray.enumerated() where index > 0 {
            
            // X-Position für den Kreis errechnen
            updateCirclePosition(&circlePositionXArray[index], range: -30...30, adjustment: 0.01)
            updateCirclePosition(&circlePositionYArray[index], range: -30...30, adjustment: 0.01)
            updateCirclePosition(&circlePositionZArray[index], range: 0...0, adjustment: 0.1)
            
            // Die Cubes in einen Ring kreisen lassen
            angleArrayChaos[index] = rotationAngleInChaosState + (0.5 * Float(index))
            
            // Angepasste Radius beim PumpUp
            circlePositionX = circlePositionXArray[index] * pumpUpOfSpace
            circlePositionY = circlePositionYArray[index] * pumpUpOfSpace
            circlePositionZ = circlePositionZArray[index] * pumpUpOfSpace
            
            
            //Kreisberechnung vom Mittelpunkt(spaceInvaderBase)
            let newX = PositionCenterInvader.x + circlePositionX  // Radius
                       * sin(circlePositionXArray[index])         // Konstant (phi)
                       * cos(angleArrayChaos[index])              // Kontinuierlich erhöht (theta)
            
            let newY = PositionCenterInvader.y + circlePositionY  // Radius
                       * sin(circlePositionYArray[index])         // Konstant (phi)
                       * sin(angleArrayChaos[index])              // Kontinuierlich erhöht (theta)
            
            let newZ = PositionCenterInvader.z + circlePositionZ  // Radius
                       * cos(circlePositionZArray[index])         // Konstant (phi)
            
            // Setzen der neuen Position für das PumpUp
            if index == 46 && pumpUpOfSpace < 1 {
                pumpUpOfSpace += 0.01
            }
            
            node.position = SCNVector3(newX, newY, newZ)
            //  Eventuell rotieren lassen    /node.rotation = SCNVector4(45, -45, 90, angleArrayChaos[index])
        }
        
        // Diese drei Zeilen prüfen ob der Kreis nun rund ist ...
        let allAreThirtyX = circlePositionXArray.allSatisfy { $0 == 30 || $0 == -30 }
        let allAreThirtyY = circlePositionYArray.allSatisfy { $0 == 30 || $0 == -30 }
        let allAreZeroZ = circlePositionZArray.allSatisfy { $0 == 0 }
        
        // ... wenn ja, dann kann auf sie geschossen werden
        if allAreThirtyX && allAreThirtyY && allAreZeroZ {
            if !isCircleFinishedInvader {
                isCircleFinishedInvader = true
                spaceInvaderState = .circle
                //counter += 1
            }
        }
    }
   
    // Wiederkehrender Aufruf durch Timer
    func shieldStartToChaseTwinShip() {
        // Richtung berechnen, in die sich Shield bewegen muss
        let direction = SCNVector3(
            x: twinShipNode.worldPosition.x - shieldNode.worldPosition.x,
            y: twinShipNode.worldPosition.y - shieldNode.worldPosition.y,
            z: twinShipNode.worldPosition.z - shieldNode.worldPosition.z
        )
        
        // Abstand zwischen Shield und TwinShip berechnen
        let length = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
        if length > 0 {
            // Richtung normalisieren, um eine konstante Bewegungsgeschwindigkeit zu gewährleisten
            let normalizedDirection = SCNVector3(
                x: direction.x / length,
                y: direction.y / length,
                z: direction.z / length
            )
            
            // Shield in Richtung TwinShip bewegen
            shieldNode.worldPosition = SCNVector3(
                x: shieldNode.worldPosition.x + normalizedDirection.x * 1,
                y: shieldNode.worldPosition.y + normalizedDirection.y * 1,
                z: shieldNode.worldPosition.z + normalizedDirection.z * 1
            )
        }
        
        // Wenn beide Positionen bis auf die Einer-Stelle übereinstimmen ...
        if floor(twinShipNode.worldPosition.x) == floor(shieldNode.worldPosition.x) &&
            floor(twinShipNode.worldPosition.y) == floor(shieldNode.worldPosition.y)  {
            
            // ... dann liegt Shield über dem TwinShip und somit unzerstörbar
            twinShipNode.addChildNode(shieldNode)
            // Einen satten Score hinzu
            score += 10000
            updateHUD()
            // Shield pulsieren lassen
            twinShipShieldBlink = true
            // Diese Routine dann nicht mehr durchlaufen lassen
            isShieldStartToChaseTwinShip = false
            // Auch diese Routine nicht mehr durchlaufen lassen (übergeordnet)
            isStartToRotateByFireHitInvader = false
            // Operation beendet
            despawnSpaceInvader()
        }
    }
    
    //Unter-Funktion für updateChaosFormation()
    private func updateCirclePosition(_ value: inout Float, range: ClosedRange<Float>, adjustment: Float) {
        switch value {
        case range.lowerBound - 0.2...range.lowerBound + 0.2:
            value = range.lowerBound
        case range.upperBound - 0.2...range.upperBound + 0.2:
            value = range.upperBound
        case -60...range.lowerBound:
            value += adjustment
        case range.lowerBound...0:
            value -= adjustment
        case 0...range.upperBound:
            value += adjustment
        case range.upperBound...60:
            value -= adjustment
        default:
            print("Value \(value) is not assignable")
        }
    }
    
    // Wiederkehrender Aufruf durch Timer
    func animateCubePopUp() {
        indexCubePopUp += 1      // von rechts oben nach links unten
        
        // Alle SCNAction gesetzt
        let scalePopUp = SCNAction.scale(to: 8, duration: TimeInterval(0.1))//(0.5))
        let scalePopDown = SCNAction.scale(to: 5, duration: TimeInterval(0.05))//(0.1))
        let groupAction = SCNAction.sequence([scalePopUp, scalePopDown])
        
        // Von Abstellposition zum Mittelpunkt versetzten
        spaceInvaderArray[indexCubePopUp].position = SCNVector3(
            x: spaceInvaderPosX[indexCubePopUp]*5,
            y: spaceInvaderPosY[indexCubePopUp]*5,
            z: 0)
        
        // PopUp-Animation der einzelnen Cubes starten
        spaceInvaderArray[indexCubePopUp].runAction(groupAction)
        
        
        // Nach dem PopUp des letzten Cubes ausführen
        if indexCubePopUp == 46 {
            spaceInvaderState = .moving
            // .moving darf nur eine bestimmte Zeit dauern
            manageEnemyStateCycle(.spaceInvader, .moving, duration: 10)
            // Der Invader steht also Bewegung starten
            isStartToMoveInvader = true
            // Loopzähler für nächsten Druchlauf löschen
            indexCubePopUp = 0
            // Nur die Bewegung des Invaders
            isStartSpaceInvader = true
            // Jetzt erst Sound starten
            SoundManager.shared.playSpaceInvader()
        }
    }

    // Wiederkehrender Aufruf durch Timer
    func animateCubeFallDown()  {
        guard indexFallDown > 0 else { return }
        
        // Wenn von links unten nach rechts oben dann -= 1 und Start bei 47
        indexFallDown -= 1
        let currentIndex = indexFallDown
        
        isStartToMoveInvader = false    // Zuerst Invader stoppen
        spaceInvaderBase.removeAllActions() // Stehenbleiben beim Zerfall der Cubes
        
        let currentPositionInvaderX = spaceInvaderArray[indexFallDown].position.x
        let currentPositionInvaderY = spaceInvaderArray[indexFallDown].position.y
        
        let scaleDown = SCNAction.scale(to: 0.1, duration: TimeInterval(0.5))
        let moveDown = SCNAction.moveBy(x: CGFloat(currentPositionInvaderX),
                                        y: CGFloat(currentPositionInvaderY) - 100,
                                        z: 0,
                                        duration: 0.5)
        
        let groupAction = SCNAction.group([scaleDown, moveDown])
        
        spaceInvaderArray[currentIndex].runAction(groupAction){ [self] in
        // Und zurück zur Parkposition#
        spaceInvaderArray[currentIndex].position = parkPositionOfSpaceInvader
            // Bei der letzten Cube ...
            if indexFallDown == 0 {     // wird nur einmal ausgeführt
                // Und alle Variablen wieder zurücksetzen
                resetSpaceInvader()
                timerAnimateSpaceInvader?.invalidate()
                timerAnimateSpaceInvader = nil
                currentEnemy = .none
                scheduleNextEnemy(.spaceInvader)
            }
        }
    }
    
    // SpaceInvader ausblenden
    func despawnSpaceInvader() {
        let scaleDownAction = SCNAction.scale(to: 0.01, duration: 0.5)
        // Alle Cubes durch ScaleDown verschwinden lassen
        for (_,node) in spaceInvaderArray.enumerated() {
            node.runAction(scaleDownAction) { [self] in
                node.position = parkPositionOfSpaceInvader
                node.opacity = 1
            }
        }
        
        timerAnimateSpaceInvader?.invalidate()
        timerAnimateSpaceInvader = nil
        
        resetSpaceInvader()
        currentEnemy = .none
        scheduleNextEnemy(.spaceInvader)
    }
    
    // SpaceInvader zurücksetzten für Neustart
    func resetSpaceInvader() {
        spaceInvaderBase.removeAllActions()
        spaceInvaderState = .idle
        isStartSpaceInvader = false
        isCollisionDebounced = false
        isCubeFallingDownInvader = false
        isHitInvaderFirst = false
        isStartToRotateByFireHitInvader = false
        isStartChaosInvader = false
        isCircleSpaceInvader = false
        isCircleFinishedInvader = false
        isShieldStartToChaseTwinShip = false
        isDoubleHitAvoid = true
        isSpeedUpInvader = false
        isCubeFallDownCanceledInvader = false
        isStartToMoveInvader = false
        isSpaceInvaderEndTimerEnabled = true
        indexFallDown = 47
        velosityMoveStepOfInvader = 0.1
        spaceInvaderCubeCounter = 1
        indexIsHitNodeNumber = 0
        indexCubePopUp = 0
        rotationSpeedInvader = 0
        rotationSpeedMaxInvader = 0
        scaleTwinShipShield = 0
        pumpUpOfSpace = 0
        rotatenAngleRotation = 0
        rotationAngleInChaosState = 0
        shieldNode.position = parkPositionOfShield
    }
}
