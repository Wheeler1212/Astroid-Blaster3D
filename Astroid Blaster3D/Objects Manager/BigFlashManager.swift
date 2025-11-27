//
//  BigFlashManager.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 14.04.25.
//

import SceneKit
import UIKit

extension GameViewController {

    
    func createBigFlash() {
        
        // SCN-Zylinder für Parentnode und PyhsicsBody
        let cylinder = SCNCylinder(radius: 100, height: 100.0)
        bigFlashParent = SCNNode(geometry: cylinder)
        
        // Transparenz für das ParentNode. Geht nicht anders wegen Vererbung
        bigFlashParent.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        bigFlashParent.scale = SCNVector3(0.02, 0.02, 0.02)//SCNVector3Zero

        bigFlashParent.rotation = SCNVector4(1, 0, 0, CGFloat.pi / 2)
        bigFlashParent.position = parkPositionOfBigFlash
        bigFlashParent.name = "BigFlash"
        
        // Kreis (Oberseite) für BigFlash-Animation
        let geometry = SCNCylinder(radius: 100, height: 5)
        
        material = SCNMaterial()
        geometry.materials = [material]
        bigFlashNode = SCNNode(geometry: geometry)
        bigFlashNode.scale = SCNVector3(4, 4, 4)
        bigFlashNode.rotation = SCNVector4(1, 0, 0, -CGFloat.pi / 2)
        bigFlashParent.worldPosition = parkPositionOfBigFlash
        bigFlashParent.addChildNode(bigFlashNode)
        bigFlashParent.isHidden = true
        
        bigFlashParent.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        bigFlashParent.physicsBody?.isAffectedByGravity = false
        bigFlashParent.physicsBody?.velocityFactor = SCNVector3(x: 1, y: 1, z: 0)
        bigFlashParent.physicsBody?.categoryBitMask = combineBitMasks([.bigFlash])
        bigFlashParent.physicsBody?.collisionBitMask = combineBitMasks([.none])
        bigFlashParent.physicsBody?.contactTestBitMask = combineBitMasks([.asteroid])
        
        bigFlashNode.rotation = SCNVector4(0, 1, 0, Float.pi / 2)
        
        gameScene.rootNode.addChildNode(bigFlashParent)
        
        // Das schwarze Loch hinzufügen
        shieldBigFlashNode = setupShield(
            at: SCNVector3(0, 0, 0),
            color: .black)

            shieldBigFlashNode.scale = SCNVector3(5.0, 5.0, 5.0)
            bigFlashParent.addChildNode(shieldBigFlashNode)
    }

    func animateBigFlash() {
        
        bigFlashParent.isHidden = false
        bigFlashParent.position = SCNVector3(0, 0, 0) // War 50
        bigFlashParent.opacity = 1
        //Zur Max-Größe hochscalieren (0.2)
        let scaleUpAction = SCNAction.scale(to: 0.2, duration: 25.0)
        scaleUpAction.timingMode = .easeIn
        
        bigFlashParent.runAction(scaleUpAction) {
            self.bigFlashState = .moving
        }
        
        // Werte für DispatchQueue UIImage
        var currentFrame = 0
        let zPosition = Float(20)
        let totalFrames = BigFlash.count
        let frameDuration: TimeInterval = 0.05 // Dauer eines Frames (20 FPS)

        // Gleich beim Start setzen, bevor Timer übernimmt
        material.diffuse.contents = BigFlash[0]

        
        // Starte Timer für die Bilderanimation auf der Box
        DispatchQueue.main.async { [self] in
            timerStartBigFlash = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { [self] timer in
                currentFrame = (currentFrame + 1) % totalFrames
                // Setze die aktuelle Textur auf das Material
                material.diffuse.contents = BigFlash[currentFrame]
            }
        }
        
        // BigFlash zufällig auf dem Bildschirm bewegen
        let durationRange: ClosedRange<TimeInterval> = 3.0...6.0
        moveObjectRandomly(bigFlashParent,
                           moveObjectRangeX,
                           moveObjectRangeY,
                           zPosition,
                           durationRange)

        rotateObjectRandomly(bigFlashNode)
    }
    
    func despawnBigFlash() {
        //#14 bigFlashIsOnScreen = false
        bigFlashState = .scaleDown
        
        let scaleDownAction = SCNAction.scale(to: 0.01, duration: 0.5)
        bigFlashParent.runAction(scaleDownAction) { [weak self] in
            guard let self = self else { return }
            
            bigFlashParent.removeAllAnimations()
            bigFlashParent.removeAllActions()
            bigFlashParent.worldPosition = parkPositionOfBigFlash
            //#14bigFlashParent.physicsBody?.velocity = SCNVector3(0.02, 0.02, 0.02)
            bigFlashParent.scale = SCNVector3(0.02, 0.02, 0.02)
            timerStartBigFlash?.invalidate()
            timerStartBigFlash = nil

            bigFlashState = .idle
            currentEnemy = .none    //Neuen Enemy freigeben
            scheduleNextEnemy()
            }
    }
   
    // Vom Renderer bei "bigFlashIsOnScreen = true" gestartet
    func blinkBigFlash() {
  
        if increasingBigFlash {
            blinkBigFlashValue += 0.1
            if blinkBigFlashValue  > 0.9 {
                increasingBigFlash = false // Richtung ändern
            }
        } else {
            blinkBigFlashValue -= 0.1
            if blinkBigFlashValue < 0.2 {
                increasingBigFlash = true // Richtung ändern
            }
        }
        bigFlashParent.opacity = blinkBigFlashValue
    }
}
