//
//  BallWallManager.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 14.04.25.
//

//TODO:
//Shield ausblenden von Invader wenn BallWall kommt

import SceneKit
import UIKit


extension GameViewController {
    
    
// MARK: Timer BallWall
    func startTimerBallWall() {
        if timerBallWall != nil {
            timerBallWall?.invalidate()
        }
        DispatchQueue.main.async { [self] in
            timerBallWall = Timer.scheduledTimer(
                timeInterval: ballWallStartDelay,
                target: self,
                selector: #selector(self.startBallWall),
                userInfo: nil,
                repeats: false)
        }
    }
    
    // Animationstimer zwei Kugeln pro Sekunde
    func startTimerAnimateBallWall() {
        if timerAnimateBallWall != nil {
            timerAnimateBallWall?.invalidate()
        }
        DispatchQueue.main.async { [self] in
            timerAnimateBallWall = Timer.scheduledTimer(
                timeInterval: 0.5,
                target: self,
                selector: #selector(self.animateBallWall),
                userInfo: nil,
                repeats: true)
        }
    }
    
    // MARK: - BallWall
    // Blaue Kugel für die obere BallWall erzeugen
    func createBallWallUp(positon: SCNVector3,    // Position der Kugel
                          size: CGFloat,          // Größe
                          color: UIColor)   {     // Farbe als UIColor.init(red: 0.1, green: 0.1, blue: 1, alpha: 0.8)
        
        let ballGeometry = SCNSphere(radius: size)
        ballGeometry.firstMaterial?.diffuse.contents = color
        ballUp = SCNNode(geometry: ballGeometry)
        ballUp.name = "BallWall"
        ballUp.isHidden = false
        ballUp.position = positon
        
        ballUp.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        ballUp.physicsBody?.categoryBitMask = combineBitMasks([.ballWall])
        ballUp.physicsBody?.collisionBitMask = combineBitMasks([.none])
        ballUp.physicsBody?.contactTestBitMask = combineBitMasks([.fire, .twinShip])
        
        gameScene.rootNode.addChildNode(ballUp)
        ballWallNodeUp.append(ballUp)
    }

    // Blaue Kugel für die untere BallWall erzeugen
    func createBallWallDown(positon: SCNVector3,    // Position der Kugel
                            size: CGFloat,          // Größe
                            color: UIColor)   {     // Farbe als UIColor.init(red: 0.1, green: 0.1, blue: 1, alpha: 0.8)
        
        let ballGeometry = SCNSphere(radius: size)
        ballGeometry.firstMaterial?.diffuse.contents = color
        ballDown = SCNNode(geometry: ballGeometry)
        ballDown.name = "BallWall"
        ballDown.isHidden = false
        ballDown.position = positon
        
        ballDown.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        ballDown.physicsBody?.categoryBitMask = combineBitMasks([.ballWall])
        ballDown.physicsBody?.collisionBitMask = combineBitMasks([.none])
        ballDown.physicsBody?.contactTestBitMask = combineBitMasks([.fire, .twinShip])
        
        gameScene.rootNode.addChildNode(ballDown)
        ballWallNodeDown.append(ballDown)
    }

    // Gelbe Kugel für die Türe BallWall erzeugen
    func createBallWallDoor(positon: SCNVector3,    // Position der Kugel
                            size: CGFloat,          // Größe
                            color: UIColor)   {     // Farbe als UIColor.init(red: 0.1, green: 0.1, blue: 1, alpha: 0.8)
        
        let ballGeometry = SCNSphere(radius: size)
        ballGeometry.firstMaterial?.diffuse.contents = color
        ballDoor = SCNNode(geometry: ballGeometry)
        ballDoor.name = "BallWallDoor"
        ballDoor.isHidden = false
        ballDoor.position = positon
        
        ballDoor.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        ballDoor.physicsBody?.categoryBitMask = combineBitMasks([.ballWall])
        ballDoor.physicsBody?.collisionBitMask = combineBitMasks([.none])
        ballDoor.physicsBody?.contactTestBitMask = combineBitMasks([.fire, .twinShip]) //FireCategory + TwinShipCategory
        
        gameScene.rootNode.addChildNode(ballDoor)
        ballWallNodeDoor.append(ballDoor)
    }
    
    //MARK: BallWall
        //Vorbereitungen um BallWall zu animieren
    @objc func startBallWall() {
        //currentEnemy wird ausgeblendet dann mit Verzögerung startTimerAnimateBallWall()
        hideCurrentEnemy { [self] in
            ballWallState = .buildUp
            startTimerAnimateBallWall()
        }
    }
    
    //Enemies ausblenden und dann mit Verzögerung BallWall einlaufen lassen
    func hideCurrentEnemy(completion: @escaping () -> Void) {
        switch currentEnemy {
        case .spaceProbe:
            despawnSpaceProbe()
        case .bigFlash:
            despawnBigFlash()
        case .spaceInvader:
            despawnSpaceInvader()
        default:
            break
        }
        
        //currentEnemy = .none
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            completion() // Verzögertes Completion für saubere Übergänge
        }
    }
    
    
    // Durch "startTimerAnimateBallWall()" aufgerufen
    @objc func animateBallWall() {
        guard buildWall else { return }

        ballPositionY -= 10 // Abstand der Bälle in vertikaler Richtung

        if ballPositionY > -DeviceConfig.layout.maxBallPositionY {
            handleBallWallPlacement()
        } else {
            setupBallWallAnimation()
            buildWall = false // BallWall ist gesetzt, keine weiteren Animationen starten
            ballWallState = .moving
            enableCollision()
            //startTimerBallWall() // Warten auf den nächsten BallWall
        }
    }
    
    // Hilfsfunktion für das Platzieren von blauen Bällen
    private func handleBallWallPlacement() {
        SoundManager.shared.playBallWall()

        // Blaue Kugeln setzen (oben und unten)
        createBallWallDown(
            positon: SCNVector3(x: 180, y: ballPositionY, z: 0),
            size: 4,
            color: .blue
        )
        createBallWallUp(
            positon: SCNVector3(x: 180, y: abs(ballPositionY), z: 0),
            size: 4,
            color: .blue
        )
        ballWallColorCounter += 1
    }

    // Hilfsfunktion für die Animation der gelben Türkugel
    private func setupBallWallAnimation() {
        // Die gelbe Kugel für die Tür erstellen
        createBallWallDoor(
            positon: SCNVector3(x: 180, y: -20, z: 0),
            size: 4,
            color: .yellow
        )
        
        // Türanimation erstellen
        let bounceSequence = createBounceSequence()
        ballDoor.runAction(SCNAction.repeatForever(bounceSequence))
        
        // Bewegung der Kugeln nach links anstoßen
        startActionBallWall(nodeArray: ballWallNodeUp)
        startActionBallWall(nodeArray: ballWallNodeDown)
        startActionBallWall(nodeArray: ballWallNodeDoor)
    }

    // Erstellen einer Animation für das Auf- und Abspringen der gelben Kugel
    private func createBounceSequence() -> SCNAction {
        let moveUp = SCNAction.moveBy(x: 0, y: 40, z: 0, duration: 0.5)
        let moveDown = SCNAction.moveBy(x: 0, y: -40, z: 0, duration: 0.5)
        
        let reachedTop = SCNAction.run { _ in
            SoundManager.shared.playBallDoor()
            // Farbverlauf Kugeln aufwärts starten
            self.startColorWave(nodeArray: self.ballWallNodeUp)
        }
        let reachedBottom = SCNAction.run { _ in
            SoundManager.shared.playBallDoor()
            // Farbverlauf Kugeln abwärts starten
            self.startColorWave(nodeArray: self.ballWallNodeDown)
        }
        
        return SCNAction.sequence([moveUp, reachedTop, moveDown, reachedBottom])
    }

    //Funktion, um den Farbverlauf zu starten
    func startColorWave(nodeArray: [SCNNode]) {
        for (index, nodeElement) in nodeArray.enumerated() {
            let delay = Double(index) * 0.1 // Setzt eine Verzögerung für jede Kugel
            
            // Aktion zum Ändern der Farbe auf gelb
            let changeToYellow = SCNAction.run { (node) in
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            }
            
            // Aktion zum Zurücksetzen der Farbe auf blau
            let resetToOriginal = SCNAction.run { (node) in
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            }
            
            // Setze eine Sequenz von Aktionen: Ändern zu gelb -> warten -> zurück zu blau
            let sequence = SCNAction.sequence([
                SCNAction.wait(duration: delay),    // Verzögerung für den Farbwechsel
                changeToYellow,                     // Farbe auf gelb setzen
                SCNAction.wait(duration: 0.1),      // Kurzes Warten, während die Farbe gelb bleibt
                resetToOriginal                     // Zurück zur Originalfarbe (blau)
            ])
            
            // Führe die Aktion für die aktuelle Kugel aus
            nodeElement.runAction(sequence)
        }
    }
    
    // BallWall nach links bewegen
    func startActionBallWall(nodeArray: [SCNNode])   {
        
        // SCNAction moveLeft für ballWallNode
        let moveLeft = SCNAction.moveBy(x: -DeviceConfig.layout.ballWallMoveBorderX, y: 0, z: 0, duration: TimeInterval(20 - levelCount))
        
        for (index, node) in nodeArray.enumerated() {
            moveLeft.timingFunction = { time in     // Für Ease-In-Effekt
                return Float(time * time)
            }
            
            if index == nodeArray.count - 1 {
                // BallWall ist links aus dem Bildschirm
                let runFinishBallWall = SCNAction.run { node in
                    self.finishBallWall(nodeArray: nodeArray)
                }
                let sequence = SCNAction.sequence([moveLeft, runFinishBallWall])
                node.runAction(sequence)
            } else {
                node.runAction(moveLeft)
            }
        }
    }

    func fadeOutBallWall() {
        
        let fadeOut = SCNAction.fadeOut(duration: 1.0)
        
        for node in ballWallNodeUp {
            node.runAction(fadeOut)
            node.removeAllActions()
            node.removeFromParentNode()
        }
        for node in ballWallNodeDown {
            node.runAction(fadeOut)
            node.removeAllActions()
            node.removeFromParentNode()
        }
        for node in ballWallNodeDoor {
            node.runAction(fadeOut)
            node.removeAllActions()
            node.removeFromParentNode()
        }
        
        if ballWallState != .idle {
            ballWallState = .idle   //Nur einmal aufrufen
            currentEnemy = .none
            //Animationstimer löschen
            timerAnimateBallWall?.invalidate()
            timerAnimateBallWall = nil
            buildWall = true
            ballWallColorCounter = 0    //??
            ballPositionY = -20
            startTimerBallWall()    //#Timer Spawn BallWall setzen
        }
    }

    // BallWall ist links aus dem Bildschirm
    func finishBallWall(nodeArray: [SCNNode])   {
        
        for node in nodeArray {
            node.removeAllActions()
            node.removeFromParentNode()
        }
        
        if ballWallState != .idle {
            ballWallState = .idle   //Nur einmal aufrufen
            currentEnemy = .none
            //Animationstimer löschen
            timerAnimateBallWall?.invalidate()
            timerAnimateBallWall = nil
            buildWall = true
            //ballWallColorCounter = 0
            ballPositionY = -20
            ballWallNodeUp.removeAll()
            ballWallNodeDoor.removeAll()
            ballWallNodeDown.removeAll()
            startTimerBallWall()    //#Timer Spawn BallWall setzen
        }
    }
    
    func handleBallWallCollision(_ ballWall: SCNNode) {
        // Beispiel: BallWall-Kollision behandeln
        // Beispielhafte Aktion
        //removeNodeOnCollision(for: ballWall)
    }
    
    func enableCollision() {
        
    }
}
