

import Foundation
import AVFoundation
import UIKit

protocol LevelManagerDelegate: AnyObject {
    func updateAsteroidValues(_ asteroidConfig: AsteroidConfig)
    func updateEnemyValues(_ enemyConfig: EnemyConfig)
}

class LevelManager {
    static let shared = LevelManager()
    
    weak var delegate: LevelManagerDelegate?

    var levelCount: Int = 0
    var difficulty: LevelType = .easy

    var asteroidValues: AsteroidConfig {
        LevelConfig.asteroidConfig(for: difficulty, level: levelCount)
    }

    var enemyValues: EnemyConfig {
        LevelConfig.enemyConfig(for: difficulty)
    }

    func nextLevel() {
        levelCount += 1  // Level erhöhen
        
        print("Game-Level \(levelCount) - Mode: \(difficulty)")
        delegate?.updateAsteroidValues(asteroidValues)
        delegate?.updateEnemyValues(enemyValues)
    }
    
    /// Wird beim Difficulty-Wechsel genutzt
    func applySettingsForDifficulty() {
        print("Difficulty changed → apply settings, no level-up")
        delegate?.updateAsteroidValues(asteroidValues)
        delegate?.updateEnemyValues(enemyValues)
    }
}

