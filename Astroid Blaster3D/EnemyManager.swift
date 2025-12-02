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
    
    func scheduleNextEnemy() {

        var spawnDelay: Double = 0
        // watchdog.functionWasCalled()
        //FIXME: * spaceInvaderSpawnDelay
        spawnDelay = Double.random(in: enemySpawnDelayRange)
        
        //Enemy mit Verzögerung starten
        DispatchQueue.main.asyncAfter(deadline: .now() + spawnDelay) { [self] in
            // BallWall darf nicht aktiv sein
            guard ballWallState == .idle else {
                currentEnemy = .none            // Neuen Enemy freigeben
                scheduleNextEnemy()             // Nächster run
                return
            }
            //Für unterschiedliche Häufung der Enemies
            let weightedEnemies: [EnemyType] = [
                //.spaceProbe, //.spaceProbe, .spaceProbe,  // 3x häufiger
                .spaceInvader, //.spaceInvader,           // 2x häufiger
                //.bigFlash                               // 1x selten
                ]
            // Es darf nur EIN Enemy gleichzeitig unterwegs sein
            guard currentEnemy == .none else {
                scheduleNextEnemy()
                return }
            // Typ wählen und dann spawnen
            currentEnemy = weightedEnemies.randomElement() ?? .spaceProbe
            spawnNextEnemy()
            print("DispatchQueue: \(spawnDelay)")
        }
    }
    
    func spawnNextEnemy() {
        
        guard bonusState != .enabled else { return }
        
        switch currentEnemy {
        case .spaceInvader:
            guard spaceInvaderState == .idle else { return }
            spaceInvaderState = .popUp
            startTimerAnimateSpaceInvader()
        case .spaceProbe:
            guard spaceProbeState == .idle else { return }
            
//            guard colorfullStarsState == .idle else {
//                self.currentEnemy = .none
//                return }
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
            //FIXME: Ist das noch nötig
                // spaceInvaderOnScreenTime = spawnDelay
        case .bigFlash:
            //Kein guard da immer von duration ausgeblendet
            currentEnemy = .none
            despawnBigFlash()
        default:
            break
        }
    }
    
   // Timer-Steuerung für Enemys
   func manageInvaderStateCycle(_ enemyState: SpaceInvaderState,duration: TimeInterval) {
       
       switch enemyState {
       case .moving:
           // Wie lange bewegt sich der Invader
           startEnemySegmentTimer(.moving, duration: duration)
       case .rotate:
           // Nach stehendem .rotate wieder nach .moving
           startEnemySegmentTimer(.rotate, duration: duration)
       default:
           break
       }
   }
   
   // Von Timer aufgerufenes Steuerung für das Ausblenden
   func manageEnemyDespawn(_ enemyState: SpaceInvaderState) {

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
           // Dann wieder für 20 Sekunden den State .moving aufrufen
           manageInvaderStateCycle(.moving, duration: spaceInvaderMovingDuration)
       case .chaos:
           break
       case .circle:
           break
       case .fallDown:
           break
       }
   }
}

