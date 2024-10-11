import SwiftUI

struct Koltuklar: Identifiable {
    let id: Int
    let numara: Int
    var durum: KoltukDurumu
    var yolcu: Yolcular?
}

enum KoltukDurumu: String { // For rawValue
    case bos = "bos"
    case dolu = "dolu"
}
