//
//  Asteroid.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 20.11.25.
//


import SceneKit
import SpriteKit
import AudioToolbox

extension GameViewController {
    
    
    // MARK: Timer Asteroid
    func startTimerAsteroid() {
        if timerAsteroid != nil {
            timerAsteroid?.invalidate()
        }
        DispatchQueue.main.async { [self] in
            timerAsteroid = Timer.scheduledTimer(
                timeInterval: asteroidStartDelay,
                target: self,
                selector: #selector(setAsteroidToStart),
                userInfo: nil,
                repeats: true)
        }
    }
    
    // Kollision Fire mit Asteroid. Erzeugung der Explosionsfragmente
    func fireHitAsteroid(enemyNameOfNode: String, fireNode: SCNNode) {
        
        if !isContactAsteroidCooldownActive { // Taste entprellen
                // *** Abarbeitung des Asteroiden mit Namen nameOfNode
            if let hitAsteroid = asteroidNodeDictionary[enemyNameOfNode] {
                let asteroidScale  = hitAsteroid.scale.x // Scale mitnehmen
                let asteroidPosition = hitAsteroid.presentation.position // Position mitnehmen
                let numberBurstAsteroid = Int(asteroidScale * 10)
                let numberAsteroid = Int(enemyNameOfNode.suffix(4))!
 
                // Explosion erzeugen
                var explosionSize: CGFloat
                // Größe der Explosion ist der Größe des Asteroiden angepasst
                explosionSize = CGFloat(hitAsteroid.scale.x) * 20
                createExplosion(for: hitAsteroid, newSize: explosionSize) // Explosion auf Position von "Fire"
                SoundManager.shared.playRockExplosion() // Sound abspielen
                
                // Ob Groß ob klein zurück zur Parkposition, Bewegungswerte löschen
                moveAsteroidToParkPosition(node: hitAsteroid, parkPosition: parkPositionOfAsteroid)
                
                // Nur bei großen Asteroiden Zähler korrigieren
                if numberAsteroid < offsetNumber {
                    asteroidCountMax -= 1   // Noch verbleibende Asteroiden für das Level
                    asteroidCountActive -= 1     // Ein Asteroid weniger auf dem Schirm
                }

                // Burst Asteroiden werden in kleine Teile gesprengt
                if explosionType == .fragmentation && numberAsteroid < offsetNumber {

                    for burstNodeOfAsteroid in asteroidNode.dropFirst(AsteroidStartValueOfBurstOne).prefix(numberBurstAsteroid) {
                        
                            // Burst-Asteroid auf Position des zerstörten Asteroiden setzten
                        setStartPositionOfBurstAsteroids(burstNodeOfAsteroid: burstNodeOfAsteroid, asteroidPosition: asteroidPosition)

                            // Burst Asteroids in alle Richtungen schleudern
                        applyRandomForceWithRotation(to: burstNodeOfAsteroid, speedRange: 10...50, forceOffsetRange: -5...5)
                        
                            // Nach 5 bis 10 Sekunden ausblenden und auf Parkposition setzen
                        fadeOutActionOfBurstAsteroids(burstNodeOfAsteroid: burstNodeOfAsteroid)
                    }
                    
                    // Verwertung der benutzen Asteroiden
                    if AsteroidStartValueOfBurstOne + numberBurstAsteroid <= asteroidNode.count {AsteroidStartValueOfBurstOne += numberBurstAsteroid
                    } else {
                        AsteroidStartValueOfBurstOne = offsetNumber
                    }
                } else {
                    score += 1000 // Kleiner Asteroid bringt mehr Punkte, zählt aber nicht bei .countMax oder .numberTotal
                }
            }
            // Aktivieren des Cooldowns
            isContactAsteroidCooldownActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Cooldown Zeit
                self.isContactAsteroidCooldownActive = false
            }
        }
    }
    
    private func setStartPositionOfBurstAsteroids(burstNodeOfAsteroid: SCNNode, asteroidPosition: SCNVector3) {
        burstNodeOfAsteroid.position = asteroidPosition
        burstNodeOfAsteroid.isHidden = false
        burstNodeOfAsteroid.opacity = 1.0
        burstNodeOfAsteroid.physicsBody?.velocity = SCNVector3(x: Float.random(in: -50 ... -10),y: 0,z: 0)
        burstNodeOfAsteroid.physicsBody?.categoryBitMask = combineBitMasks([.asteroid])
    }
    
    private func fadeOutActionOfBurstAsteroids(burstNodeOfAsteroid: SCNNode) {
        // Generiere eine zufällige Schwebezeit zwischen 5 und 10 Sekunden
        let randomWaitDuration = Double.random(in: 5.0...10.0)
        let fadeOutDuration = 2.0
    
        // Aktionen definieren
        let waitAction = SCNAction.wait(duration: randomWaitDuration) // Wartezeit
        let fadeOutAction = SCNAction.fadeOut(duration: fadeOutDuration) // Ausblenden
        let sequence = SCNAction.sequence([waitAction, fadeOutAction]) // Aktionen in Sequenz ausführen
        
        // Aktion auf die Node anwenden
        burstNodeOfAsteroid.runAction(sequence) { [self] in
        // BurstAsteroiden in Parkposition und PhysicsBody ausschalten
        moveToParkPosition(node: burstNodeOfAsteroid, parkPosition: parkPositionOfAsteroid)
        }
    }
    
    func fadeOutAsteroidAndMoveToParkPosition(node: SCNNode, parkPosition: SCNVector3) {
        node.runAction(SCNAction.fadeOut(duration: 2.0)) { [self] in
            moveAsteroidToParkPosition(node: node, parkPosition: parkPosition)
        }
    }
    
    func moveToParkPosition(node: SCNNode, parkPosition: SCNVector3) {
        node.position = parkPosition
        node.physicsBody?.velocity = SCNVector3Zero
        node.physicsBody?.categoryBitMask = combineBitMasks([.none])
    }
    // Mit Asteroiden Zähler
    func moveAsteroidToParkPosition(node: SCNNode, parkPosition: SCNVector3) {
        node.position = parkPosition
        node.opacity = 1.0
        node.physicsBody?.velocity = SCNVector3Zero
        node.physicsBody?.categoryBitMask = combineBitMasks([.none])
    }
    
    private func applyRandomForceWithRotation(to node: SCNNode, speedRange: ClosedRange<Float>, forceOffsetRange: ClosedRange<Float>) {
        // Zufällige Richtung für die Bewegung (x und y in der 2D-Ebene)
        let x = Float.random(in: -1.0...1.0)
        let y = Float.random(in: -1.0...1.0)
        let z: Float = 0.0
        
        var direction = SCNVector3(x, y, z)
        let length = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
        
        // Normalisiere die Richtung (Länge = 1)
        if length > 0 {
            direction.x /= length
            direction.y /= length
            direction.z /= length
        }
        
        // Zufällige Geschwindigkeit (Impulsstärke)
        let speed = Float.random(in: speedRange)
        let force = SCNVector3(direction.x * speed, direction.y * speed, direction.z * speed)
        
        // Zufällige Position des Kraftansatzpunkts relativ zur Asteroidenmitte
        let offsetX = Float.random(in: forceOffsetRange)
        let offsetY = Float.random(in: forceOffsetRange)
        let offsetZ = Float.random(in: forceOffsetRange)
        let forcePosition = SCNVector3(offsetX, offsetY, offsetZ)
        
        // Wende die Kraft an der zufälligen Position an
        node.physicsBody?.applyForce(force, at: forcePosition, asImpulse: true)
    }
  


    func stopAllAsteroidsRotation(_ asteroids: [SCNNode]) {
        if asteroid.position.x == -asteroidParkPositionX {
            for asteroid in asteroids {
                stopNodeRotation(asteroid)
            }
        }
    }
    
    func stopNodeRotation(_ node: SCNNode) {
        guard let physicsBody = node.physicsBody else { return }
        
        // Geschwindigkeit stoppen
        physicsBody.velocity = SCNVector3(0, 0, 0)
        
        // Rotation stoppen
        physicsBody.angularVelocity = SCNVector4(0, 0, 0, 0)
        
        // Optional: Dämpfungswerte hoch setzen, um weitere Bewegungen zu verhindern
//        physicsBody.damping = 1.0
//        physicsBody.angularDamping = 1.0
    }
}
