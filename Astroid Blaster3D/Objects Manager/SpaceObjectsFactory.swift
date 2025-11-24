//
//  Untitled.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 21.01.25.
//

import SceneKit

extension GameViewController {
 
    // Wegen Ruckler Asteroids vorab erzeugen
    func createObjectPool() {
        // Die großen Asteoiden - und die Clone für CollisionDisplay - erzeugen (hier 20 Stück)
        createAsteroids(count: 20, offsetNumber: 0)
        
        // Ab hier dann die Burst-Asteroiden
        offsetNumber = asteroidNode.count
        AsteroidStartValueOfBurstOne = offsetNumber
        // Die Burst Asteroiden für explosionType == .fragmentation 
        createAsteroids(count: 100, offsetNumber: offsetNumber)
                
        // Red, Green and Yellow Stars
        createColorfullStars(position: SCNVector3(x: 0, y: 0, z: 0))
    }


    
    // MARK: TwinShip
    func createTwinShip() {
        
        twinShipNode.name = "Twinship"
        twinShipNode.scale = SCNVector3(x: 1, y: 1, z: 1)
        //FIXME: Für Animation noch nachbessern
        twinShipNode.isHidden = true
        twinShipNode.position = SCNVector3(x: -400, y: 0, z: 0)
        
        // FIXME: - Alle ***.physicsBody = SCNPhysicsBody -  ausschalten wenn LevelClear - .kinematic ??
        twinShipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        twinShipNode.physicsBody?.isAffectedByGravity = false
        twinShipNode.physicsBody?.categoryBitMask = combineBitMasks([.twinShip])
        twinShipNode.physicsBody?.collisionBitMask = combineBitMasks([.none])
        twinShipNode.physicsBody?.contactTestBitMask = combineBitMasks([.colorfullStars])
        
        gameScene.rootNode.addChildNode(twinShipNode)
        
        //twinShipNode.categoryBitMask = 1    // Licht
    }
    
    // SpaceInvader aus der guten alten Zeit
    func createSpaceInvader() {
        // Variable (zurück)setzen
        resetSpaceInvader()
        
        gameScene.rootNode.addChildNode(spaceInvaderBase)
        spaceInvaderBase.physicsBody?.isAffectedByGravity = false
        spaceInvaderBase.name = "SpaceInvaderBase"
        spaceInvaderBase.position = SCNVector3(x:0, y:0, z:0)
        spaceInvaderBase.opacity = 0.0
        
        //Alle 47 Cubes erzeugen
        for i in 0...46 {
            let nodeName = String(format: "SpaceInvader%02d",i)
            var childNode = SCNNode()
            childNode = spaceInvader.clone()
            childNode.name = nodeName
            childNode.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
            childNode.position = parkPositionOfSpaceInvader //(-400, 200, 0)
            // Damit die Cubes besser zu treffen sind
            let largerShape = SCNPhysicsShape(geometry: SCNSphere(radius: 5.0))
            
            // *** Kollisionserkennung wird initialisiert
            childNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: largerShape)
            childNode.physicsBody?.isAffectedByGravity = false
            childNode.physicsBody?.velocityFactor = SCNVector3(x: 1, y: 1, z: 0)
            childNode.physicsBody?.categoryBitMask = combineBitMasks([.spaceInvader])
            childNode.physicsBody?.collisionBitMask = combineBitMasks([.none])
            childNode.physicsBody?.contactTestBitMask = combineBitMasks([.fire])
            
            spaceInvaderArray.append(childNode)
            spaceInvaderNodeDictionary[nodeName] = childNode
            
            spaceInvaderBase.addChildNode(childNode)
        }
    }
    
    func createTwinShipBonus() {
        
        twinShipBonusNode.name = "TwinshipBonus"
        twinShipBonusNode.scale = SCNVector3(x: 1, y: 1, z: 1)
        twinShipBonusNode.isHidden = false
        twinShipBonusNode.position = parkPositionOfTwinShipBonus
        twinShipBonusNode.opacity = 1.0

        twinShipBonusNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        twinShipBonusNode.physicsBody?.isAffectedByGravity = false
        twinShipBonusNode.physicsBody?.categoryBitMask = combineBitMasks([.twinShip])
        twinShipBonusNode.physicsBody?.collisionBitMask = combineBitMasks([.asteroid])
        twinShipBonusNode.physicsBody?.contactTestBitMask = combineBitMasks([.none])
        
        gameScene.rootNode.addChildNode(twinShipBonusNode)
    }
    
    func createTwinShipStart() {
        
        twinShipStartNode.name = "TwinshipStart"
        twinShipStartNode.scale = SCNVector3(x: 1, y: 1, z: 1)
        twinShipStartNode.isHidden = true
        twinShipStartNode.position = SCNVector3(x: -400, y: 0, z: 0)
        
        gameScene.rootNode.addChildNode(twinShipStartNode)
    }
    
    func combineBitMasks(_ categories: [CollisionCategory]) -> Int {
        return categories.reduce(0) { $0 | $1.bitMask }
    }
  
    
    // MARK: - Fire
    func createFireLeft(position: SCNVector3) {
        
        let fireGeometry = SCNSphere(radius: 2)
        fireGeometry.firstMaterial?.diffuse.contents = UIColor.red
        let fireNode = SCNNode(geometry: fireGeometry)
        fireNode.name = "Fire"
        fireNode.position = position
        
        fireNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        fireNode.physicsBody?.velocityFactor = SCNVector3(x: 1, y: 1, z: 0)
        fireNode.physicsBody?.categoryBitMask = combineBitMasks([.fire])
        fireNode.physicsBody?.collisionBitMask = combineBitMasks([.none])
        fireNode.physicsBody?.contactTestBitMask = combineBitMasks([.asteroid, .spaceInvader])
        
        gameScene.rootNode.addChildNode(fireNode)
        fireNodeLeft.append(fireNode)
    }

    func createFireRight(position: SCNVector3) {
    
        let fireGeometry = SCNSphere(radius: 2)
        fireGeometry.firstMaterial?.diffuse.contents = UIColor.red
        let fireNode = SCNNode(geometry: fireGeometry)
        fireNode.name = "Fire"
        fireNode.position = position
    
        fireNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        fireNode.physicsBody?.velocityFactor = SCNVector3(x: 1, y: 1, z: 0)
        fireNode.physicsBody?.categoryBitMask = combineBitMasks([.fire])
        fireNode.physicsBody?.collisionBitMask = combineBitMasks([.none])
        fireNode.physicsBody?.contactTestBitMask = combineBitMasks([.asteroid, .spaceInvader])
    
        gameScene.rootNode.addChildNode(fireNode)
        fireNodeRight.append(fireNode)
    }

// MARK: Fire
    /// Erstellt einen Feuerball für die angegebene Seite
    /// - Parameters:
    ///   - side: Seite des Schusses (rechts oder links)
    ///   - yOffset: Vertikaler Versatz relativ zum Schiff
    func createFire(side: FireSide, yOffset: Float) {
        if bonusRoundIsEnabled {
            // Bonusrunde (3D)
            let firePositionX = twinShipBonusNode.position.x + FireConfig.fireOffsetXToShip  // Vor dem Schiff
            let firePositionY = twinShipBonusNode.position.y    // Gleiche Z-Ebene wie Schiff
            let firePositionZ = twinShipBonusNode.position.z + yOffset  // Gondel-Offset

            let position = SCNVector3(firePositionX, firePositionY, firePositionZ)
            if side == .right {
                shipYPosRight = floor(twinShipBonusNode.position.y)
                createFireRight(position: position)
            } else {
                shipYPosLeft = floor(twinShipBonusNode.position.y)
                createFireLeft(position: position)
            }
        } else {
            // Levelrunde (2D)
            let firePositionX = floor(twinShipNode.position.x) + FireConfig.fireOffsetXToShip
            let firePositionY = floor(twinShipNode.position.y) + yOffset

            let position = SCNVector3(firePositionX, firePositionY, 0)
            if side == .right {
                shipYPosRight = floor(twinShipNode.position.y)
                createFireRight(position: position)
            } else {
                shipYPosLeft = floor(twinShipNode.position.y)
                createFireLeft(position: position)
            }
        }
    }
    
    // MARK: - Explosion generell
        // Explosion mit unterschiedlicher größe
    func createExplosion(for node: SCNNode, newSize: CGFloat) {
 
        // Erstellen eines Partikelsystems für die Explosion
        let explosion = SCNParticleSystem(named: "art.scnassets/Explode.scnp", inDirectory: nil)!
        explosion.loops = false
        explosion.particleLifeSpan = 1.0
        explosion.emitterShape = SCNSphere(radius: newSize)
        explosion.birthRate = 50 * newSize
        explosion.particleSize = 0.5
        explosion.particleColor = .orange
        explosion.particleVelocity = newSize

        // Setze die Position des Partikelsystems auf die Node-Position
        let explosionNode = SCNNode()
        explosionNode.position = node.presentation.worldPosition
        explosionNode.addParticleSystem(explosion)

        // Füge den Explosion-Node zur Szene hinzu
        gameScene.rootNode.addChildNode(explosionNode)
    }
    
    // MARK: - Asteroid
    func createAsteroids(count: Int, offsetNumber: Int) {
        
        let burstAsteroid = offsetNumber != 0   // Wenn true dann werden die Großen erzeugt
        let scaleRange: ClosedRange<Float> = burstAsteroid ? (0.3...0.5) : (0.8...2.0)

        for nameNumber in 0..<count {
            // Klonen und Konfigurieren der Node
            let nodeOfCreateAsteroid = asteroid.clone()
            nodeOfCreateAsteroid.scale = SCNVector3(
                Float.random(in: scaleRange),
                Float.random(in: scaleRange),
                Float.random(in: scaleRange)
            )
            nodeOfCreateAsteroid.position = SCNVector3(0, 0, 0)
            nodeOfCreateAsteroid.name = String(format: "Asteroid%04d", nameNumber + offsetNumber)
            nodeOfCreateAsteroid.isHidden = false
            nodeOfCreateAsteroid.opacity = 1.0
            
            // Für die großen Asteroiden
            if offsetNumber == 0 {
                // Asteroiden für die CollisionDisplay
                let clonedNode = nodeOfCreateAsteroid.clone()
                let nameOfNode = nodeOfCreateAsteroid.name!
                let clonedName = nameOfNode.replacingOccurrences(of: "Asteroid", with: "Clone", options: .anchored)

                clonedNode.name = clonedName
                clonedNode.opacity = 0.0
                clonedNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
                clonedNode.isHidden = false //*01
                displayScene.rootNode.addChildNode(clonedNode)
                displayNodeByName[nameOfNode] = clonedNode   //Dictionary Zuweisung
                
                // Für die Großen die detailierte PhysicsShape
                nodeOfCreateAsteroid.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                // Für die Burst-Asteroiden
            } else {
                // Für die Burst-Asteroiden reicht eine bounding Box
                let parentPhysicsShape = SCNPhysicsShape(node: nodeOfCreateAsteroid,
                                                         options: [.type: SCNPhysicsShape.ShapeType.boundingBox])
                nodeOfCreateAsteroid.physicsBody = SCNPhysicsBody(type: .dynamic, shape: parentPhysicsShape)
            }
            
            nodeOfCreateAsteroid.physicsBody?.isAffectedByGravity = false
            nodeOfCreateAsteroid.physicsBody?.velocityFactor = SCNVector3(x: 1, y: 1, z: 0)
            nodeOfCreateAsteroid.physicsBody?.damping = 0
            nodeOfCreateAsteroid.physicsBody?.angularDamping = 0
            nodeOfCreateAsteroid.physicsBody?.friction = 0
            nodeOfCreateAsteroid.physicsBody?.mass = 5.0
            
            nodeOfCreateAsteroid.physicsBody?.categoryBitMask = combineBitMasks([.asteroid])
            nodeOfCreateAsteroid.physicsBody?.collisionBitMask = combineBitMasks([.none])
            nodeOfCreateAsteroid.physicsBody?.contactTestBitMask = combineBitMasks([.fire])
            
            // Hinzufügen zu den entsprechenden Sammlungen
            asteroidNode.append(nodeOfCreateAsteroid)
            asteroidNodeDictionary[nodeOfCreateAsteroid.name!] = nodeOfCreateAsteroid
            
            // Zur Szene hinzufügen
            gameScene.rootNode.addChildNode(nodeOfCreateAsteroid)
        }
    }
       
    //MARK: STARS
    func createStars() {
        // Create 100 Stars for Background animation
        for index in 0..<100 {
            
            let starBig = CGFloat.random(in: 0.1...1.5)  // Random Size
            let pointGeometry = SCNSphere(radius: starBig)
            pointGeometry.firstMaterial?.diffuse.contents = UIColor.systemYellow
            let point = SCNNode(geometry: pointGeometry)
            
            // Fill up Array with speed values
            let value = Double(index) * (starBig/10)    // Speed ​​star proportional to size
            starSpeed.append(Float(value))              // assign value
            
            // Zufällige Position der Sterne rechts vom Bildfeld ...
            // ... damit die Sterne in der Intro-Animation nicht sichtbar sind
            let startX = Float.random(in: 400...800) //Alt: -200...200)
            let startY = Float.random(in: -DeviceConfig.layout.starMoveBorderY...DeviceConfig.layout.starMoveBorderY)
                        
            // Für die BonusRound Sterne ist z vor dem Spielfeld
            if index < 50 {
                point.position = SCNVector3(x: startX, y: startY, z: -100)
            } else {
                point.position = SCNVector3(x: startX, y: startY, z: 100)
            }

            gameScene.rootNode.addChildNode(point)
            pointNode.append(point)
        }
    }
    
    //TODO: TwinShip Collision Detector
    /// Erstellt die unsichtbare Sonde für Kollisionserkennung
    func createTwinShipCollisionDetector() {
        collisionSensorNode = SCNNode()
        collisionSensorNode?.name = "CollisionSensor"
        collisionSensorNode?.opacity = 1.0  // Sichtbar (kann ggf. auf 0.0 gesetzt werden)

        // Maße des Sichtfeldes
        let pyramid = SCNPyramid(width: 160, height: 500, length: 80)
        
        // Geometrie deaktiviert, falls unsichtbar bleiben soll
        // pyramid.firstMaterial?.diffuse.contents = UIColor.red
        // collisionSensorNode?.geometry = pyramid

        // Physik-Körper zuweisen
        collisionSensorNode?.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: pyramid))
        collisionSensorNode?.physicsBody?.categoryBitMask = combineBitMasks([.probe])
        collisionSensorNode?.physicsBody?.collisionBitMask = 0
        collisionSensorNode?.physicsBody?.contactTestBitMask = combineBitMasks([.asteroid])

        // Zur Szene hinzufügen
        gameScene.rootNode.addChildNode(collisionSensorNode!)
        twinShipNode.addChildNode(collisionSensorNode!)
        
        // In Sichtrichtung des TwinShips ausrichten
        collisionSensorNode?.simdOrientation = simd_quatf(angle: .pi / 2, axis: SIMD3(0, 0, 1))
        
        // Spitze der Pyramide an das TwinShip setzen
        collisionSensorNode?.position = SCNVector3(x: 500, y: 0, z: 0)
    }

    // MARK: SHIELD BigFlash
    func setupShield(
        at position: SCNVector3,
        category: CollisionCategory = .none,
        collideWith: [CollisionCategory] = [.none],
        contactTest: [CollisionCategory] = [.none],
        radius: CGFloat = 3.0,
        color: UIColor = .blue
    ) -> SCNNode {
        
        // 1. Geometrie & Material erstellen
        let shieldGeometry = SCNSphere(radius: radius)
        let shieldNode = SCNNode(geometry: shieldGeometry)
        shieldNode.position = position
        
        let shieldMaterial = SCNMaterial()
        shieldMaterial.diffuse.contents = color.withAlphaComponent(0.7)
        shieldMaterial.blendMode = .add
        shieldMaterial.isDoubleSided = false
        shieldGeometry.materials = [shieldMaterial]
        
        // 2. PhysicsBody konfigurieren
        shieldNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        shieldNode.physicsBody?.isAffectedByGravity = false
        shieldNode.physicsBody?.categoryBitMask = category.bitMask
        shieldNode.physicsBody?.collisionBitMask = combineBitMasks(collideWith)
        shieldNode.physicsBody?.contactTestBitMask = combineBitMasks(contactTest)
        
        // 3. Sichtbarkeit & Hierarchie
        shieldNode.isHidden = false
        shieldNode.opacity = 1.0
        gameScene.rootNode.addChildNode(shieldNode)
        
        return shieldNode
    }
    
    func setupShipBoost(for shipNode: SCNNode, with config: TwinShipBoosterConfig) {
               
        //  Linker Booster
        let leftBoostNode = SCNNode()
        leftBoostNode.addParticleSystem(fireBoost)  // Hier wird das Partikelsystem zugewiesen!
        leftBoostNode.position = config.positionLeft
        
        let leftBoostRotation = simd_quatf(angle: config.rotation1, axis: config.axis1) *
                                simd_quatf(angle: config.rotation2, axis: config.axis2)
        leftBoostNode.simdOrientation = leftBoostRotation // additionalRotationLeft * leftBoostQuaternion
        shipNode.addChildNode(leftBoostNode)

        //  Rechter Booster
        let rightBoostNode = SCNNode()
        rightBoostNode.addParticleSystem(fireBoost)
        rightBoostNode.position = config.positionRight
        let rightBoostRotation = simd_quatf(angle: config.rotation1, axis: config.axis1) *
                                 simd_quatf(angle: config.rotation2, axis: config.axis2)
        rightBoostNode.simdOrientation = rightBoostRotation
        shipNode.addChildNode(rightBoostNode)
    }
    
    /*Für die Ausrichtung der Booster in den unterschiedlichen
    Bonus/Level/Animationsrichtungen des TwinShips */
    struct TwinShipBoosterConfig {
        let positionLeft: SCNVector3
        let positionRight: SCNVector3
        let rotation1: Float
        let axis1: SIMD3<Float>
        let rotation2: Float
        let axis2: SIMD3<Float>
        
        static let standard = TwinShipBoosterConfig(
            positionLeft: SCNVector3(-60, 15, 0),
            positionRight: SCNVector3(-60, -15, 0),
            rotation1: -.pi / 2,
            axis1: SIMD3<Float>(0, 0, 1),
            rotation2: 0,                   // Keine Rotation: axis2 ist dann egal
            axis2: SIMD3<Float>(1, 0, 0)
        )
        
        static let bonus = TwinShipBoosterConfig(
            positionLeft: SCNVector3(-60, 0, -10),
            positionRight: SCNVector3(-60, 0, 10),
            rotation1: 0, //.pi,  // Invertierte Werte für Bonus-Modus
            axis1: SIMD3<Float>(0, 1, 0),
            rotation2: -.pi / 2,
            axis2: SIMD3<Float>(0, 0, 1)
        )

        static let start = TwinShipBoosterConfig(
            positionLeft: SCNVector3(-10, 0, 60),
            positionRight: SCNVector3(10, 0, 60),
            rotation1: 0,
            axis1: SIMD3<Float>(0, 1, 0),
            rotation2: -.pi / 2,
            axis2: SIMD3<Float>(1, 0, 0)
        )
    }
    
    func setupTwinShipBoost() {
        fireBoost = SCNParticleSystem()
        
        // Partikeleigenschaften setzen
        fireBoost.particleSize = 0.2
        
        fireBoost.birthRate = 1000
        fireBoost.particleLifeSpan = 0.8
        fireBoost.particleSizeVariation = 1
        fireBoost.particleColor = UIColor.red
        
//        fireBoost.isLightingEnabled = true
//        fireBoost.particleVelocityVariation = 2.0 // Partikel bewegen sich nicht alle gleich schnell
//        fireBoost.spreadingAngle = 30 // Verwirbelung durch Streuung
        
        fireBoost.particleMassVariation = 4
        fireBoost.particleColorVariation = SCNVector4(0, 1.0, 1.0, 0)
        fireBoost.emitterShape = SCNCone(topRadius: 2, bottomRadius: 20, height: 75)
        fireBoost.particleVelocity = 100.0
        fireBoost.emittingDirection = SCNVector3(x: 0, y: -1, z: 0)
        fireBoost.blendMode = .additive
        fireBoost.isAffectedByGravity = false
        fireBoost.particleImage = UIImage(named: "spark.png")

    }
}

