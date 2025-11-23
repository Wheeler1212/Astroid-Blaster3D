//
//  Helper.swift
//  Astroid Blaster3D
//
//  Created by Günter Voit on 14.01.25.
//

import SceneKit

//FIXME: TimeInterval on enum
//extension SpaceProbeState {
//    var timeSpent: TimeInterval {
//        get {
//            return EnemyStateManager.shared.getTime(for: .spaceProbe, state: "\(self)")
//        }
//        set {
//            EnemyStateManager.shared.incrementTime(for: .spaceProbe, state: "\(self)", by: newValue)
//        }
//    }
//}

extension SCNVector3 {
    
    /// Gibt die euklidische Distanz zwischen zwei Punkten zurück
    func distance(to vector: SCNVector3) -> Float {
        let dx = self.x - vector.x
        let dy = self.y - vector.y
        let dz = self.z - vector.z
        return sqrtf(dx * dx + dy * dy + dz * dz)
    }
    
    /// Gibt den Richtungsvektor von `self` zu `vector` zurück
    func direction(to vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            x: vector.x - self.x,
            y: vector.y - self.y,
            z: vector.z - self.z
        )
    }
    
    /// Gibt die normalisierte Richtung zurück (Länge = 1)
    func normalized() -> SCNVector3 {
        let length = sqrt(x * x + y * y + z * z)
        guard length != 0 else { return SCNVector3Zero }
        return SCNVector3(x / length, y / length, z / length)
    }
    
    /// Ist der Zielpunkt oberhalb des aktuellen Punktes?
    func isAbove(_ vector: SCNVector3) -> Bool {
        return vector.y > self.y
    }
    
    /// Ist der Zielpunkt unterhalb des aktuellen Punktes?
    func isBelow(_ vector: SCNVector3) -> Bool {
        return vector.y < self.y
    }
    
    /// Liegt der Zielpunkt rechts vom aktuellen Punkt?
    func isRight(of vector: SCNVector3) -> Bool {
        return vector.x > self.x
    }
    
    /// Liegt der Zielpunkt links vom aktuellen Punkt?
    func isLeft(of vector: SCNVector3) -> Bool {
        return vector.x < self.x
    }

    /// Verbale Richtungsbeschreibung (für Debug-Zwecke oder Effekte)
    func directionDescription(to vector: SCNVector3) -> String {
        var result = [String]()
        if isAbove(vector) { result.append("oben") }
        if isBelow(vector) { result.append("unten") }
        if isRight(of: vector) { result.append("rechts") }
        if isLeft(of: vector) { result.append("links") }
        if result.isEmpty { result.append("gleiche Position") }
        return result.joined(separator: " und ")
    }
}


extension Float {
    func isAlmostEqual(to other: Float, tolerance: Float = 0.0001) -> Bool {
        return abs(self - other) < tolerance
    }
}


func resetStar(_ star: SCNNode, to position: SCNVector3) {
    star.removeFromParentNode()
    star.removeAllActions()
    star.position = position
    star.opacity = 1.0
}

func fadeIn(_ view: UIView, delay: TimeInterval) {
    UIView.animate(withDuration: 1.0, delay: delay, options: .curveEaseInOut) {
        view.alpha = 1
    }
}

//MARK: SCNQuaternion.slerp
// Spherical Linear Interpolation (Slerp)
extension SCNQuaternion {
    static func slerp(from start: SCNQuaternion, to end: SCNQuaternion, factor t: Float) -> SCNQuaternion {
        let q1 = start.normalized()
        var q2 = end.normalized()
        
        // Winkel zwischen den Quaternionen berechnen
        var dot = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w
        if dot < 0.0 {
            // Richtungen anpassen, wenn sie nicht übereinstimmen
            q2 = SCNQuaternion(x: -q2.x, y: -q2.y, z: -q2.z, w: -q2.w)
            dot = -dot
        }
        
        // Bei kleinen Winkeln kann Lerp verwendet werden
        if dot > 0.9995 {
            return lerp(from: q1, to: q2, factor: t)
        }
        
        // Slerp durchführen
        let theta = acos(dot)
        let sinTheta = sin(theta)
        let w1 = sin((1 - t) * theta) / sinTheta
        let w2 = sin(t * theta) / sinTheta
        
        return SCNQuaternion(
            x: w1 * q1.x + w2 * q2.x,
            y: w1 * q1.y + w2 * q2.y,
            z: w1 * q1.z + w2 * q2.z,
            w: w1 * q1.w + w2 * q2.w
        )
    }
}

//MARK: SCNQuaternion.lerp
// Linear Interpolation (Lerp)
extension SCNQuaternion {
    static func lerp(from start: SCNQuaternion, to end: SCNQuaternion, factor t: Float) -> SCNQuaternion {
        let x = start.x + (end.x - start.x) * t
        let y = start.y + (end.y - start.y) * t
        let z = start.z + (end.z - start.z) * t
        let w = start.w + (end.w - start.w) * t
        return SCNQuaternion(x: x, y: y, z: z, w: w).normalized()
    }
}

//MARK: SCNVector4.normalized
// .normalized hinzu
extension SCNVector4 {
    func normalized() -> SCNVector4 {
        let length = sqrt(x * x + y * y + z * z + w * w)
        guard length > 0 else { return self } // Verhindert Division durch 0
        return SCNVector4(x / length, y / length, z / length, w / length)
    }
}

//MARK: SCNNode.rotate
extension SCNNode {
    func rotate(using axis: SCNVector3, angleInRadians: Float) {
        self.orientation = createQuaternion(axis: axis, angleInRadians: angleInRadians)
    }
}

//MARK: createQuaternion()
// Verwendung
//        let rotationQuaternion = createQuaternion(axis: SCNVector3(0, 1, 0), angleInDegrees: 90)
//        node.orientation = rotationQuaternion
func createQuaternion(axis: SCNVector3, angleInRadians: Float) -> SCNQuaternion {
    // Konvertiere den Winkel von Grad in Radiant
    //let angleInRadians = angleInDegrees * Float.pi / 180

    // Berechne die Quaternion-Werte
    let x = axis.x * sin(angleInRadians / 2)
    let y = axis.y * sin(angleInRadians / 2)
    let z = axis.z * sin(angleInRadians / 2)
    let w = cos(angleInRadians / 2)

    // Rückgabe des Quaternion
    return SCNQuaternion(x, y, z, w)
}

//MARK: combineQuaternions()
// Verwendung
//    // Beispiel: Kombiniere Rotation um X- und Y-Achse
//    let quaternionX = createQuaternion(axis: SCNVector3(1, 0, 0), angleInRadians: 1.4)
//    let quaternionY = createQuaternion(axis: SCNVector3(0, 1, 0), angleInRadians: 1.5)
//    let combinedQuaternion = combineQuaternions(q1: quaternionX, q2: quaternionY)
//
// Verwendung der kombinierten Rotation
//    node.orientation = combinedQuaternion
func combineQuaternions(q1: SCNQuaternion, q2: SCNQuaternion) -> SCNQuaternion {
    // Formel zur Kombination von zwei Quaternionen
    return SCNQuaternion(
        x: q1.x * q2.w + q1.w * q2.x + q1.y * q2.z - q1.z * q2.y,
        y: q1.y * q2.w + q1.w * q2.y + q1.z * q2.x - q1.x * q2.z,
        z: q1.z * q2.w + q1.w * q2.z + q1.x * q2.y - q1.y * q2.x,
        w: q1.w * q2.w - (q1.x * q2.x + q1.y * q2.y + q1.z * q2.z)
    )
}

//MARK: applyRotation()
//Verwenung
//        applyRotation(to: node, axis: SCNVector3(0, 1, 0), angleInRadians: 90)
//        applyRotation(to: node, axis: SCNVector3(1, 0, 0), angleInRadians: 45)
func applyRotation(to node: SCNNode, axis: SCNVector3, angleInRadians: Float) {
    let quaternion = createQuaternion(axis: axis, angleInRadians: angleInRadians)
    node.orientation = quaternion
}

//MARK: "SCNVector3".isEqual(to: "SCNVector3")
// Verwendung
//    let v1 = SCNVector3(1.0000001, 2.0, 3.0)
//    let v2 = SCNVector3(1.0, 2.0, 3.0)
//
//    print(v1.isEqual(to: v2))  // Gibt true zurück!
extension SCNVector3 {
    // Vergleicht zwei SCNVector3 mit einer Toleranz, um Rundungsfehler zu vermeiden
    func isEqual(to other: SCNVector3, tolerance: Float = 0.0001) -> Bool {
        return abs(x - other.x) < tolerance &&
               abs(y - other.y) < tolerance &&
               abs(z - other.z) < tolerance
    }
}




