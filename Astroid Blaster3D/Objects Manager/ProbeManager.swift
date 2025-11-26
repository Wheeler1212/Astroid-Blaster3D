//
//  ProbeManager.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 14.04.25.
//

import SceneKit

extension GameViewController {
    
    
    // MARK: Timer CollorfulStars
    func startTimerForStarsCleanUp() {
        if timerOnScreenColorfullStars != nil {
            timerOnScreenColorfullStars?.invalidate()
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.timerOnScreenColorfullStars = Timer.scheduledTimer(
                timeInterval: self.colorfullStarsOnScreenTime,
                target: self,
                selector: #selector(self.fadeOutColorfullStars),
                userInfo: nil,
                repeats: false
            )
        }
    }

    // SpaceProbe erzeugen - Opacity = 0.0 auf ParkPosition
    func createSpaceProbe() {
        spaceProbeBodyNode.name = "SpaceProbeBody"
        spaceProbeTopNode.name = "SpaceProbeTop"
        spaceProbeBottomNode.name = "SpaceProbeBottom"
        
        // Parent-Node vorbereiten
        spaceProbeParentNode = SCNNode()
        spaceProbeParentNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
        spaceProbeParentNode.scale = SCNVector3(x: 1.5, y: 1.5, z: 1.5)
        spaceProbeParentNode.opacity = 0.0
        spaceProbeParentNode.name = "SpaceProbeParent"
        
        // Child-Nodes hinzufügen
        spaceProbeParentNode.addChildNode(spaceProbeBodyNode)
        spaceProbeParentNode.addChildNode(spaceProbeTopNode)
        spaceProbeParentNode.addChildNode(spaceProbeBottomNode)
        
        // PhysicsBody an den echten Parent hängen
        spaceProbeParentNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        spaceProbeParentNode.physicsBody?.isAffectedByGravity = false
        spaceProbeParentNode.physicsBody?.categoryBitMask = combineBitMasks([.spaceProbe])
        spaceProbeParentNode.physicsBody?.collisionBitMask = combineBitMasks([.none])
        spaceProbeParentNode.physicsBody?.contactTestBitMask = combineBitMasks([.fire])
        
        // Jetzt Node zur Szene hinzufügen
        gameScene.rootNode.addChildNode(spaceProbeParentNode)
    }
    
    // --- Bunte Sterne aus der guten alten Zeit -----
    func createColorfullStars(position: SCNVector3) {
        let configs: [(SCNNode, String, SCNVector3)] = [
            (starRedNode, "RedStar", SCNVector3(2, 2, 2)),
            (starGreenNode, "GreenStar", SCNVector3(3, 3, 3)),
            (starYellowNode, "YellowStar", SCNVector3(2.5, 2.5, 2.5))
        ]
        
        for (node, name, scale) in configs {
            configureStar(node: node, name: name, position: position, scale: scale)
            gameScene.rootNode.addChildNode(node)
        }
    }

    private func configureStar(node: SCNNode, name: String, position: SCNVector3, scale: SCNVector3) {
        node.name = name
        node.scale = scale
        node.position = position

        let body = SCNPhysicsBody(type: .kinematic, shape: nil)
        body.isAffectedByGravity = false
        body.velocityFactor = SCNVector3(x: 1, y: 1, z: 0)
        body.categoryBitMask = combineBitMasks([.colorfullStars])
        body.collisionBitMask = combineBitMasks([.none])
        body.contactTestBitMask = combineBitMasks([.twinShip])
        
        node.physicsBody = body
    }

    func spawnSpaceProbe() {
//#        guard !spaceProbeIsOnScreen else { return }
//        spaceProbeIsOnScreen = true
        spaceProbeState = .fadeIn
        SoundManager.shared.playSpaceProbe()

        spaceProbeParentNode.position = SCNVector3(x: 0, y: 0, z: 0)
        spaceProbeParentNode.runAction(.fadeIn(duration: 1.0)) { [weak self] in
            guard let self = self else { return }
            
            spaceProbeState = .moving   //#
            let durationRange: ClosedRange<TimeInterval> = 3.0...6.0
            self.moveObjectRandomly(spaceProbeParentNode,
                                  moveObjectRangeX,
                                  moveObjectRangeY,
                                  0,
                                  durationRange)
            
            // Unterschiedliche Bewegungen für die Teile
            let rotateActions = SCNAction.group([
                createRotateAction(for: spaceProbeBottomNode),
                createRotateAction(for: spaceProbeBodyNode),
                createRotateAction(for: spaceProbeTopNode)
            ])
            spaceProbeParentNode.runAction(rotateActions)
            
            //Beim ersten Abwurf
            if starsCounter == 0 {
                setupPhysicsBodies()
            }
        }
    }
    
    private func createRotateAction(for node: SCNNode) -> SCNAction {
        return SCNAction.run { [weak self] _ in
            guard let self = self else { return }
            self.rotateObjectRandomly(node)
        }
    }
    
    private func setupPhysicsBodies() {
        [spaceProbeTopNode, spaceProbeBodyNode, spaceProbeBottomNode].forEach {
            $0.physicsBody = SCNPhysicsBody.kinematic()
        }
    }
    
    func probeSurprisedByHit() {
        guard !raiseAndLowerAgainSpaceProbe else { return }
        
        //Bei doppeltem Treffer nur einmal reagieren
        raiseAndLowerAgainSpaceProbe = true
        spaceProbeState = .isHit
        
        // Vorher Originalpositionen speichern
        let originalPositions = (
            top: spaceProbeTopNode.position,
            bottom: spaceProbeBottomNode.position
        )
        // Lift-Aktionen vorbereiten
        let (topActions, bottomActions) = createLiftActions(
            originalTop: originalPositions.top,
            originalBottom: originalPositions.bottom
        )
        // Den Body kurz ausblenden und sofort wieder einblenden
        let fadeSequence = SCNAction.sequence([
            .fadeOpacity(to: 0.2, duration: 1),
            .fadeOpacity(to: 1.0, duration: 1)
        ])
        
        // Alle alten rotate- und move- Aktionen stoppen
        [spaceProbeParentNode, spaceProbeTopNode,
         spaceProbeBodyNode, spaceProbeBottomNode].forEach { $0.removeAllActions() }
        
        // Aktionen ausführen
        spaceProbeBodyNode.runAction(fadeSequence)      //Aus- und einblenden
        spaceProbeTopNode.runAction(topActions)         //Oberteil hochheben
        spaceProbeBottomNode.runAction(bottomActions)   //Unterteil nach unten liften
            { [weak self] in
                //Oben gestoppte Actions wieder starten
                self?.rotateProbeAgainAfterRaiseAndLower()
                self?.attachStars()
            }
    }
    
    private func attachStars() {

        colorfullStarsState = .starsOn
        //Position vom Probe lesen
        let position = SCNVector3(
            x: spaceProbeBodyNode.position.x,
            y: spaceProbeBodyNode.position.y - 20,
            z: spaceProbeBodyNode.position.z
        )
        //Die drei Sterne an den BottomNode hängen
        [starRedNode, starGreenNode, starYellowNode].forEach {
            $0.position = position
            spaceProbeBottomNode.addChildNode($0)
        }
    }

    private func rotateProbeAgainAfterRaiseAndLower() {
        
        // Zufällige Bewegung der Parentnode starten
        let durationRange: ClosedRange<TimeInterval> = 3.0...6.0
        moveObjectRandomly(spaceProbeParentNode,
                          moveObjectRangeX,
                          moveObjectRangeY,
                          0,
                          durationRange)
        
        // Rotation der Einzelteile starten
        [spaceProbeBottomNode, spaceProbeTopNode, spaceProbeBodyNode].forEach {
            rotateObjectRandomly($0)
        }
        
        starsCounter = 3    //Drei Sterne angehängt
        colorfullStarsState = .starsOn
        raiseAndLowerAgainSpaceProbe = false
    }

    //--------------------------------------------------------------------------------------
    @objc func fadeOutColorfullStars() {
        
        let fadeOut = SCNAction.fadeOut(duration: 1.0)
        let stars = [starRedNode, starGreenNode, starYellowNode].compactMap { $0 }
        
        // Sterne ausblenden
        stars.forEach { star in
            star.runAction(fadeOut)
        }
        
        // Nach dem Ausblenden aufräumen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Sterne zurück in die Parkposition
            stars.forEach {
                resetStar($0, to: self.parkPositionOfColorfullStars)
            }
            //Kein doppelter Aufruf -> despawnSpaceProbe()
            if colorfullStarsState != .starsOn {
                currentEnemy = .none
                scheduleNextEnemy(.spaceProbe)
            }
            
            colorfullStarsState = .idle
            starsCounter = 0    //Keine Sterne angehängt
            raiseAndLowerAgainSpaceProbe = false    //Reset
            
        }
        if timerOnScreenColorfullStars != nil {
            timerOnScreenColorfullStars?.invalidate()
        }
    }
    
    private func createLiftActions(originalTop: SCNVector3, originalBottom: SCNVector3)
    -> (SCNAction, SCNAction) {
        let rotate = SCNAction.rotate(by: .pi * 2, around: SCNVector3(0, 1, 0), duration: 1)
        
        let topActions = SCNAction.group([
            rotate,
            .sequence([
                .move(by: SCNVector3(0, 10, 0), duration: 0.5),
                .move(to: originalTop, duration: 0.5)
            ])
        ])
        
        let bottomActions = SCNAction.group([
            rotate,
            .sequence([
                .move(by: SCNVector3(0, -10, 0), duration: 0.5),
                .move(to: originalBottom, duration: 0.5)
            ])
        ])
        
        return (topActions, bottomActions)
    }
    
    
    func performStarRelease() {
        guard colorfullStarsState != .starsOff else { return }
        //Stars wurden abgeworfen
        spaceProbeState = .moving //starsOff  //#17 .moving
        colorfullStarsState = .starsOff
        
        // Sterne vorbereiten (mit compactMap für Optionals)
        let stars = [starRedNode, starGreenNode, starYellowNode].compactMap { $0 }
        guard !stars.isEmpty else {
            print("Warning: No stars available to release")
            return
        }

        let durations: [ClosedRange<TimeInterval>] = [
            15.0...20.0,
            10.0...15.0,
            5.0...10.0
        ]
        
        // Weltposition und -orientierung vom ersten Stern holen (sicher)
        guard let firstStar = stars.first else { return }
        let worldPosition = firstStar.worldPosition
        let worldOrientation = firstStar.worldOrientation
        
        // Sterne freigeben (sicherer Zugriff)
        stars.forEach { star in
            star.removeAllActions()
            gameScene.rootNode.addChildNode(star)
            star.worldPosition = worldPosition
            star.worldOrientation = worldOrientation
        }

        for (index, star) in stars.enumerated() {
            guard durations.indices.contains(index) else { continue }
            
            moveObjectRandomly(star,
                               moveObjectRangeX,
                               moveObjectRangeY,
                               0,
                               durations[index])
            rotateObjectRandomly(star)
        }

        updateHUD()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
            despawnSpaceProbe()
        }
        //Timer für Colorfull Stars
        startTimerForStarsCleanUp()
    }
    
    func handleStarCollision(_ star: SCNNode) {
        guard let name = star.name else { return }
        
        switch true {
            //Ein Leben wird abgezogen
        case name.hasPrefix("Red"):
            removeStarOnCollision(for: starRedNode)
            playerLives -= 1
            //Ein Leben gewonnen
        case name.hasPrefix("Green"):
            removeStarOnCollision(for: starGreenNode)
            playerLives += 1
            //Doppelfeuer ein oder aus
        case name.hasPrefix("Yellow"):
            removeStarOnCollision(for: starYellowNode)
            fireType.toggle()
            //fireType = .single oder .double
            
        default:
            print("Unbekannter Star-Typ: \(name)")
        }
    }

    func removeStarOnCollision(for node: SCNNode) {
        node.opacity = 0.0
        node.removeAllActions()
        node.removeFromParentNode()
        //StarCounter herunterzählen
        starsCounter -= 1
        if starsCounter == 0 {
            colorfullStarsState = .idle
        }
    }
    
    // SpaceProbe ausblenden und löschen
    func despawnSpaceProbe() {
         
        spaceProbeState = .fadeOut
        
        if colorfullStarsState == .starsOn {
            fadeOutColorfullStars()
        }
        
        let fadeOut = SCNAction.fadeOut(duration: 1.0)
        spaceProbeParentNode.runAction(fadeOut) { [self] in
            // SpaceProbe-Aktionen stoppen
            spaceProbeParentNode.removeAllActions()
            spaceProbeBottomNode.removeAllActions()
            spaceProbeBodyNode.removeAllActions()
            spaceProbeTopNode.removeAllActions()
            
            // SpaceProbe hat den Screen verlassen
            spaceProbeParentNode.position = parkPositionOfSpaceProbe
            spaceProbeIsOnScreen = false
            
            spaceProbeState = .idle
            currentEnemy = .none    //# Neuen Enemy freigeben
            scheduleNextEnemy(.spaceProbe)
        }
    }
}
