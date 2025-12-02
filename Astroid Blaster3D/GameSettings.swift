//
//  GameSettings.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 21.04.25.
//


import UIKit
import Foundation

//MARK: - Enemy Type
enum EnemyType {
    case none, spaceInvader, spaceProbe, bigFlash, ballWall // Status des EnemyTypen
}

enum SpaceProbeState {
    case idle, fadeIn, moving, isHit, starsOn, starsOff, fadeOut
}

enum ColorfullStarsState {
    case idle, moving, starsOn, starsOff
}

enum SpaceInvaderState {
    case idle, popUp, moving, rotate, chaos, circle ,fallDown
}

enum BigFlashState {
    case idle, approach, moving, scaleDown
}

enum BallWallState {
    case idle, buildUp, moving
}

enum LevelType {
    case easy, medium, hard
}

enum GameState {
    case ready          // Standard oder eben Beginn
    case running        // Mit StartGameDisplay beginn das Spiel
    case paused         // Level Clear oder Benutzer-Pause
    case gameOver       // Selbst-erklärend
}

enum BonusState {
    case locked           // Noch nicht erreicht
    case reached          // Punktzahl erreicht, Spieler kann wählen
    case enabled          // Spieler hat gewählt, Bonus wartet auf Start
    case active           // Schiff wird gerade im Bonus gespielt
}


enum CollisionCategory {
    case none
    case asteroid
    case fire
    case ballWall
    case spaceProbe
    case spaceInvader
    case twinShip
    case colorfullStars
    case bigFlash
    case probe

    var bitMask: Int {
        switch self {
        case .none:            return 0
        case .asteroid:        return 0x1 << 0
        case .fire:            return 0x1 << 1
        case .ballWall:        return 0x1 << 2
        case .spaceProbe:      return 0x1 << 3
        case .spaceInvader:    return 0x1 << 4
        case .twinShip:        return 0x1 << 5
        case .colorfullStars:  return 0x1 << 6
        case .bigFlash:        return 0x1 << 7
        case .probe:           return 0x1 << 8
        }
    }
}

//MARK: - Tags
struct ViewTags {
    static let startImageView = 100
    static let startButton = 101
    static let settingsButton = 102
    static let canvasButton = 103
    static let difficultyButton = 104
    static let welcomeLabel = 201
    static let bonusButton = 202
    static let difficultyLabel = 203
}

//MARK: - Layout
struct DeviceConfig {
    static let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    
    static let crossSize: CGFloat = isIPad ? 200 : 120  // Größe des Steuerkreuzes
    static let lineWidth: CGFloat = crossSize * 0.25   // Dicke der Linien (relativ zur Größe)
    static let cornerRadius: CGFloat = crossSize * 0.1 // Abgerundete Ecken
    static let margin: CGFloat = isIPad ? 80 : 40       // Abstand zum Rand
   
    struct Layout {
        let displayViewFrame: CGRect
        let preferredFramesPerSecond: Int
        // Bewegungsgrenzen Twinship
        let shipMoveBorderY: Float
        let shipMoveBorderX: Float
        // Bewegungsgrenzen Hintergrundsterne für CleanScene)
        let starMoveBorderY: Float
        // Bewegungsgrenzen BallWall
        let maxBallPositionY: Float         // Beim setzten
        let ballWallMoveBorderX: CGFloat    // Beim bewegen
        // Bewegungsgrenzen Asteroids
        let asteroidMoveBorderY: Float
        let fireBorderLeft: CGFloat         // Begrenzung für Touchfläche für Feuereingabe
        let welcomeTextYPosition: CGFloat
        let switchPositionOffsetY: CGFloat  // Schalterposition nach unten verschieben
        let switchYPositionOffsetRow2: Int  // TODO: Nicht benutzt
        let startSwitchPosOffsetY: Int      // TODO: Nicht benutzt
        let orthographicScale: CGFloat
    }
    
    static let layout: Layout = {
        if isIPad {
            print("Läuft auf einem iPad")
            return Layout(
                displayViewFrame: CGRect(x: screenWidth - 600, y: 50, width: 500, height: 200),
                preferredFramesPerSecond: 60,
                shipMoveBorderY: 160,
                shipMoveBorderX: 240,
                starMoveBorderY: 200,
                maxBallPositionY: 200,
                ballWallMoveBorderX: 450,
                asteroidMoveBorderY: 250,
                fireBorderLeft: 400,
                welcomeTextYPosition: 400,
                switchPositionOffsetY: 650,
                switchYPositionOffsetRow2: 300,
                startSwitchPosOffsetY: 300,
                orthographicScale: 200
            )
        } else {
            print("Läuft auf einem iPhone")
            return Layout(
                displayViewFrame: CGRect(x: screenWidth - 350, y: 30, width: 300, height: 150),
                preferredFramesPerSecond: 60,
                shipMoveBorderY: 80,
                shipMoveBorderX: 200,
                starMoveBorderY: 100,
                maxBallPositionY: 110,
                ballWallMoveBorderX: 400,
                asteroidMoveBorderY: 130,
                fireBorderLeft: 200,
                welcomeTextYPosition: 80,   //NEU
                switchPositionOffsetY: 50,
                switchYPositionOffsetRow2: -230,
                startSwitchPosOffsetY: -10,
                orthographicScale: 100
            )
        }
    }()
}

//MARK: - Level
struct AsteroidConfig {
    let startDelay: TimeInterval    // Frequenz Asteroid Start
    let countMax: Int               // Anzahl Asteroiden pro Level
    let scale: CGFloat
    let maxNumberOnScreen: Int
    let startValueOfBurstOne: Int
    let startBorderY: Float
    let difficultyLabel = UILabel()
}

struct EnemyConfig {
    let invaderMovingDuration: Double
    let invaderOnScreenTime: TimeInterval
    let invaderFramesRefreshTime: TimeInterval
    let probeStartDelay: TimeInterval
    let probeOnScreenTime: TimeInterval
    let flashStartDelay: TimeInterval
    let flashOnScreenTime: TimeInterval
    let wallStartDelay: TimeInterval
    let moveObjectRangeY: ClosedRange<Float>
    let bigFlashOnScreenDurationRange: ClosedRange<TimeInterval>
    let spawnDelayRange: ClosedRange<TimeInterval>
}


struct LevelConfig {
    static let isIPad = UIDevice.current.userInterfaceIdiom == .pad

    static func asteroidConfig(for difficulty: LevelType, level: Int) -> AsteroidConfig {
        
        let levelFactor = max(level, 1)
        let lf = Double(levelFactor)
        
        print("LevelConfig level: \(level)")
        switch difficulty {
        case .easy:
            // Gemütlicher Einstieg
            let baseDelay = 4.0
            let minDelay  = 0.5
            
            return isIPad
            ? AsteroidConfig(
                startDelay:            max(minDelay, baseDelay / lf),
                countMax:              5 * levelFactor, // Anzahl Asteroids erhöhen
                scale:                 1.5,
                maxNumberOnScreen:     3,
                startValueOfBurstOne:  2,
                startBorderY:          80
            )
            
            //FIXME: noch anpassen
            : AsteroidConfig(
                startDelay:            3.0,
                countMax:              5 * levelFactor,
                scale:                 1.2,
                maxNumberOnScreen:     3,
                startValueOfBurstOne:  1,
                startBorderY:          80
            )

        case .medium:
            // Spürbar schneller & mehr los
            let baseDelay = 3.0
            let minDelay  = 0.35
            
            return isIPad
            ? AsteroidConfig(
                startDelay:            max(minDelay, baseDelay / lf),
                countMax:              5 * levelFactor,
                scale:                 2.0,
                maxNumberOnScreen:     12,
                startValueOfBurstOne:  3,
                startBorderY:          150
            )
            : AsteroidConfig(
                startDelay:            2.5,
                countMax:              18,
                scale:                 1.8,
                maxNumberOnScreen:     8,
                startValueOfBurstOne:  2,
                startBorderY:          80
            )

        case .hard:
            // Richtig Action – BonusRound-Vorstufe
            let baseDelay = 2.0
            let minDelay  = 0.2
            
            return isIPad
            ? AsteroidConfig(
                startDelay:            max(minDelay, baseDelay / lf),
                countMax:              9 * levelFactor,
                scale:                 3.0,
                maxNumberOnScreen:     20,
                startValueOfBurstOne:  5,
                startBorderY:          200
            )
            : AsteroidConfig(
                startDelay:            1.5,
                countMax:              25,
                scale:                 2.5,
                maxNumberOnScreen:     12,
                startValueOfBurstOne:  4,
                startBorderY:          80
            )
        }
    }

    static func enemyConfig(for level: LevelType) -> EnemyConfig {
        switch level {
        case .easy:
            return isIPad
            ? EnemyConfig(
                invaderMovingDuration:    15,
                invaderOnScreenTime:     9,
                invaderFramesRefreshTime: 0.0083,
                probeStartDelay:         5,
                probeOnScreenTime:       30,
                flashStartDelay:         25,
                flashOnScreenTime:       20,
                wallStartDelay:          200,
                moveObjectRangeY:        -70...70,
                // 25 Sekunden ist die Startzeit von BigFlash .moving
                bigFlashOnScreenDurationRange: 30.0...50.0,
                spawnDelayRange: 15.0...17.0
            )
            : EnemyConfig(
                invaderMovingDuration:       15,
                invaderOnScreenTime:     9,
                invaderFramesRefreshTime: 0.1,
                probeStartDelay:         5,
                probeOnScreenTime:       10,
                flashStartDelay:         25,
                flashOnScreenTime:       20,
                wallStartDelay:          270,
                moveObjectRangeY:        -70...70,
                bigFlashOnScreenDurationRange: 30.0...40.0,
                spawnDelayRange: 15.0...17.0
            )

        case .medium:
            return isIPad
            ? EnemyConfig(
                invaderMovingDuration:       75,
                invaderOnScreenTime:     40,
                invaderFramesRefreshTime: 0.1,
                probeStartDelay:         15,
                probeOnScreenTime:       10,
                flashStartDelay:         25,
                flashOnScreenTime:       20,
                wallStartDelay:          270,
                moveObjectRangeY:        -150...150,
                bigFlashOnScreenDurationRange: 30.0...70.0,
                spawnDelayRange: 15.0...17.0
            )
            : EnemyConfig(
                invaderMovingDuration:       100,
                invaderOnScreenTime:     20,
                invaderFramesRefreshTime: 0.1,
                probeStartDelay:         15,
                probeOnScreenTime:       10,
                flashStartDelay:         25,
                flashOnScreenTime:       20,
                wallStartDelay:          270,
                moveObjectRangeY:        -70...70,
                bigFlashOnScreenDurationRange: 30.0...50.0,
                spawnDelayRange: 15.0...17.0
            )

        case .hard:
            return isIPad
            ? EnemyConfig(
                invaderMovingDuration:       50,
                invaderOnScreenTime:     30,
                invaderFramesRefreshTime: 0.1,
                probeStartDelay:         15,
                probeOnScreenTime:       10,
                flashStartDelay:         25,
                flashOnScreenTime:       20,
                wallStartDelay:          270,
                moveObjectRangeY:        -200...200,
                bigFlashOnScreenDurationRange: 30.0...100.0,
                spawnDelayRange: 15.0...17.0
            )
            : EnemyConfig(
                invaderMovingDuration:       75,
                invaderOnScreenTime:     20,
                invaderFramesRefreshTime: 0.1,
                probeStartDelay:         15,
                probeOnScreenTime:       10,
                flashStartDelay:         25,
                flashOnScreenTime:       20,
                wallStartDelay:          270,
                moveObjectRangeY:        -70...70,
                bigFlashOnScreenDurationRange: 30.0...70.0,
                spawnDelayRange: 15.0...17.0
            )
        }
    }
}

//MARK: - Fire
struct FireConfig {
    static let fireOffsetXToShip: Float = 30        // Abstand zur Schiffsposition (X)
    static let fireOffsetRightYToShip: Float = -8   // Offset für die rechte Gondel (Y)
    static let fireOffsetLeftYToShip: Float = 8     // Offset für die linke Gondel (Y)
    static let moveDuration: TimeInterval = 0.7     // Dauer der Bewegung
}

//TODO: Umsetzten
enum ExplosionType {
    case disruption, fragmentation
}

// 1. Enum definieren
enum FireType {
    case single, double
    
    mutating func toggle() {
        switch self {
        case .single:
            self = .double
        case .double:
            self = .single
        }
    }
}

enum FireSide {
    case left, right
}
