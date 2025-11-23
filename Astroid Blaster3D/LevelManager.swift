

import Foundation

protocol LevelManagerDelegate: AnyObject {
    func updateAsteroidValues(_ asteroidConfig: AsteroidConfig)
    func updateEnemyValues(_ enemyConfig: EnemyConfig)
}

class LevelManager {
    static let shared = LevelManager()
    
    weak var delegate: LevelManagerDelegate?

    var levelCount: Int = 1
    var difficulty: LevelType = .easy

    var asteroidValues: AsteroidConfig {
        LevelConfig.asteroidConfig(for: difficulty)
    }

    var enemyValues: EnemyConfig {
        LevelConfig.enemyConfig(for: difficulty)
    }

    func nextLevel() {
        print("Game-Level \(levelCount) - Mode: \(difficulty)")
        delegate?.updateAsteroidValues(asteroidValues)
        delegate?.updateEnemyValues(enemyValues)
    }
}

