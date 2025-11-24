    //
    //  GameViewController.swift
    //
    //  Created by Günter Voit on 14.08.24.
    //

import SceneKit
import SpriteKit
import AudioToolbox
import UIKit
import Foundation
import CoreGraphics
import AVFoundation


class GameViewController: UIViewController, LevelManagerDelegate {
    
    var audioPlayer: AVAudioPlayer?
    var watchdog: FunctionWatchdog!
    var debugHUD: DebugHUD!
    var fps: Int = 0
    var settingsView: UIView?
    var canvasView: UIView?
    var welcomeLabel: UILabel!
    var showSpawnDelay = 0.0
    
    // Globale Variablen (ersetzt die Klassen-Properties)
    var currentEnemy: EnemyType = .none
    var spawnDelay: Double = 0
    
    var asteroidStartDelay: TimeInterval = 0.0
    var asteroidScale: CGFloat = 1.0
    var asteroidBurstStartValue: Int = 0
    
    var bonusTestMode: Bool = false
    var displayLink: CADisplayLink?
    var isMusicOn = false
    var soundSwitch: UISwitch!
    var musicSwitch: UISwitch!
    var debugAxesSwitch: UISwitch!
    var startAnimationSwitch: UISwitch!

    //Parkpostitionen der Objekte
    let parkPositionOfSpaceProbe: SCNVector3 =      SCNVector3(-400, 0, 0)
    let parkPositionOfColorfullStars: SCNVector3 =  SCNVector3(-400, 50, 0)
    let parkPositionOfTwinShipBonus: SCNVector3 =   SCNVector3(-400, -150, 0)
    let parkPositionOfTwinShip: SCNVector3 =        SCNVector3(-400, 150, 0)
    let parkPositionOfBigFlash: SCNVector3 =        SCNVector3(-400, -50, 0)
    let parkPositionOfAsteroid: SCNVector3 =        SCNVector3(-400, 100, 0)
    var parkPositionOfShield: SCNVector3 =          SCNVector3(-400, -100, 0)
    var parkPositionOfSpaceInvader: SCNVector3 =    SCNVector3(-400, 200, 0)
    let asteroidParkPositionX: Float = 400 // Position (Minus) Ende der Bewegung
    
    var alternateZ = false  // Variable zum Wechseln zwischen 0.0 und Zufallswert

    var startQuaternion = SCNVector4(0, 0, 0, 1)
    var endQuaternion = SCNVector4(0, 0, 0, 1)
    var cameraBaseOrientation: simd_quatf = simd_quatf(real: 1, imag: SIMD3(0, 0, 0)) // Standard-Quaternion
    var currentFactor: Float = 1.0
    let interpolationSpeed: Float = 0.1 // Schrittweite pro Frame
    var shipDampingFactor: Float = 0.2  // Je kleiner, desto weicher
    
    // Chatty neu
    var lastDelta: SIMD3<Float> = .zero  // Letzte Bewegungsänderung
    var isTouching: Bool = false  // Ob Touch aktiv ist
    var lastDeltaX: Float = 0.0
    var isTouchingX: Bool = false  // Touch für X-Achse aktiv?
    var lastCameraMovement = SIMD3<Float>(0, 0, 0)  // Letzte Bewegung
    // Schnelles nachziehen Höhere Werte/Niedrigere Werte trägeres Nachziehen
    let cameraDampingFactor: Float = 0.1
    var starNodes = [SKShapeNode]()  // Array für Sterne
    var crossOverlay: CrossOverlayView?
    var activeTouches: [UITouch: CGPoint] = [:]  // Speichert die letzte Position jedes aktiven Touches

    
    // moveShipAccelerationBonusRound()
    var twinShipBonusVelocity: SIMD3<Float> = .zero  // Aktuelle Geschwindigkeit
    let accelerationFactor: Float = 2.0         // Wie stark das Schiff beschleunigt
    let dampingFactorAcceleration: Float = 0.95 // Dämpfung (0.0 = keine, 1.0 = sofortiger Stopp)
    var rightViewCamera = SIMD3<Float>(0, 0, 1) // Blickrichtung rechts lokal
    var upViewCamera = SIMD3<Float>(0, 1, 0)
    
    // Für updateShipMotion()
    var currentFactorBonusRound: Float = 0.0
    let interpolationSpeedBonusRound: Float = 0.05
    var startPosition: SIMD3<Float> = SIMD3<Float>(0.0, 0.0, 0.0)
    
    var timerUpdateCollisionDisplay: Timer?
    var displayNodeByName: [String: SCNNode] = [:] 
    var displayScene: SCNScene!
    var boundingCube: SCNNode!
    var timers: [String: Timer] = [:]
    var bonusRoundIsReached: Bool = false   // Punkte für mögliche Bonus Runde erreicht
    var bonusRoundIsEnabled: Bool = false   // Bonus Runde nicht freigeschaltet
    
    // Temporäre Variable
    var SCNVector: Float = 0.0
    var counter: Int = 0    // Aktuell für den Ausdruck in PhysicsWorld
    var switchContainers: [UIView] = []
    var Backup: Bool = false
    var Backup2: Bool = true
    var addDebugAxesIsOn: Bool = false
    
    var startImageView: UIImageView!
    
    // MARK: System Variable
    var gameScene: SCNScene!
    var hudScene: SKScene!  // Für die Labels
    var scnView: SCNView!   // Hauptview des Controllers
    var displayView: SCNView! // Für das Collision Display
    
    // Zwischenspeicher für gespeichertes Hintergrundbild zur Spiele-View
    var selectedBackgroundImage: UIImage? = nil
    
    // MARK: Label
    var scoreLabel: SKLabelNode!
    var scoreLabelValue: SKLabelNode!
    var timeCounterLabel: SKLabelNode!
    var timeCounterLabelValue: SKLabelNode!
    var centerLabel1: SKLabelNode!
    var centerLabel2: SKLabelNode!
    var bonusLabel: SKLabelNode!
    var labelGameLevel: SKLabelNode!
    var labelGameLevelValue: SKLabelNode!
    var labelRemainingLives: SKLabelNode!
    var labelRemainingLivesValue: SKLabelNode!
    var startLevelXLabel: SKLabelNode!
    var readyLabel: SKLabelNode!
    var labelContainerInfo: [SKLabelNode] = []
    var labelContainerCenter: [SKLabelNode] = []
    
    //MARK: Kamera
    var cameraNode = SCNNode()
    var camera = SCNCamera()
    var cameraDisplayNode = SCNNode()
    var cameraDisplay = SCNCamera()
    var explosionNode = SCNNode()
    var explosion = SCNParticleSystem() // Explosion Asteroids
    
    // MARK: Fire
    var fireNodeRight: [SCNNode] = []
    var fireNodeLeft: [SCNNode] = []
    var lastTouchPosition: CGPoint? // Touchposition für Fire
    let fireMoveBorderX: Float = 300 // Grenze (iPhone 16 Pro Max) rechts dann verschwindet Fire
    //TODO: .disruption wird noch nicht eingesetzt. Eventuell ab Level 2 ???
    var explosionType: ExplosionType = .fragmentation //.disruption
    var fireType: FireType = .single
   
    
    // MARK: Booster für twinShip
    var leftBoostNode = SCNNode()
    var rightBoostNode = SCNNode()
    
    // MARK: SpaceInvader
    var spaceInvaderState: SpaceInvaderState = .idle
    var animationSlowDownInvader: Int = 0
    //var spaceInvaderIsOnScreen: Bool = false // Wenn true dann SpaceInvader isOnScreen
    var isStartSpaceInvader: Bool = false // SpaceInvader beginnt ganz am Anfang
    var isStartToMoveInvader: Bool = false // Invaderbewegung bewegt sich (vor Rotation)
    var isStartChaosInvader: Bool = false // Hilfsvariable für Circle Invader
    var isCircleSpaceInvader: Bool = false  // SpaceInvader ist beim Circle
    var isCircleFinishedInvader: Bool = false // Circle ist zu Ende
    var isCubeFallDownCanceledInvader: Bool = false // CubeFallDown wurde abgebrochen
    var isSpaceInvaderEndTimerEnabled: Bool = true // Steht während .rotate
    var isStartToRotateByFireHitInvader: Bool = false // PhysicsWorld meldet eine Kollision
    var isCollisionDebounced: Bool = false
    var isCubeFallingDownInvader: Bool = false // Ende Animation mit CubeFallDown
    var isShieldStartToChaseTwinShip: Bool = false    // Shield verfolgt TwinShip
    var isHitInvaderFirst: Bool = false
    var isDoubleHitAvoid: Bool = true // SpaceInvader keine zwei Treffer pro Schuss
    var isSpeedUpInvader: Bool = false // In der Rotationsfase Drehgeschwindigkeit wird erhöht
    var spaceInvaderCubeCounter = 1 // Damit nicht zwei oder mehr Cubes auf einmal getroffen werden
    var rotationSpeedInvader: Float = 0
    var rotationSpeedMaxInvader: Float = 0
    var indexIsHitNodeNumber: Int = 0
    //var indexIsHitRight: Int = 0
    var indexCubePopUp: Int = 0
    var indexFallDown: Int = 47 // Bei 46 Cubes für Cube Fall Down
    var PositionCenterInvader = SCNVector3(x: 0, y: 0, z: 0)
    var durationRangeInvader: ClosedRange<TimeInterval> = 3.0...6.0
    //var spaceInvaderOnScreenTime: TimeInterval = 0
    var spaceInvaderFramesRefreshTime: TimeInterval = 0
    var circlePositionX: Float = 0
    var circlePositionY: Float = 0
    var circlePositionZ: Float = 0
    var scaleTwinShipShield: CGFloat = 0
    var pumpUpOfSpace: Float = 0
    var rotatenAngleRotation: Float = 0
    var rotationAngleInChaosState: Float = 0 //#10
    let redMaterial = SCNMaterial()
    var spaceInvaderBase: SCNNode!
    var spaceInvader: SCNNode!
    var spaceInvaderArray: [SCNNode] = []
    var spaceInvaderNodeDictionary: [String: SCNNode] = [:]
    var nodeSpaceInvader: SCNNode!
    var timerSpaceInvader: Timer?
    var enemySegmentTimer: Timer?
    var timerAnimateSpaceInvader: Timer?
    var angleArrayChaos = Array(repeating: Float(0), count: 47)
    var circlePositionXArray = Array(repeating: Float(30), count: 47)
    var circlePositionYArray = Array(repeating: Float(30), count: 47)
    var circlePositionZArray = Array(repeating: Float(0), count: 47)
    var spaceInvaderMoveBorderX: Float = 300
    var moveLeftInvader: Float = -1 // Invaderbewegung in X-Richtung
    var moveDownInvader: Float = -1 // Invaderbewegung in Y-Richtung
    var velosityMoveStepOfInvader: Float = 0.1 // Invadergeschwindigkeit-Index
    var moveStepXDirection: Float = 0 // Die Koordinaten der Invaderbewegung in X-Richtung ...
    var moveStepYDirection: Float = 0 // ... und die Y-Richtung

    let spaceInvaderCubePositionX: [[Int]] = [ // Zugriff über [Zeile Y Wert]  [Spalte X Wert]
        [0],    // Zeile entspricht Y Wert
        [99,99,-3,99,99,99,99,99,3,99,99,],
        [99,99,99,-2,99,99,99,2,99,99,99,],
        [99,99,-3,-2,-1,0,1,2,3,99,99,],
        [99,-4,-3,99,-1,0,1,99,3,4,99,],
        [-5,-4,-3,-2,-1,0,1,2,3,4,5,],
        [-5,99,-3,-2,-1,0,1,2,3,99,5,],
        [-5,99,-3,99,99,99,99,99,3,99,5,],
        [99,99,99,-2,-1,99,1,2,99,99,99,]
    ]
    let spaceInvaderCubePositionY: [[Int]] = [
        [0],
        [99,99,4,99,99,99,99,99,4,99,99,],
        [99,99,99,3,99,99,99,3,99,99,99,],
        [99,99,2,2,2,2,2,2,2,99,99,],
        [99,1,1,99,1,1,1,99,1,1,99,],
        [0,0,0,0,0,0,0,0,0,0,0,],
        [-1,99,-1,-1,-1,-1,-1,-1,-1,99,-1,],
        [-2,99,-2,99,99,99,99,99,-2,99,-2,],
        [99,99,99,-3,-3,99,-3,-3,99,99,]
    ]
    let spaceInvaderCubePositionNode: [[Int]] = [
        [0],
        [0,0,1,0,0,0,0,0,2,0,0,],
        [0,0,0,3,0,0,0,4,0,0,0,],
        [0,0,5,6,7,8,9,10,11,0,0,],
        [0,12,13,0,14,15,16,0,17,18,0,],
        [19,20,21,22,23,24,25,26,27,28,29,],
        [30,0,31,32,33,34,35,36,37,0,38,],
        [39,0,40,0,0,0,0,0,41,0,42,],
        [0,0,0,43,44,0,45,46,0,0,0,]
    ]
    
    let spaceInvaderPosX: [Float] =  [0,
                                      -3,3,
                                      -2,2,
                                      -3,-2,-1,0,1,2,3,
                                      -4,-3,-1,0,1,3,4,
                                      -5,-4,-3,-2,-1,0,1,2,3,4,5,
                                      -5,-3,-2,-1,0,1,2,3,5,
                                      -5,-3,3,5,
                                      -2,-1,1,2]
    let spaceInvaderPosY: [Float] = [0,
                                     4,4,
                                     3,3,
                                     2,2,2,2,2,2,2,
                                     1,1,1,1,1,1,1,
                                     0,0,0,0,0,0,0,0,0,0,0,
                                     -1,-1,-1,-1,-1,-1,-1,-1,-1,
                                     -2,-2,-2,-2,
                                     -3,-3,-3,-3]
    
    // MARK: UIButton
    var bonusRoundButton: UIButton!
    var nextLevelButton: UIButton!
    
    // MARK: SpaceProbe
    var spaceProbeBodyNode: SCNNode!
    var spaceProbeTopNode: SCNNode!
    var spaceProbeBottomNode: SCNNode!
    var spaceProbeParentNode: SCNNode!
    var timerOnScreenTimeSpaceProbe: Timer?
    var timerWaitForDelaySpaceProbe: Timer?
    var moveSpaceProbeSequence: SCNAction?
    var animateSpaceProbeTopNodeSequence: SCNAction?
    var animateSpaceProbeBottomNodeSequence: SCNAction?
    //var spaceProbeTimerMin: Float = 0
    //var spaceProbeTimerMax: Float = 0
    var spaceProbeOnScreenTime: TimeInterval = 0
    var spaceProbeStartDelay: TimeInterval = 0
    var raiseAndLowerAgainSpaceProbe: Bool = false // Ober- und Unterteil anheben und wieder zurück
    var spaceProbeIsOnScreen: Bool = false
    var spaceProbeState: SpaceProbeState = .idle
    
    // MARK: Colorful Stars
    var starYellowNode: SCNNode!
    var starRedNode: SCNNode!
    var starGreenNode: SCNNode!
    var starsCounter: Int = 0    // Bis zu drei Sterne on Screen
    var isContactStarsCooldownActive = false
    var colorfullStarsOnScreenTime: TimeInterval = 30
    var timerOnScreenColorfullStars: Timer?
    var colorfullStarsState: ColorfullStarsState = .idle

    
    //MARK: BigFlash
    var bigFlashState: BigFlashState = .idle
    var bigFlashStartDelay: TimeInterval = 0
    var bigFlashOnScreenTime: TimeInterval = 0
    var BigFlash: [UIImage] = []
    var bigFlashIsOnScreen: Bool = false
    var bigFlashNode: SCNNode!
    var bigFlashParent: SCNNode!
    var timerBigFlash: Timer?
    var timerStartBigFlash: Timer?
    var timerEndBigFlash: Timer?
    var bigFlashOnScreenDuration: Double = 0
    
    //Test
    var bigFlashCountdown: Double = 0
    
    var timerBallWallForInvader: Timer?
    var material = SCNMaterial()
    var isContactBigFlashCooldownActive = false
    
    // MARK: Punkte Zähler
    var secondsCounter: Int = 0
    var pointsUpdateCount: Int = 3000 // 0
    var score: Float = 0
    
    //MARK: Stars
    var pointNode: [SCNNode] = [] // Es war voller Sterne
    var starSpeed: [Float] = []
    var increaseSpeedFactor: Float = 0.01
    var accelerateStars: Bool = true
    var slowDownStars: Bool = false
    var startBackgroundStars: Bool = false
    
    // MARK: Asteroid
    var asteroidMaxNumberOnScreen: Int = 0 // Max Anzahl auf einmal auf dem Schirm
    var numberCounterAsteroidsLabel: SKLabelNode!
    var numberCounterAsteroidsLabelValue: SKLabelNode!
    var asteroid: SCNNode! // Hilf-Node
    var asteroidNode: [SCNNode] = [] // Array AsteroidNode
    var asteroidNodeDictionary: [String: SCNNode] = [:] // Dictionary zur Verwaltung von Nodes
    var bonusPointsTimer: Timer? // Zum Hochzählen der Bonuspunkte
    var offsetNumber: Int = 0 // Beginn Burst-Asteroids im Array
    var asteroidXPosition: [Float] = []
    var rotationForce: Float = 0
    var asteroidTime: TimeInterval = 0
    var doubleHitAsteroid: String = "9999"
    var timerAsteroid: Timer?
    var asteroidStartPositionX: Float = 300 // Startposition rechts aussen
    var asteroidStartBorderY: Float = 80 // In Bonus Runde sind es 500
    var asteroidStartBorderZ: Float = 50 //*01 500 // Für das Rechteck in Y und Z
    var isContactAsteroidCooldownActive: Bool = false
    var AsteroidStartValueOfBurstOne: Int = 0 //*02 Zwischenspeicher für Offset der Burstasteroiden
    var asteroidCountMax: Int = 0
    var asteroidCountActive: Int = 0
    
    // MARK: TwinShip
    var twinShipNode: SCNNode!
    var twinShipStartNode: SCNNode!
    var twinShipBonusNode: SCNNode!
    var moveTwinShipSequence: SCNAction?
    var ship: SCNNode!
    var shipDirectionY: Int = 0
    var shipDirectionX: Int = 0
    var shipSpeed: Float = 0
    var shipXPos: [Float] = []
    var shipYPosRight: Float = 0
    var shipYPosLeft: Float = 0
    var shipRotateEnd: Bool = true
    var increasing: Bool = true // Gibt an, ob die Variable wächst oder schrumpft
    var touchActive: Bool = true // Für dir Rückdrehung des Schiffes
    var shipIdleTimer: Timer?
    var startShipOrientation: Bool = false
    
    var collisionSensorNode: SCNNode! // Für die Kollisionserkennung zum Collisionsdisplay
    
    // MARK: TwinShip Steuerung
    var velocity: SCNVector3 = SCNVector3(0, 0, 0) // Bewegungsgeschwindigkeit
    let dampingFactor: Float = 0.9 // Dämpfungsfaktor (zwischen 0 und 1)
    let inputSensitivity: Float = 0.01 // Empfindlichkeit der Eingabe
    let rotationSensitivity: Float = 0.5 // Wie stark die Bewegung die Drehung beeinflusst
    let lateralSensitivity: Float = 0.01 // Sensitivität für seitliche Bewegung
    var steeringPositionX: Float = 0    // Backup Wert für Positionsdifferenz
    var steeringPositionY: Float = 0
    var shipSteering: Int = 1
    
    
    //MARK: Shield
    var shieldNode = SCNNode()
    var twinShipShieldBlink: Bool = false
    
    //MARK: BigFlash
    var blinkBigFlashValue: CGFloat = 0
    var increasingBigFlashValue: Bool = true
    var increasingBigFlash: Bool = true
    var blinkShieldValue: CGFloat = 0 // shipShield
    var shieldBigFlashNode = SCNNode()
    
    //MARK: TwinShip Booster
    var fireBoost = SCNParticleSystem() // ParticleSystem
    var fireBoostNode = SCNNode() // Node die als Emitter dient
    
    // MARK: Level
    var timerUpdateHUD: Timer?
    var levelCount: Int = 0  // Versuch Bonus Round Start - wieder auf 0 setzen - Level auf 0 gesetzt wird in func nextLevel() hochgezählt
    var levelClear: Bool = false
    var player1: String = "Günter"

    // MARK: BallWall
    var ballWallState: BallWallState = .idle
    var ballWallStartDelay: TimeInterval = 0
    var ballUp: SCNNode!
    var ballDown: SCNNode!
    var ballDoor: SCNNode!
    var ballWallNodeUp: [SCNNode] = []
    var ballWallNodeDown: [SCNNode] = []
    var ballWallNodeDoor: [SCNNode] = []
    var timerAnimateBallWall: Timer?
    var timerBallWall: Timer?
    var ballPositionY: Float = -20
    var buildWall: Bool = true
    var ballWallColorCounter: Int = 0
    var ballWallTime: TimeInterval = 0
    var ballExplosion = SCNParticleSystem()
    var ballExplosionNode = SCNNode()
    
    // Enemys Koordinatenbegrenzung
    let moveObjectRangeX: ClosedRange<Float> = -100...150
    var moveObjectRangeY: ClosedRange<Float> = -70...70
    var bigFlashOnScreenDurationRange: ClosedRange<TimeInterval> = 30.0...40.0
    
    var screenHeight: CGFloat = 0
    var pointsDifferenzBackup: Int = 0
    var lightNode = SCNNode()
    var keyLightNode = SCNNode()
    var fillLightNode = SCNNode()
    var backLightNode = SCNNode()
    var ambientLightNode = SCNNode()
    var playerLives: Int = 3
    var gameIsRunning: Bool = false
    var gameIsPaused: Bool = true   // Nur Sternebewegung
    var bonusRoundIsActive: Bool = false // Nach Enabled wird BonusRound gestarted
    var isReadyToRender: Bool = false
    var startLevel = true
    var startAnimation: Bool = false
    
    // Anpassung Framerate an Animationsgeschwindigkeit
    var lastUpdateTime: TimeInterval = 0         // Zeitpunkt des letzten Frames
    var shouldUpdateRenderer: Int = 0      // Zeitakkumulator für Bewegungssteuerung
    let updateInterval: TimeInterval = 1 / 15 // Zeitintervall für 30 Bewegungen pro Sekunde
    

    //MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        LevelManager.shared.delegate = self
        
        //Setup UI und Ansicht
        setupScene()
        setupView()
        setupStartImageView()
        setupCamera()
        setupLights()
        setupLabel()
        setupLabelContainer()
        setupNextLevelButton()
        setupBonusRoundButton()
        setupCollisionDisplay()
        setupSettingsView()
        setupCanvasView()
        startDisplayLink()
        
        createTwinShip()
        createTwinShipStart()
        createTwinShipBonus()
        shieldNode = setupShield(
                                at: parkPositionOfShield,
                                category: .twinShip,
                                collideWith: [.fire, .asteroid, .spaceInvader],
                                contactTest: [.fire])
       
        createStars()
        // createTwinShipCollisionDetector() // Noch implementieren
        setupTwinShipBoost()
        
        // Create Enemys
        createSpaceInvader()
        createSpaceProbe()
        createBigFlash()
        
        // Erzeugung während des SplashScreens um Ruckler zu vermeiden
        createObjectPool()
        // Zuweisung der restlichen let/var und Level let/var
        nextLevelUpdate()

        // Wegen Erstellung der PoolNodes StartScreen 5 Sekunden lang anzeigen ...
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
            //StartButtons anzeigen
            ButtonBuilder.addMainMenuButtons(
                to: self.view,
                startingY: DeviceConfig.layout.switchPositionOffsetY,
                target: self,
                switchContainers: &switchContainers
            )
            // "Prepare for Launch" ausblenden
            welcomeLabelFadeOut()
            
            // Vorher gespeicherte Werte lesen
            SoundManager.shared.isSoundOn = UserDefaults.standard.bool(forKey: "isSoundOn")
            isMusicOn = UserDefaults.standard.bool(forKey: "isMusicOn")
            if isMusicOn {
                SoundManager.shared.playBackgroundMusic()  // Sound abspielen
            }
            addDebugAxesIsOn = UserDefaults.standard.bool(forKey: "addDebugAxesIsOn")
            startAnimation = UserDefaults.standard.bool(forKey: "startAnimation")
            
            // Schalter auf gespeicherte Werte setzen
            soundSwitch.isOn = SoundManager.shared.isSoundOn
            musicSwitch.isOn = isMusicOn
            debugAxesSwitch.isOn = addDebugAxesIsOn
            startAnimationSwitch.isOn = startAnimation
            //TODO: Start-Rotation funktioniert noch nicht
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
//                showAndRotateTwinShip()
//            }
        }
}
    //MARK: Ende ViewDidLoad
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let scnView = self.view as? SCNView else { return }
        
        // Falls das Overlay noch nicht existiert, erst dann hinzufügen
        if crossOverlay == nil {
            let overlay = CrossOverlayView(frame: scnView.bounds)
            overlay.isHidden = true  // Erst ausblenden
            scnView.addSubview(overlay)
            scnView.bringSubviewToFront(overlay) // Chatty View neu
            crossOverlay = overlay
        }
    }

    // Delegate-Methode wird aufgerufen, wenn sich Werte ändern
    func updateAsteroidValues(_ asteroidConfig: AsteroidConfig) {
        asteroidStartDelay = asteroidConfig.startDelay
        asteroidCountMax = asteroidConfig.countMax
        asteroidScale = asteroidConfig.scale
        asteroidMaxNumberOnScreen = asteroidConfig.maxNumberOnScreen
        asteroidBurstStartValue = asteroidConfig.startValueOfBurstOne
        asteroidStartBorderY = asteroidConfig.startBorderY

        print("Asteroid-Werte aktualisiert im GameViewController")
    }

    // Implementierung der zweiten Delegate-Methode
    func updateEnemyValues(_ enemyConfig: EnemyConfig) {
        //spaceInvaderSpawnDelay = enemyConfig.invaderSpawnDelay
        //spaceInvaderOnScreenTime = enemyConfig.invaderOnScreenTime
        spaceInvaderFramesRefreshTime = enemyConfig.invaderFramesRefreshTime
        spaceProbeStartDelay = enemyConfig.probeStartDelay
        spaceProbeOnScreenTime = enemyConfig.probeOnScreenTime
        bigFlashStartDelay = enemyConfig.flashStartDelay
        bigFlashOnScreenTime = enemyConfig.flashOnScreenTime
        ballWallStartDelay = enemyConfig.wallStartDelay
        moveObjectRangeY = enemyConfig.moveObjectRangeY
        print("SpaceInvader-Werte aktualisiert im GameViewController")
    }

    func setupScene() {
        // create a new scene
        gameScene = SCNScene(named: "art.scnassets/world.scn")!

        // Asteroid
        asteroid = SCNScene(named: "art.scnassets/asteroid.scn")!.rootNode.childNodes.first!
        
        spaceInvaderBase = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
        spaceInvader = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.2))
        redMaterial.diffuse.contents = UIColor.red
        spaceInvader.geometry?.materials = [redMaterial]
        
        //Twinship
        twinShipNode = SCNScene(named: "art.scnassets/twinship.scn")!.rootNode.childNodes.first!
        twinShipBonusNode = SCNScene(named: "art.scnassets/twinshipbonus.scn")!.rootNode.childNodes.first!
        twinShipStartNode = SCNScene(named: "art.scnassets/twinShipStartAnimation.scn")!.rootNode.childNodes.first!
        
        // Coloreful Stars
        starRedNode = SCNScene(named: "art.scnassets/SternRot.scn")!.rootNode.childNodes.first!
        starGreenNode = SCNScene(named: "art.scnassets/SternGruen.scn")!.rootNode.childNodes.first!
        starYellowNode = SCNScene(named: "art.scnassets/SternGelb.scn")!.rootNode.childNodes.first!
        
        // SpaceProbe Body, Oberteil und Unterteil
        spaceProbeBodyNode = SCNScene(named: "art.scnassets/SpaceProbe.scn")!.rootNode.childNode(withName: "Body", recursively: true)!
        spaceProbeTopNode = SCNScene(named: "art.scnassets/SpaceProbe.scn")!.rootNode.childNode(withName: "Oberteil", recursively: true)!
        spaceProbeBottomNode = SCNScene(named: "art.scnassets/SpaceProbe.scn")!.rootNode.childNode(withName: "Unterteil", recursively: true)!
              
        // 200 images of BigFlash for the continuous animation
        for i in 1...200 {
            let imageName = String(format: "BigFlash%03d@2x.png", i) // Beispiel: image_001.png, image_002.png
            if let image = UIImage(named: imageName) {
                BigFlash.append(image)
            }
        }

        // Das Scene soll PhysicsWorld unterstützen
        gameScene.physicsWorld.contactDelegate = self
        
        let suffix = DeviceConfig.isIPad ? "Pad" : "Phone"
        let imageName = "Default" + suffix
 // TODO: Printanweisungen löschen
        if let image = UIImage(named: imageName) {
            print("Bild geladen: \(imageName)")
            gameScene.background.contents = image
        } else {
            print("Bild NICHT gefunden: \(imageName)")
        }

        //gameScene.background.contents = UIImage(named: "SkyScene3.png")
    }
     //--------------------------------------------------------------------------------------
  
     
     // MARK: MAINVIEW
     func setupView() {
         
         scnView = self.view as? SCNView                    // SceneKit-View erstellen und zur Ansicht hinzufügen
         scnView.preferredFramesPerSecond = 60             // Sollte reichen
         scnView.scene = gameScene                        // SceneKit-Scene erstellen
         scnView.allowsCameraControl = false             // allows the user to don't manipulate the camera
         scnView.showsStatistics = false                // show statistics
         scnView.backgroundColor = UIColor.clear       // configure the view
         scnView.delegate = self                      // Setze den Delegate des SceneView auf die aktuelle Klasse
         scnView.isPlaying = true                    // Beginne mit dem Rendern
         scnView.isMultipleTouchEnabled = true         // Eigentlich Standard
         
         //scnView.debugOptions = [.showLightInfluences, .showPhysicsShapes]

         hudScene = SKScene(size: CGSize(width: scnView.bounds.size.width, height: scnView.bounds.size.height))

         // CrossOverlay hinzufügen
         if crossOverlay == nil {
             crossOverlay = CrossOverlayView(frame: scnView.bounds)
             crossOverlay?.isHidden = true  // Startet unsichtbar
             scnView.addSubview(crossOverlay!)
         }

         debugHUD = DebugHUD()
         debugHUD.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(debugHUD)
         
         // Position (X, Y) des HUDs
         NSLayoutConstraint.activate([
             debugHUD.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
             debugHUD.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 320)
         ])

     }

    
    // *** Wird vom StartButton aufgerufen ***
// MARK: - Startscreen mit Auswahl
    @objc func startGameView() {
        if let startImageView = self.view.viewWithTag(ViewTags.startImageView),
           let startButton = self.view.viewWithTag(ViewTags.startButton) as? UIButton {
            
// TODO: Löschen wenn funktioniert. Das gewählte Bild setzen, falls es existiert
            if let selectedImage = selectedBackgroundImage {
                gameScene.background.contents = selectedImage
            }
            
            // Button ausblenden
            // Animation in Animation da sonst die UIButton im Spielbild zu lange zu sehen sind
            UIView.animate(
                withDuration: 1.0,
                animations: { [self] in
                    // Button und die Switches ausblenden (erste Animation)
                    startButton.alpha = 0.0
                    switchContainers.forEach { $0.alpha = 0.0 }
                    settingsView?.alpha = 0.0
                },
                completion: { [self] _ in
                    // ImageView ausblenden (zweite Animation)
                    UIView.animate(
                        withDuration: 1.0,
                        animations: {
                            startImageView.alpha = 0.0
                        },
                        completion: { [self] _ in
                            // Entfernen der Subviews nach der Animation
                            startImageView.removeFromSuperview()
                            startButton.removeFromSuperview()
                            switchContainers.forEach { $0.removeFromSuperview() }
                            switchContainers.removeAll() // Array leeren
                            
                            // Animation oder starte Spiel
                            if startAnimation {
                                startGameIntro()
                            } else {
                                startGameDisplay()
                            } // Spiel starten
                        }
                    )
                }
            )
        }
        // Wegen zeitaufwendiger PhysicsBody (ruckler) jetzt erst PoolNodes to Parkosition
        poolNodesMoveToParkPosition()
    }
    
    // Start Level xx anzeigen
    func startGameDisplay() {
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        let wait = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        
        // Einblenden drei Sekunden warten dann wieder ausblenden
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut])
               
        // Schriftzug "Start Level"
        startLevelXLabel.text = "Start Level: \(levelCount)" // Text aktualisieren
        startLevelXLabel.alpha = 0
        startLevelXLabel.isHidden = false
        startLevelXLabel.run(sequence)
        
        // Schriftzug "Ready"
        readyLabel.alpha = 0
        readyLabel.isHidden = false
        readyLabel.run(sequence)

        gameIsRunning = true
        
        secondsCounter = 0  // Reset Variable
        startTimerUpdateHUD()
        updateHUD() //
        
        // TODO: Eventuell rückbauen - Booster (Particle-System ausrichten und starten
//        setupShipBoost(for: twinShipNode, with: TwinShipBoosterConfig.standard)

        // Die Zählerstände einblenden ...
        for SKLabelNode in labelContainerInfo {
            SKLabelNode.alpha = 0
            SKLabelNode.isHidden = false
            SKLabelNode.run(fadeIn){ [self] in
                // ... danach Game starten.
                twinShipNode.isHidden = false
                startBackgroundStars = true
            }
        }
        
        // Zum Start Ship einlaufen lassen und Timer starten
        if levelCount == 1 {
            twinShipNode.worldPosition.x = -400
            
            // Booster (Particle-System ausrichten und starten
            setupShipBoost(for: twinShipNode, with: TwinShipBoosterConfig.standard)
            
            // Ship einlaufen lassen
            let moveInTwinShip = SCNAction.move(to: SCNVector3(x: -180, y: 0, z: 0), duration: 3)
            moveInTwinShip.timingMode = .easeOut
            twinShipNode.runAction(moveInTwinShip) { [self] in
                
                // Watchdog für EnemyManager erstellen
//                watchdog = FunctionWatchdog(
//                    checkInterval: 5.0, // Alle 5 Sekunden prüfen
//                    timeout: 60.0       // Wenn länger als 60 Sekunden nichts kommt, ausführen:
//                ) {
//                    self.scheduleNextEnemy()
//                }
                gameIsPaused = false
                scheduleNextEnemy(.none)
                startTimerAsteroid()
                startTimerBallWall()
                //#21
                DispatchQueue.main.async { [self] in
                    //showOverlay() //TODO: Wieder einschalten
                    animateCollisionDisplayWithScale()
                }
            }
        }
    }
    
    func setupStartImageView() {
        // UIImageView initialisieren
        startImageView = UIImageView()
        startImageView.frame = self.view.bounds
        startImageView.contentMode = .scaleAspectFill
        startImageView.tag = ViewTags.startImageView
        startImageView.backgroundColor = .red
        startImageView.translatesAutoresizingMaskIntoConstraints = true
        // Hintergrundbild setzen
        changeBackgroundImage(for: startImageView, baseName: "Default")
        
        // UILabel mit mehrzeiligem Text und angepasstem Zeilenabstand
        welcomeLabel = UILabel()
        welcomeLabel.textColor = .yellow
        welcomeLabel.textAlignment = .center
        welcomeLabel.numberOfLines = 0  // Wichtig für mehrzeiligen Text
        
        // Attributed String für präzise Kontrolle über Zeilenabstand
        let text = "Prepare\nfor\nLaunch"
        let attributedText = NSMutableAttributedString(string: text)
        
        // Zeilenabstand einstellen (hier: 20 Punkte)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 20
        paragraphStyle.alignment = .center
        
        attributedText.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedText.length)
        )
        
        // Font setzen
        if let customFont = UIFont(name: "PressStart2P-Regular", size: 48) {
            attributedText.addAttribute(
                .font,
                value: customFont,
                range: NSRange(location: 0, length: attributedText.length))
        } else {
            print("Custom Font nicht gefunden!")
            attributedText.addAttribute(
                .font,
                value: UIFont.systemFont(ofSize: 48, weight: .bold),
                range: NSRange(location: 0, length: attributedText.length))
        }
        
        welcomeLabel.attributedText = attributedText
        
        // Positionierung (mit angepasster Höhe für den mehrzeiligen Text)
        positionLabelTopCentered(
            welcomeLabel,
            in: startImageView,
            size: CGSize(width: 1000, height: 200),  // Höhe anpassen
            topOffset: DeviceConfig.layout.welcomeTextYPosition
        )
        
        startImageView.addSubview(welcomeLabel)
        self.view.addSubview(startImageView)
        self.view.sendSubviewToBack(startImageView)
    }
    
    //MARK: CAMERA
    func setupCamera() {
        
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        camera = cameraNode.camera!
        camera.usesOrthographicProjection = true
        // struct DeviceConfig
        camera.orthographicScale = DeviceConfig.layout.orthographicScale
        cameraNode.camera?.zNear = 0.1  // Nahe Clipping-Ebene (muss > 0 sein)
        cameraNode.camera?.zFar = 600
        cameraNode.camera?.fieldOfView = 30
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 100)
        cameraNode.categoryBitMask = ~0  // Damit die Kamera alles sieht
        
        gameScene.rootNode.addChildNode(cameraNode)
        
        //addDebugAxes(to: cameraNode)
        
    }
    
    //MARK: LIGHTS
    func setupLights() {
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.light?.intensity = 600
        lightNode.position = SCNVector3(x: 0, y: 0, z: 500) // (x: 200, y: 0, z: 50)
        gameScene.rootNode.addChildNode(lightNode)
        
        let shieldLightNode = SCNNode()
        let shieldLight = SCNLight()
        shieldLight.type = .omni
        shieldLight.intensity = 1000
        shieldLightNode.light = shieldLight
        shieldLightNode.categoryBitMask = 2
        
        // Versuch shieldNode.addChildNode(shieldLightNode)
        shieldLightNode.position = SCNVector3(x: 400, y: 0, z: 0)
        
        
        // Hauptlicht
        //let keyLightNode = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 1000
        keyLight.castsShadow = true
        keyLightNode.light = keyLight
        keyLightNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        keyLightNode.categoryBitMask = 1
        keyLightNode.isHidden = true
        gameScene.rootNode.addChildNode(keyLightNode)
        
        // Fülllicht
        //let fillLightNode = SCNNode()
        let fillLight = SCNLight()
        fillLight.type = .omni
        fillLight.intensity = 200
        fillLight.color = UIColor(white: 0.8, alpha: 1.0)
        fillLightNode.light = fillLight
        fillLightNode.position = SCNVector3(x: -100, y: 50, z: 50)
        fillLightNode.categoryBitMask = 1
        fillLightNode.isHidden = true
        gameScene.rootNode.addChildNode(fillLightNode)
        
        // Hintergrundlicht
        //let backLightNode = SCNNode()
        let backLight = SCNLight()
        backLight.type = .omni
        backLight.intensity = 500
        backLight.color = UIColor(white: 0.9, alpha: 1.0)
        backLightNode.light = backLight
        backLightNode.position = SCNVector3(x: 0, y: 100, z: -200)
        backLightNode.categoryBitMask = 1
        backLightNode.isHidden = true
        gameScene.rootNode.addChildNode(backLightNode)
        
        // Umgebungslicht
        //let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 1000
        ambientLight.color = UIColor(white: 0.3, alpha: 1.0)
        ambientLightNode.light = ambientLight
        ambientLightNode.categoryBitMask = 2
        ambientLightNode.isHidden = true
        gameScene.rootNode.addChildNode(ambientLightNode)
    }
    
}

