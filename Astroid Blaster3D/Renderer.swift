//
//  GameViewController+Renderer.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 12.01.25.
//

import SceneKit

extension GameViewController: SCNSceneRendererDelegate {

    
   // MARK: RENDERER (updateAtTime)
   func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {

       
       // Für BigFlash OnScreen-Zeit
       let dt = time - lastUpdateTime
       lastUpdateTime = time
       
       // 200 Sterne im Hintergrund von rechts nach links bewegen
       moveBackgroundStars()
       
       fps = calculateCurrentFPS(time)
       
       guard isReadyToRender else { return }
      
       if !isTouching {
           lastDelta *= 0.9  // Dämpfung der letzten Bewegung

           if length(lastDelta) < 0.001 {  // Stoppe, wenn fast keine Bewegung mehr da ist
               lastDelta = .zero
           }
       }
       
       if !isTouchingX {
           lastDeltaX *= 0.9  // Dämpfung der X-Bewegung
           
           if abs(lastDeltaX) < 0.001 {  // Stoppe, wenn fast keine Bewegung mehr da ist
               lastDeltaX = 0.0
           }
       }
       if !gameIsPaused {
           // Wegen des Einlaufens des TwinShips
           dampenShipMotionLevelRound() // In Level und Bonusrunde aktive
           if !bonusRoundIsActive { //***
               resetShipOrientationLevelRound() // In Levelrunde aktive
           }
       }
       
       if bonusRoundIsActive {
           //TwinShip bei Pitch und Roll auf/ab und links/rechts bewegen
           updateShipMotionBonusRound()
           
           //TwinShip im Displayrand einfangen
           viewBounding()
           //Vorwärtsbeschleunigung für updateShipMotionBonusRound()
           twinShipBonusNode.simdPosition += twinShipBonusVelocity

       }
       
       // Für die aus dem Bild gelaufenen Objekte
       cleanAsteroids()
       
       // Im Main-Thread wegen möglichem SIGABRT (Signal Abort) Fehler bei "newFireNodeLeft.append(fire)"
       DispatchQueue.main.async { [self] in
           cleanFire()
       }
       
       // Shield pulsieren (Schutzschield für Twinship)
       if twinShipShieldBlink {
           blinkShield()
       }
 
       // Spiel wurde von User gestartet
       guard gameState == .running else { return }
       
       // Ab hier nur wenn Spiel läuft
       if levelClear {
           levelClearDisplay()    // Funktion für die Animation LevelClear
       }
       
       // BigFlashNode pulsieren lassen
       if bigFlashState == .approach {
           blinkBigFlash()
       }

       if bigFlashOnScreenDuration > 0 {
           bigFlashOnScreenDuration -= dt
           if bigFlashOnScreenDuration <= 0 {
               // Zeit ist vorbei
               despawnBigFlash()
           }
       }
   }
    

    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval)    {
        // Wurde von User gestartet
        guard gameState == .running else { return }
    } 
    
    func startDisplayLink() {
        // Falls ein alter DisplayLink existiert, zuerst entfernen
        displayLink?.invalidate()
        
        // Neuen DisplayLink erstellen und mit `updateCollisionDisplay()` verknüpfen
        displayLink = CADisplayLink(target: self, selector: #selector(updateCollisionDisplay))
        
        // Automatische Synchronisation mit der maximal möglichen Framerate
        displayLink?.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        
        // DisplayLink dem RunLoop hinzufügen (damit er im UI-Thread läuft)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc func updateCollisionDisplay() {
        // Je nach Level oder BonusRunde ShipNode wählen
        let shipNode = bonusRoundIsActive ? twinShipBonusNode! : twinShipNode!
        // Asteroids iterieren
        for (name, node) in displayNodeByName {
            if let asteroidNode = asteroidNodeDictionary[name] {
                // Position und Rotation des Asteroiden-Clone auf das `displayNode` übertragen
                node.simdTransform = asteroidNode.presentation.simdTransform
            }
        }
        
        let twinShipRotation = shipNode.presentation.simdOrientation

        // Extrahiere NUR die X-Rotation aus dem TwinShip
        let twinShipAngleX = -2 * atan2(twinShipRotation.imag.x, twinShipRotation.real)

        // Erzeuge eine Quaternion für die Kamera, die das X-Movement auf die Z-Achse überträgt
        let cameraRotationFix = simd_quatf(angle: twinShipAngleX, axis: SIMD3(0, 0, 1))

        // Kombiniere die gespeicherte Basis-Rotation mit der berechneten Drehung
        cameraDisplayNode.simdOrientation = simd_mul(cameraBaseOrientation, cameraRotationFix)

        // Position der Kamera synchronisieren
        cameraDisplayNode.simdPosition = shipNode.presentation.simdWorldPosition
    }
 
 
    
    func updateShipMotionBonusRound() {
        
        // TwinShip bewegt sich nach rechts beim Rollen nach rechts und umgekehrt
        let rollOffset = atan2(2.0 * (twinShipBonusNode.simdOrientation.vector.w * twinShipBonusNode.simdOrientation.vector.x),
                               1.0 - 2.0 * (twinShipBonusNode.simdOrientation.vector.x * twinShipBonusNode.simdOrientation.vector.x))
        twinShipBonusNode.simdPosition.z += rollOffset
        
        // TwinShip bewegt sich nach oben beim Pitchen nach oben und umgekerht
        let pitchOffset = atan2(2.0 * (twinShipBonusNode.simdOrientation.vector.w * twinShipBonusNode.simdOrientation.vector.z),
                              1.0 - 2.0 * (twinShipBonusNode.simdOrientation.vector.z * twinShipBonusNode.simdOrientation.vector.z))
        twinShipBonusNode.simdPosition.y += pitchOffset
        
        // Versuch twinShipBonusNode.simdPosition.x += twinShipBonusVelocity.x
    }


       
// MARK: - TwinShip Steuerung
    /// Level Runde - Dämpfung der X und Y Richtung durch Renderer getriggert
    func dampenShipMotionLevelRound() {
        // Dämpfungsfaktor anwenden, um Geschwindigkeit zu reduzieren
        velocity.x *= dampingFactor // = deltaX
        velocity.y *= dampingFactor // = deltaY
        
        // Position aktualisieren basierend auf der Geschwindigkeit
        twinShipNode.position.x += velocity.x
        twinShipNode.position.y += velocity.y
        
        // Begrenzung der Position auf definierte Grenzen
        twinShipNode.position.x = min(max(twinShipNode.position.x, -DeviceConfig.layout.shipMoveBorderX), DeviceConfig.layout.shipMoveBorderX)
        twinShipNode.position.y = min(max(twinShipNode.position.y, -DeviceConfig.layout.shipMoveBorderY), DeviceConfig.layout.shipMoveBorderY)
    }
    
    /// Setzt die Orientierung des Schiffes in der 2D-Levelrunde schrittweise zur Neutralstellung zurück, wenn keine Touch-Eingabe erfolgt
    func resetShipOrientationLevelRound() {
        // Prüfe, ob keine nennenswerte Y-Geschwindigkeit vorliegt und Rücksetzung aktiviert ist
        if abs(velocity.y) < 0.1 && startShipOrientation {
            startShipOrientation = false  // Deaktiviere Flag, um Rücksetzung zu starten
            currentFactor = 0.0           // Setze Interpolationsfaktor zurück
            startQuaternion = twinShipNode.orientation  // Speichere aktuelle Orientierung als Startpunkt
        }

        // Führe Interpolation durch, solange der Faktor < 1.0 ist
        if currentFactor < 1.0 {
            // Erhöhe den Interpolationsfaktor schrittweise, begrenze auf 1.0
            currentFactor = min(currentFactor + interpolationSpeed, 1.0)
            
            // Interpoliere zwischen Start- und Ziel-Orientierung (Neutralstellung)
            let interpolatedQuaternion = SCNQuaternion.slerp(from: startQuaternion,
                                                             to: endQuaternion,
                                                             factor: currentFactor)
            
            // Wende die interpolierte Orientierung auf das Level-Schiff an
            twinShipNode.orientation = interpolatedQuaternion
        }
    }
    
    // TwinShip wird innerhalb des Bildschirms gehalten
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

    
}

