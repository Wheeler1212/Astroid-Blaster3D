//
//  SoundManager.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 21.04.25.
//

import AVFoundation
import AudioToolbox

import AVFoundation
import AudioToolbox

class SoundManager {
    
    // Singleton Instanz
    static let shared = SoundManager()
    
    // Öffentliche Eigenschaften
    var isSoundOn: Bool = true {
        didSet {
            // Musik stummschalten wenn Sounds aus sind
            backgroundPlayer?.volume = isSoundOn ? currentMusicVolume : 0
        }
    }
    
    // Private Eigenschaften
    private var backgroundPlayer: AVAudioPlayer?
    private var currentMusicVolume: Float = 0.7
    
    private var fireShotSoundID: SystemSoundID = 0
    private var rockExplosionSoundID: SystemSoundID = 0
    private var ballWallSoundID: SystemSoundID = 0
    private var ballDoorSoundID: SystemSoundID = 0
    private var spaceProbeSoundID: SystemSoundID = 0
    private var spaceInvaderSoundID: SystemSoundID = 0
    private var starBonusSoundID: SystemSoundID = 0
    
    // Privater Initializer
    private init() {
        configureAudioSession()
        loadAllSounds()
    }
    
    // MARK: - Audio Session Konfiguration
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession Konfigurationsfehler: \(error)")
        }
    }
    
    // MARK: - Sound Laden
    private func loadAllSounds() {
        loadSound(named: "lasergun", id: &fireShotSoundID)
        loadSound(named: "rocksexplosion", id: &rockExplosionSoundID)
        loadSound(named: "ballWall", id: &ballWallSoundID)
        loadSound(named: "ballDoor", id: &ballDoorSoundID)
        loadSound(named: "ghost", id: &spaceProbeSoundID)
        loadSound(named: "spaceinvader", id: &spaceInvaderSoundID)
        loadSound(named: "starBonusBell", id: &starBonusSoundID)
    }

    private func loadSound(named name: String, id: inout SystemSoundID) {
        if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            AudioServicesCreateSystemSoundID(url as CFURL, &id)
        }
    }

    // MARK: - Soundeffekte
    func playFireShot() { playSound(id: fireShotSoundID) }
    func playRockExplosion() { playSound(id: rockExplosionSoundID) }
    func playBallWall() { playSound(id: ballWallSoundID) }
    func playBallDoor() { playSound(id: ballDoorSoundID) }
    func playSpaceProbe() { playSound(id: spaceProbeSoundID) }
    func playSpaceInvader() { playSound(id: spaceInvaderSoundID) }
    func playStarBonus() { playSound(id: starBonusSoundID) }

    private func playSound(id: SystemSoundID) {
        guard isSoundOn else { return }
        AudioServicesPlaySystemSound(id)
    }

    // MARK: - Musiksteuerung
    func playBackgroundMusic() {
        guard let player = loadPlayer(for: "hotFireBelow") else { return }
        
        backgroundPlayer = player
        backgroundPlayer?.numberOfLoops = -1
        backgroundPlayer?.volume = isSoundOn ? currentMusicVolume : 0
        backgroundPlayer?.play()
    }

    func stopBackgroundMusic() {
        backgroundPlayer?.stop()
        backgroundPlayer = nil
    }
    
    func setMusicVolume(_ volume: Float) {
        currentMusicVolume = volume
        backgroundPlayer?.volume = isSoundOn ? volume : 0
    }
    
    // MARK: - Player Hilfsfunktion
    private func loadPlayer(for resource: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else {
            print("Sounddatei nicht gefunden: \(resource)")
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("Fehler beim Laden von \(resource): \(error)")
            return nil
        }
    }
    
    // MARK: - Cleanup
    deinit {
        // SystemSoundIDs freigeben
        AudioServicesDisposeSystemSoundID(fireShotSoundID)
        AudioServicesDisposeSystemSoundID(rockExplosionSoundID)
        AudioServicesDisposeSystemSoundID(ballWallSoundID)
        AudioServicesDisposeSystemSoundID(ballDoorSoundID)
        AudioServicesDisposeSystemSoundID(spaceProbeSoundID)
        AudioServicesDisposeSystemSoundID(spaceInvaderSoundID)
        AudioServicesDisposeSystemSoundID(starBonusSoundID)
    }
}

