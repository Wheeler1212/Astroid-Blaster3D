//
//  SpaceInvaderController.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 26.03.25.
//

import Foundation
import SceneKit
import UIKit


extension GameViewController {
    
    func scheduleNextEnemy(_ enemy: EnemyType) {
        let spawnDelayRange = 15.0...17.0

        //#10 watchdog.functionWasCalled()
        //FIXME: * spaceInvaderSpawnDelay
        spawnDelay = Double.random(in: spawnDelayRange)
        
        //"Timer" mit spawnDelay-Verzögerung starten
        DispatchQueue.main.asyncAfter(deadline: .now() + spawnDelay) { [self] in
            //Wenn BallWall aktive, dann abbrechen
            guard ballWallState == .idle else {
                currentEnemy = .none    //# Neuen Enemy freigeben
                scheduleNextEnemy(.ballWall)   //Nächster run
                return
            }
            //Für unterschiedliche Häufung der Enemies
            //TODO: Häufungen wieder einschalten
            let weightedEnemies: [EnemyType] = [
                //.spaceProbe, //.spaceProbe, .spaceProbe,  // 3x häufiger
                .spaceInvader, //.spaceInvader,           // 2x häufiger
                //.bigFlash                               // 1x selten
                ]
            // Neuen Enemy nur freigeben wenn sonst keiner unterwegs ist
            guard currentEnemy == .none else {
                scheduleNextEnemy(.none)
                return }
            currentEnemy = weightedEnemies.randomElement() ?? .spaceProbe
            spawnNextEnemy()
        }
    }
    
    func spawnNextEnemy() {
        // FIXME: In GameSettings eintragen
        // Für unterschiedliche Werte in Level und Difficulty
        // 25 Sekunden für BigFlash wird ja vergrößert eingeflogen
        let bigFlashOnScreenDurationRange = 30.0...40.0
        
        switch currentEnemy {
        case .spaceInvader:
            guard spaceInvaderState == .idle else { return }
            //SpaceInvader starten
            spaceInvaderState = .popUp
            startTimerAnimateSpaceInvader()
        case .spaceProbe:
            guard colorfullStarsState == .idle else {
                self.currentEnemy = .none
                return }
            spaceProbeState = .fadeIn
            spawnSpaceProbe()
        case .bigFlash:
            guard bigFlashState == .idle else { return }
            bigFlashState = .approach
            bigFlashOnScreenDuration = Double.random(in: bigFlashOnScreenDurationRange)
            animateBigFlash()
        case .ballWall:
            break
        case .none:
            break
        }
    }
  
    // Enemies nach duration ausblenden
    func despawnNextEnemy()  {

        switch currentEnemy {
        case .spaceProbe:
            //SpaceProbe aktive??
            guard spaceProbeState != .idle else { return }
            currentEnemy = .none
            despawnSpaceProbe()
        case .spaceInvader:
            guard spaceProbeState != .idle else { return }
//                    spaceInvaderOnScreenTime = spawnDelay
        case .bigFlash:
            //Kein guard da immer von duration ausgeblendet
            currentEnemy = .none
            despawnBigFlash()
        default:
            break
        }
    }
    
   // Timer-Steuerung für Enemys
   func manageEnemyStateCycle(_ enemyType: EnemyType, _ enemyState: SpaceInvaderState,duration: TimeInterval) {
       logEvent("manageEnemyStateCycle")
       switch enemyState {
       case .moving:
           // .moving nach Zeit (duration) abbrechen
           startEnemySegmentTimer(.moving, duration: duration)
       case .rotate:
           // State zeitlich begrenzen
           startEnemySegmentTimer(.rotate, duration: duration)
       default:
           break
       }
   }
   
   // Von Timer aufgerufenes Steuerung für das Ausblenden
   func manageEnemyDespawn(_ enemyState: SpaceInvaderState) {
       logEvent("manageEnemyDespawn")
       //switch enemyState { - Der State vom gestartetem Timer
       switch spaceInvaderState { // Der aktuelle State
       case .idle:
           break
       case .popUp:
           break
       case .moving:
           // CubeFallDown starten
           isCubeFallingDownInvader = true
           spaceInvaderState = .fallDown
           indexFallDown = 47
       case .rotate:
           // Nach stehendem .rotate wieder nach .moving
           isStartSpaceInvader = true
           isStartToMoveInvader = true
           velosityMoveStepOfInvader = 0.1
           isHitInvaderFirst = false
           spaceInvaderState = .moving
           // Dann wieder für 20 Sekunden den State .moving managen
           manageEnemyStateCycle(.spaceInvader, .moving, duration: 20)
       case .chaos:
           break
       case .circle:
           break
       case .fallDown:
           break
       }
   }
    
    // Log-Ausgabe mit Zeit
    func logEvent(_ message: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(time)] \(message)")
//        print (String(format: "%.0f", spawnDelay),  "spawnDelay")
//        print (String(format: "%.0f", bigFlashOnScreenDuration),  "bigFlashOnScreenDuration")
//        print ("\(currentEnemy)",  "currentEnemy")
        print ("\(spaceInvaderState)",  "spaceInvaderState")
//        print ("\(spaceProbeState)",  "spaceProbeState")
//        print ("\(bigFlashState)",  "bigFlashState")
//        print ("\(ballWallState)",  "ballWallState")
        counter += 1
        print ("counter: \(counter)")
        print("")
    }
}

