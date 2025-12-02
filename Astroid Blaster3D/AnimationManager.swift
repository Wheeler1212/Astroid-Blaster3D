


import SceneKit


extension GameViewController {
           
    // Startet schrittweise die Eingangs-Animation
    func startGameIntro() {
        DispatchQueue.main.async { [self] in
            // Perspektivische Darstellung bei der Animation
            switchToPerspective(cameraNode: cameraNode, duration: 2)
            
            // Animations Lichter einschalten
            keyLightNode.isHidden = false
            fillLightNode.isHidden = false
            backLightNode.isHidden = false
            ambientLightNode.isHidden = false

            // Die beiden Start Animationen vorbereiten
            startIntroAnimationProbe()
            startIntroAnimationForShip()
            
            // Animation für SpaceProbe starten
            spaceProbeParentNode.runAction(moveSpaceProbeSequence!)
            spaceProbeTopNode.runAction(animateSpaceProbeTopNodeSequence!)
            spaceProbeBottomNode.runAction(animateSpaceProbeBottomNodeSequence!)

            // Animation für TwinShip starten
            twinShipStartNode.runAction(moveTwinShipSequence!) { [self] in
                // Für das Spiel wieder auf orthografische Darstellung stellen
                switchToOrthographic(cameraNode: cameraNode, duration: 2)
                // TwinShip auf seitenlage und nach X+ schauen lassen
                twinShipStartNode.orientation = startQuaternion
                
                // Animations Lichter wieder ausschalten
                keyLightNode.isHidden = true
                fillLightNode.isHidden = true
                backLightNode.isHidden = true
                ambientLightNode.isHidden = true
                
                // Spiel verzögert starten damit Animation ferig auslaufen kann
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [self] in
                    startGameDisplay()
                }
            }
        }
    }
    
    // MARK: - Animate Probe
    func startIntroAnimationProbe() {
        // Startposition der Probe und sichtbar machen
        let startPointSpaceProbe = SCNVector3(-1000,-50, 0) //100) // cameraNode.position x: 0, y: 0, z: 100
        spaceProbeParentNode.opacity = 1.0
        spaceProbeParentNode.position = startPointSpaceProbe
        
// Ausdehnungspunkte des Halbkreises
        let controlPointSpaceProbeToGreenStar = SCNVector3(-100,-50,-100)
        let controlPointSpaceProbeToRedStar = SCNVector3(500,-70,-300)
        let controlPointSpaceProbeToYellowStar = SCNVector3(-500,-70,-400)
        
        // Stars erzeugen und an Größe von Probe anpassen
        //Versuch createColorfullStars(position: SCNVector3(x: 0, y: -20, z: 120))
        starRedNode.position = SCNVector3(x: 0, y: -20, z: 120)
        starGreenNode.position = SCNVector3(x: 0, y: -20, z: 120)
        starYellowNode.position = SCNVector3(x: 0, y: -20, z: 120)
        
        // Die Beleuchtung der Scene und Nodes
        lightNode.light?.intensity = 500
        lightNode.position = SCNVector3(x:0, y:100, z:200)
        
// Augen schließen (SpaceProbe)
        let moveTopNodeDown = SCNAction.move(by: SCNVector3(0, -3.8, 0), duration: 0.2)
        let moveBottomNodeUp = SCNAction.move(by: SCNVector3(0, 3.8, 0), duration: 0.2)
        
// Probe kriegt einen Schreck
        let moveTopNodeUp = SCNAction.move(by: SCNVector3(0, 2.0, 0), duration: 0.2)
        let moveBottomNodeDown = SCNAction.move(by: SCNVector3(0, -2.0, 0), duration: 0.2)
        
// Probe blinzelt
        let moveTopNodeForSleepyEye = SCNAction.move(by: SCNVector3(0, 0.8, 0), duration: 0.5)
        moveTopNodeForSleepyEye.timingMode = .easeIn
        let moveBottomNodeForSleepyEye = SCNAction.move(by: SCNVector3(0, -0.8, 0), duration: 0.5)
        moveBottomNodeForSleepyEye.timingMode = .easeIn
        
// WarteAktionen
        let waitActionCloseEye = SCNAction.wait(duration: 2.0)
        let waitActionForCloseEye = SCNAction.wait(duration: 8.0)
        let waitActionForEscape = SCNAction.wait(duration: 3.0)

// Sequenzen für TopNode
        animateSpaceProbeTopNodeSequence = SCNAction.sequence([
            waitActionForCloseEye,
            waitActionForCloseEye,
            waitActionForCloseEye,
            waitActionCloseEye,  // 2 Sekunden warten
            moveTopNodeUp,          // 2.0          Augen auseinander
            waitActionCloseEye,     // 2.0 warten
            moveTopNodeDown,        // 0.2          Klappe schließen
            waitActionCloseEye,     // 2.0 warten
            moveTopNodeForSleepyEye,// 0.5          Augen halb aufmachen (blinzeln)
            waitActionCloseEye,     // 2.0 warten
            moveTopNodeForSleepyEye // 0.5          Augen wieder ganz aufmachen
        ])

// Sequenzen für BottomNode
        animateSpaceProbeBottomNodeSequence = SCNAction.sequence([
            waitActionForCloseEye,
            waitActionForCloseEye,
            waitActionForCloseEye,
            waitActionCloseEye,
            moveBottomNodeDown,
            waitActionCloseEye,
            moveBottomNodeUp,
            waitActionCloseEye,
            moveBottomNodeForSleepyEye,
            waitActionCloseEye,
            moveBottomNodeForSleepyEye
        ])

// Ober und Unterteil zufällig rotieren lassen
        rotateObjectRandomly(spaceProbeTopNode)
        rotateObjectRandomly(spaceProbeBottomNode)
        
// Die Stars auch einzeln rotieren lassen
        rotateObjectRandomly(starRedNode)
        rotateObjectRandomly(starGreenNode)
        rotateObjectRandomly(starYellowNode)

// Bewegung von unten nach oben von SpaceProbeParent
        let moveUpAction = SCNAction.move(to: SCNVector3(0, 0, 50), duration: 1.0)
        moveUpAction.timingMode = .easeOut
        // BodyNode rotieren lassen
        let rotateBody = SCNAction.rotateBy(x: 0, y: degreesToRadians(380), z: 0, duration: 8.0)
        rotateBody.timingMode = .easeOut
        let rotateBodyBack = SCNAction.rotateBy(x: 0, y: degreesToRadians(-20), z: 0, duration: 0.2)
        rotateBodyBack.timingMode = .easeIn
        
// Punkte der Flugbahn für die Flucht (Bezier-Kurve) erstellen
        let startPoint = SCNVector3(0, -50, 50)
        let controlPoint = SCNVector3(100, 0, -500)
        let endPoint = SCNVector3(-800, 0, -500)
        // Bezier-Kurve selber erstellen
        let pathPoints = generateBezierPoints(start: startPoint, control: controlPoint, end: endPoint, segments: 50)
        // Erzeugung eines Arrays um die Positionen zu speichern
        var bezierActions: [SCNAction] = []
        for point in pathPoints {
            let moveAction = SCNAction.move(to: point, duration: 0.1)
            bezierActions.append(moveAction)
        }
        // Die Positionen werden an ein SCNAction übergeben
        let bezierSequence = SCNAction.sequence(bezierActions)
        bezierSequence.timingMode = .easeIn
        
// Die drei Stars initialisieren und Endpunkte setzten
        var kissPointRedStar = SCNVector3(10,-50,-400)
        var kissPointGreenStar = SCNVector3(-10,-50,-200)
        var kissPointYellowStar = SCNVector3(0,-50,-100)
        
// Punkte für das Einsammeln für GreenStar
        let pathPointsCollectGreenStar = generateBezierPoints(
                start: startPointSpaceProbe,
                control: controlPointSpaceProbeToGreenStar,
                end: kissPointGreenStar,
                segments: 50)
        
        var bezierActionsCollectGreenStar: [SCNAction] = []
        for point in pathPointsCollectGreenStar {
            let moveAction = SCNAction.move(to: point, duration: 0.1)
            bezierActionsCollectGreenStar.append(moveAction)
        }
        // Die Positionen werden an ein SCNAction übergeben
        let bezierSequenceCollectGreenStar = SCNAction.sequence(bezierActionsCollectGreenStar)
        bezierSequenceCollectGreenStar.timingMode = .easeOut    // Um langsam an den Star zu gelangen
        
// Punkte für das Einsammeln für RedStar
        let pathPointsCollectRedStar = generateBezierPoints(
                start: kissPointGreenStar,
                control: controlPointSpaceProbeToRedStar,
                end: kissPointRedStar,
                segments: 50)
        
        var bezierActionsCollectRedStar: [SCNAction] = []
        for point in pathPointsCollectRedStar {
            let moveAction = SCNAction.move(to: point, duration: 0.1)
            bezierActionsCollectRedStar.append(moveAction)
        }
        // Die Positionen werden an ein SCNAction übergeben
        let bezierSequenceCollectRedStar = SCNAction.sequence(bezierActionsCollectRedStar)
        bezierSequenceCollectRedStar.timingMode = .easeInEaseOut    // Um langsam an den Star zu gelangen
        
// Punkte für das Einsammeln für YellowStar --------------------------------------------------------------
        let pathPointsCollectYellowStar = generateBezierPoints(
                start: kissPointRedStar,
                control: controlPointSpaceProbeToYellowStar,
                end: kissPointYellowStar,
                segments: 50)
        
        var bezierActionsCollectYellowStar: [SCNAction] = []
        for point in pathPointsCollectYellowStar {
            let moveAction = SCNAction.move(to: point, duration: 0.1)
            bezierActionsCollectYellowStar.append(moveAction)
        }
        // Die Positionen werden an ein SCNAction übergeben
        let bezierSequenceCollectYellowStar = SCNAction.sequence(bezierActionsCollectYellowStar)
        bezierSequenceCollectYellowStar.timingMode = .easeInEaseOut    // Um langsam an den Star zu gelangen
        
// Punkte für das direkte Auftauchen vor dem Twinship
        let pathPointsCollectToTwinShip = generateBezierPoints(
                start: kissPointYellowStar,
                control: SCNVector3(0,-70,80),
                end: SCNVector3(0,0,50), // Direkt vor dem TwinShip
                segments: 50)
        
        var bezierActionsCollectToTwinShip: [SCNAction] = []
        for point in pathPointsCollectToTwinShip {
            let moveAction = SCNAction.move(to: point, duration: 0.1)
            bezierActionsCollectToTwinShip.append(moveAction)
        }
        // Die Positionen werden an ein SCNAction übergeben
        let bezierSequenceCollectToTwinShip = SCNAction.sequence(bezierActionsCollectToTwinShip)
        let rotateEyesAndFaceTwinShip = SCNAction.group([bezierSequenceCollectToTwinShip, rotateBody])
        rotateEyesAndFaceTwinShip.timingMode = .easeInEaseOut    // Um langsam an den Star zu gelangen
        
        // Die Stars nach dem erreichen unten an Probe anhängen
        let catchRedStarAction = SCNAction.customAction(duration: 0) { [self] node, time in
            spaceProbeBottomNode.addChildNode(starRedNode)
            starRedNode.position = SCNVector3(0,-20,0)
        }
        let catchGreenStarAction = SCNAction.customAction(duration: 0.5) { [self] node, time in
            spaceProbeBottomNode.addChildNode(starGreenNode)
            starGreenNode.position = SCNVector3(0,-20,0)
        }
        let catchYellowStarAction = SCNAction.customAction(duration: 0) { [self] node, time in
            spaceProbeBottomNode.addChildNode(starYellowNode)
            starYellowNode.position = SCNVector3(0,-20,0)
        }
        let moveStartPointAction = SCNAction.customAction(duration: 0) { [self] node, time in
            spaceProbeParentNode.position = SCNVector3(-500,0,0)
        }
        
        let spaceProbeComeBackAction = SCNAction.move(to: SCNVector3(0,0,0), duration: 5.0)
        spaceProbeComeBackAction.timingMode = .easeOut
        
        let fadeOutSpaceProbeAction = SCNAction.run { [self] node in
            despawnSpaceProbe()
        }
        
        
// Gesamtaktion der ParentNode
        moveSpaceProbeSequence = SCNAction.sequence([
            // Zum GreenStar fliegen
            bezierSequenceCollectGreenStar,
            // GreenStar an Probe anhängen
            catchGreenStarAction,
            // dito für die anderen beiden Stars
            bezierSequenceCollectRedStar,
            catchRedStarAction,
            bezierSequenceCollectYellowStar,
            catchYellowStarAction,
            rotateEyesAndFaceTwinShip,
            // 0.5 Sek - Für Augen erschreckt zurückdrehen nachdem er TwinShip entdeckt hat
            rotateBodyBack,
            // 8.0 Sek - Einfach nur warten für die syncronistion mit der Botton und Top Animation
            waitActionForCloseEye,
            waitActionForEscape,
            // Mit langgezogener Kurve nach links verschwinden
            bezierSequence,
            waitActionForCloseEye, // 8.0
            // Startposition von links nach 0,0,0
            moveStartPointAction,
            spaceProbeComeBackAction,
            // SpaceProbe am Ende der Sequenz dann ausblenden
            fadeOutSpaceProbeAction
        ])

        // Die Stars hängen unter dem Probe
        kissPointRedStar.y -= 30
        kissPointGreenStar.y -= 30
        kissPointYellowStar.y -= 30
        
        // Die drei Stars in die Gegend schmeissen
        let moveActionRedStar = SCNAction.move(to: kissPointRedStar, duration: 7.0)
        let moveActionGreenStar = SCNAction.move(to: kissPointGreenStar, duration: 5.0)
        let moveActionYellowStar = SCNAction.move(to: kissPointYellowStar, duration: 3.0)

        // Die Action für die Stars wird zeitgleich gestartet
        starRedNode.runAction(moveActionRedStar)
        starGreenNode.runAction(moveActionGreenStar)
        starYellowNode.runAction(moveActionYellowStar)
    }

    // MARK: - Animate TwinShip
    
    // Verfolger TwinShip starten und SpaceProbe hinterherfliegen
    func startIntroAnimationForShip() {

        // Startposition setzen und drehen wegen anderer Position wie im Spiel
        twinShipStartNode.position = SCNVector3(0, -10, 150)
        twinShipStartNode.isHidden = false

        setupShipBoost(for: twinShipStartNode, with: TwinShipBoosterConfig.start)

        fireBoost.birthRate = 500 //100
        
        // TwinShip taucht langsam unter der Kamera hervor
        let startPoint = SCNVector3(0, -10, 40)
        let controlPoint = SCNVector3(100, 0, -500)
        let endPoint = SCNVector3(-800, 0, -500)

        let pathPoints = generateBezierPoints(start: startPoint, control: controlPoint, end: endPoint, segments: 50)
        var bezierActions: [SCNAction] = []
        
        for point in pathPoints {
            let moveAction = SCNAction.move(to: point, duration: 0.1)
            bezierActions.append(moveAction)
        }
        
        // Partikel-Anpassungen
        let changeBirthRateActionOn = SCNAction.run { _ in self.fireBoost.birthRate = 1000 }
        let changeBirthRateActionOff = SCNAction.run { _ in self.fireBoost.birthRate = 0 }
        
        // Rotation in die Kurve legen und nach links drehen
        let initialRotation2 = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 1, 1))
        let initialOrientation = twinShipStartNode.simdOrientation
        let rotateAction = SCNAction.customAction(duration: 3.0) { [self] node, elapsedTime in
            let t = Float(elapsedTime / 3.0)  // Normalisierte Zeit (0 bis 1)
            let easeInT = t * t // Quadratische Ease-In-Kurve
            let interpolatedRotation = simd_slerp(initialOrientation, initialRotation2, easeInT)
            twinShipStartNode.simdOrientation = interpolatedRotation
        }
        
        let waitForOnStage = SCNAction.wait(duration: 37.0)
        let waitForOneSeconds = SCNAction.wait(duration: 0.2)
        let startSlowlyToMoveAction = SCNAction.move(to: SCNVector3(0, -10, 40), duration: 5.0)
        let bezierSequence = SCNAction.sequence(bezierActions)
        let bezierSequenceHelper = SCNAction.sequence([waitForOneSeconds, rotateAction])
        let bezierSequenceAndRotation = SCNAction.group([
                                     bezierSequence,
                                     bezierSequenceHelper])
        // Für mehr realität langsam beschleunigen
        bezierSequenceAndRotation.timingMode = .easeIn
        
        moveTwinShipSequence = SCNAction.sequence([
                    waitForOnStage, // 37 Sekunden warten
                    startSlowlyToMoveAction, // Langsam wegbewegen
                    changeBirthRateActionOn, // Boost verstärken
                    bezierSequenceAndRotation,
                    changeBirthRateActionOff
                  ])
    }


    func switchToOrthographic(cameraNode: SCNNode, duration: TimeInterval) {
        guard let camera = cameraNode.camera else { return }
        
        DispatchQueue.main.async {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = duration
            
            // Animation: Perspektive sanft reduzieren
            camera.fieldOfView = 0.0
            
            // Aktivieren der orthografischen Ansicht
            SCNTransaction.completionBlock = {
                camera.usesOrthographicProjection = true
                camera.zNear = 0.1
                camera.zFar = 600
                camera.fieldOfView = 30 //60.0 // Setzt das FOV zurück für den nächsten Wechsel
            }
            
            // Orthografischer Maßstab erhöhen
            camera.orthographicScale = DeviceConfig.layout.orthographicScale //scnView.bounds.width/9 // iPhone = 95,6 / iPad = 137,6
            
            SCNTransaction.commit()
        }
    }

    func switchToPerspective(cameraNode: SCNNode, duration: TimeInterval) {
        guard let camera = cameraNode.camera else { return }

        DispatchQueue.main.async {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = duration

            // Orthografische Ansicht deaktivieren (vor dem Animieren)
            camera.usesOrthographicProjection = false

            // Animierte Rückkehr zur Perspektive
            camera.fieldOfView = 60.0 // Standard-FOV (anpassbar)

            SCNTransaction.completionBlock = {
                camera.zNear = 0.1
                camera.zFar = 1000
            }

            SCNTransaction.commit()
        }
    }

    
// Hilfsfunktion: Punkte auf einem Bezier-Pfad berechnen
    private func generateBezierPoints(start: SCNVector3, control: SCNVector3, end: SCNVector3, segments: Int) -> [SCNVector3] {
        var points: [SCNVector3] = []
        for i in 0...segments {
            let t = Float(i) / Float(segments)
            let x = pow(1 - t, 2) * start.x + 2 * (1 - t) * t * control.x + pow(t, 2) * end.x
            let y = pow(1 - t, 2) * start.y + 2 * (1 - t) * t * control.y + pow(t, 2) * end.y
            let z = pow(1 - t, 2) * start.z + 2 * (1 - t) * t * control.z + pow(t, 2) * end.z
            points.append(SCNVector3(x, y, z))
           
        }
        return points
    }

    // Radiant in Grad umwandeln (für bessere Lesbarkeit in den SCNAction)
    @inline(__always)   // Dann wird die Zahl vom Compiler berechnet (Inlining)
    func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees * CGFloat.pi / 180
    }

    //MARK: - Bonusround
    
    // Animation vom Level zur Bonusrunde
    func animateTwinShipForBonusRound() {
        slowDownStars = true // Sterne langsam abbremsen
        
        let base = asteroidStartDelay
        let level = Double(LevelManager.shared.levelCount)

        let moveDistance: Float = 500   // Endposition auf der x-Achse
        let duration: TimeInterval = 6.0 // Gesamtdauer des auslaufens mit wedeln
        let initialYPosition = twinShipNode.position.y
        
        // TwinShip von links nach rechts auslaufen lassen
        let moveAction = SCNAction.move(to: SCNVector3(moveDistance, initialYPosition, 0), duration: duration)
        moveAction.timingMode = .easeIn  // Weicher Start
                
        // „Winken“ um die X-Achse (zweimal 90° hin und her)
        let wiggleAngle: CGFloat = (.pi / 2) // 90 Grad
        let wiggleDuration: TimeInterval = duration / 8  // Zwei Zyklen in der Hälfte der Zeit
        let wiggleRightStart = SCNAction.rotateBy(x: (-wiggleAngle / 2),
                                                  y: 0,
                                                  z: 0, duration: wiggleDuration)
        wiggleRightStart.timingMode = .easeOut
        let wiggleRight = SCNAction.rotateBy(x: -wiggleAngle,
                                             y: 0,
                                             z: 0, duration: wiggleDuration)
        wiggleRight.timingMode = .easeInEaseOut
        let wiggleLeftEnd = SCNAction.rotateBy(x: (wiggleAngle / 2),
                                               y: 0,
                                               z: 0, duration: wiggleDuration)
        wiggleLeftEnd.timingMode = .easeIn
        let wiggleLeft = SCNAction.rotateBy(x: wiggleAngle,
                                            y: 0,
                                            z: 0, duration: wiggleDuration)
        wiggleLeft.timingMode = .easeInEaseOut
        
        // Sterne langsam ausblenden
        let fadeOutStars = SCNAction.run { [self] node in
            for index in 0..<100 {
                pointNode[index].runAction(SCNAction.fadeOut(duration: 3))
            }
        }
        
        //FireBoost langsam ausblenden
        let fadeOutFireBoost = SCNAction.customAction(duration: 2.0) { [self] node, elapsedTime in
            let progress = elapsedTime / 1.0
            fireBoost.particleColor = UIColor.red.withAlphaComponent(1.0 - CGFloat(progress))
        }
        // Twinship in nach vorne schauend ausrichten
        let rotateToRootTwinShip = SCNAction.run { [self] node in
            twinShipNode.simdWorldOrientation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0))
        }
        
        // FireBoost starten
        let stopFireBoost = SCNAction.run { [self] node in
            twinShipNode.position = parkPositionOfTwinShip
            fireBoost.birthRate = 0
        }
        
        // Deaktiviere Orthografische Ansicht
        let switchToPerspectiveAction = SCNAction.run { [self] node in
            camera.usesOrthographicProjection = false
            camera.fieldOfView = 90.0 //Versuch
        }
        
        // Sterne nun kreisförmig von vorne kommen lassen
        let circleStarPosition = SCNAction.run { [self] node in
            for index in 0..<100 {
                let radius: Float = 200  // Original - Durchmesser 200 → Radius 100
                let angle = Float.random(in: 0...(2 * .pi))  // Zufallswinkel in Bogenmaß
                let z = cos(angle) * radius
                let y = sin(angle) * radius
                // X-Werte beibehalten (in die Tiefe)
                let pointNodePositionX = pointNode[index].position.x
                pointNode[index].position = SCNVector3(pointNodePositionX, y, z)
                pointNode[index].removeFromParentNode()
                twinShipNode.addChildNode(pointNode[index])
            }
        }

        // TwinShip/Kamera/Licht/FireBoost neu setzen - Sternbeschleunigung starten
        let setNewNodePosition = SCNAction.run { [self] node in
            twinShipBonusNode.position = SCNVector3(-100, -50, 0)   // Linke Seite unter Kamera kommend
            cameraNode.position = SCNVector3(-100, 0, 0)            // Linke Seite von Null Ebene Kommend
            cameraNode.look(at: SCNVector3(0, 0, 0))                // Zu den Anfangspunkt der Asteroiden schauen
            lightNode.position = SCNVector3(x: -100, y: 50, z: 0)
            fireBoost.birthRate = 1000
            fireBoost.particleColor = UIColor.red.withAlphaComponent(1.0)
            accelerateStars = true
        }

        // TwinShip einlaufen lassen
        let moveEndPosition = SCNAction.move(to: SCNVector3(0, -50, 0), duration: duration)
        moveEndPosition.timingMode = .easeOut
        
        // Sterne langsam einblenden
        let fadeInStars = SCNAction.run { [self] node in
            for index in 0..<100 {
                pointNode[index].runAction(SCNAction.fadeIn(duration: 3))
            }
        }
        
        // Zum Schluss die Variablen für Bonus Round setzten
        let setNewStatusVariables = SCNAction.run { [self] node in
            isGamePaused = false
            bonusRoundIsActive = true
            // Enemies und Asteroids wieder starten
            cameraNode.camera?.zNear = 10 // Nahe Clipping-Ebene (muss > 0 sein)
            cameraNode.camera?.zFar = 6000
            // Da jetzt Richtung X+ geflogen wird
            // FIXME: Für LevelRunde wieder auf 300 setzten
            asteroidStartPositionX = 2000 // Startposition ganz Tief im All
            // Bonusrunde aktivieren (muss im Main-Thread laufen!)
            DispatchQueue.main.async { [self] in
                showOverlay()   // Steuerkreuz usw. einblenden
                animateCollisionDisplayWithScale()
            }
            
            for asteroid in asteroidNode.prefix(20) {
                //setAsteroidToStart()
                asteroid.opacity = 0.0
                // Und wieder einblenden
                asteroid.runAction(SCNAction.fadeIn(duration: 2))
            }
            // Neue Asteroiden wieder öfters starten
            //asteroidStartDelay = asteroidStartDelay / Double(LevelManager.shared.levelCount) * 10
            asteroidMaxNumberOnScreen = 100 // Hier kommt die volle Ballung
            asteroidStartDelay = max(0.2, base / pow(level, 1.3))
            startTimerAsteroid()
        }
        
        // 3 Sekunden warten
        let waitDurationThree = SCNAction.wait(duration: 3.0)

        // Shield von TwinShip verkleinern
        let scaleDownShield = SCNAction.scale(to: 0.1, duration: 2.0)
        scaleDownShield.timingMode = .easeIn
        shieldNode.runAction(scaleDownShield)
        
        
        // TwinShip winkt zum Abschied und fliegt nach rechts
        let wiggleSequence = SCNAction.sequence([wiggleRightStart,
                                                 wiggleLeft,
                                                 wiggleRight,
                                                 wiggleLeftEnd,
                                                 fadeOutStars,          // 3 Sekunden
                                                 fadeOutFireBoost,      // 2 Sekunden
                                                 waitDurationThree,     // 3 Sekunden
                                                 rotateToRootTwinShip,  // Sofort
                                                 stopFireBoost,         // sofort
                                                ])
        
        //  Abflug und Flügelwedeln in einem
        let sidewaysFlapTwinShipAction = SCNAction.group([moveAction, wiggleSequence,])
        sidewaysFlapTwinShipAction.timingMode = .easeIn
        twinShipNode.runAction(sidewaysFlapTwinShipAction) { [self] in
            
            setupShipBoost(for: twinShipBonusNode, with: TwinShipBoosterConfig.bonus)
        }
        
        // Sechs Sekunden warten
        let waitDurationSix = SCNAction.wait(duration: 6.0)
        //In Perspektive einfliegen, Stars vorbereiten
        let wiggleBonusRoundSequence = SCNAction.sequence([switchToPerspectiveAction,
                                                           waitDurationThree,
                                                           circleStarPosition,
                                                           waitDurationThree,
                                                           setNewNodePosition,
                                                           moveEndPosition,
                                                           fadeInStars,
                                                           setNewStatusVariables
                                                          ])

        let combinedActionTwinShipBonusRound = SCNAction.sequence([waitDurationSix, wiggleBonusRoundSequence])
        
        twinShipBonusNode.runAction(combinedActionTwinShipBonusRound)
    }
}

