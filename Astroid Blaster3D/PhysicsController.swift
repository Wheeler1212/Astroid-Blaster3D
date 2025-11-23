//
//  GameViewController+Physics.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 12.01.25.
//

import SceneKit

extension GameViewController: SCNPhysicsContactDelegate {

   func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
       
       // Haben beide Nodes einen PhysicsBody?
       if let PhysicsBodyNodeA = contact.nodeA.physicsBody, let PhysicsBodyNodeB = contact.nodeB.physicsBody {
           
           //FIXME: Eventuell bei BonusRound deaktivieren
           // Wegen orthographische Darstellung
           PhysicsBodyNodeA.velocity.z = 0
           PhysicsBodyNodeB.velocity.z = 0
           
           // Die beiden an der Kollision beteiligten Nodes
           let nodeA = contact.nodeA
           let nodeB = contact.nodeB

           // Auf Nil überprüfen und gleichzeitig Name der Node auf Variable zuweisen
           let nameOfNodeA = contact.nodeA.name ?? ""
           let nameOfNodeB = contact.nodeB.name ?? ""
           
           //FIXME: Ausgeklammert
           //print("nameOfNodeA \(nameOfNodeA) nameOfNodeB \(nameOfNodeB)")
//           print("node.position.Z \(nodeA.position.z) \(nodeB.position.z)")
//           print("  ")
           
           //print("Kollision: \(nameOfNodeA) vs \(nameOfNodeB)")

            //*01 Sonden-Kollision mit Asteroid
//           if (nameOfNodeA == "Sonde" && nameOfNodeB.hasPrefix("Asteroid")) {
//               if let node = displayNodeByName[nameOfNodeB], node.isHidden {
//                   node.isHidden = false  // Nur setzen, wenn es vorher ausgeblendet war
//                   //print("displayNodeByName[nameOfNodeB] \(String(describing: displayNodeByName[nameOfNodeB]))")
//               }
//               
//           } else if (nameOfNodeB == "Sonde" && nameOfNodeA.hasPrefix("Asteroid")) {
//               if let node = displayNodeByName[nameOfNodeA], node.isHidden {
//                   node.isHidden = false
//                   //print("displayNodeByName[nameOfNodeA] \(String(describing: displayNodeByName[nameOfNodeA]))")
//               }
//           }
// *****************
//           if !levelClear { // Fire trifft Enemy nur bei laufendem Level
//               // Kollision von Fire mit beliebigem Objekt prüfen
//               if nameOfNodeA == "Fire" || nameOfNodeB == "Fire" {
//                   // Ermittle den relevanten Namen basierend auf `nameOfNodeA` oder `nameOfNodeB`
//                   let enemyName = nameOfNodeA == "Fire" ? nameOfNodeB : nameOfNodeA // enemyName != "Fire"
//                   let enemyNode = nameOfNodeA == "Fire" ? nodeB : nodeA // enemyNode != Fire Node
//                   let fireNode = nameOfNodeB ==  "Fire" ? nodeB : nodeA // fireNode zuweisen
//                   fireHitEnemy(enemyName: enemyName, enemyNode: enemyNode, fireNode: fireNode)
//               }
//           }
           // Chatties Vorschlag: Ist leichter zu lesen
           if !levelClear {
               if nameOfNodeA == "Fire" || nameOfNodeB == "Fire" {
                   
                   let fireNode: SCNNode
                   let enemyNode: SCNNode
                   let enemyName: String
                   
                   if nameOfNodeA == "Fire" {
                       fireNode = nodeA
                       enemyNode = nodeB
                       enemyName = nameOfNodeB
                   } else {
                       fireNode = nodeB
                       enemyNode = nodeA
                       enemyName = nameOfNodeA
                   }
                   
                   fireHitEnemy(enemyName: enemyName, enemyNode: enemyNode, fireNode: fireNode)
               }
           }


           // FIXME:  Kollision mit BigFlash und Asteroid
           if nameOfNodeA == "BigFlash" || nameOfNodeB == "BigFlash" {
               var nameOfNode = ""
               var asteroidSet = false
               if !isContactBigFlashCooldownActive {
                   
                   // Wenn eine der beiden Kollisions-Nodes ein Asteroid ist ...
                   if nameOfNodeA.prefix(8) == "Asteroid" {
                       nameOfNode = nameOfNodeA
                       asteroidSet = true
                   } else if nameOfNodeB.prefix(8) == "Asteroid"{
                       asteroidSet = true
                       nameOfNode = nameOfNodeB
                   }
                   // ... dann, wenn klein genug, von BigFlash wegstoßen
                   if asteroidSet {
                       if let spezificAsteroid = asteroidNodeDictionary[nameOfNode] {
                           if spezificAsteroid.scale.x < 0.8 {
                               popUpAndDown(node: spezificAsteroid, scaleUp: 2, scaleDown: 0.1)
                           }
                       }
                   }
                   // Aktivieren des Cooldowns
                   isContactBigFlashCooldownActive = true
                   DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // 0.5 Sekunden Cooldown
                       self.isContactBigFlashCooldownActive = false
                   }
               }
           }
           //} // Ende Kollisionsprüfung "Fire"
               
        // Kollision von TwinShip mit Star oder BallWall
           let nodes = [contact.nodeA, contact.nodeB]   // Die beiden an der Kollision beteiligten Nodes
           let twinshipNode = nodes.first(where: { $0.name == "Twinship" })
           let ballWallNode = nodes.first(where: { $0.name == "BallWall" })
           let starNode = nodes.first(where: { $0.name?.hasSuffix("Star") == true })

           if twinshipNode != nil {
               // Doppelkontakte vermeiden
               if !isContactStarsCooldownActive {
                   SoundManager.shared.playStarBonus()
                   
                   if let star = starNode {
                       handleStarCollision(star)
                   }
//                   else if let ballWall = ballWallNode {
//                       //FIXME: BallWall Kollision
//                       handleBallWallCollision(ballWall)
//                   }
                   
                   // Aktivieren des Cooldowns
                   isContactStarsCooldownActive = true
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                       self.isContactStarsCooldownActive = false
                   }
               }
           }
               //FIXME: - Ab hier Kollision mit Fire Twinship bearbeiten
               if nodeA.name == "Fire" || nodeB.name == "Fire" {
                   if nodeA.name == "Twinship" || nodeB.name == "Twinship" {
                       // FIXME: Kollision mit ????? Fire und Twinship

                   }
               } // !!! Ende Kollision mit Node.name == "Fire"
           }  // !!! Ende " if let nameOfNodeA = nodeA.name" - // Auf nil überprüfen
       }  // Ende *** if let PhysicsBodyNodeA ***
   
   
   func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
       // Bearbeiten wenn Kollision beendet ist
       let nameOfNodeA = contact.nodeA.name ?? ""
       let nameOfNodeB = contact.nodeB.name ?? ""

       if (nameOfNodeA == "Sonde" && nameOfNodeB.hasPrefix("Asteroid")) {
           //delayedRemoveNode(nameOfNode: nameOfNodeB)
       } else if (nameOfNodeB == "Sonde" && nameOfNodeA.hasPrefix("Asteroid")) {
           //delayedRemoveNode(nameOfNode: nameOfNodeA)
       }
   }
}

