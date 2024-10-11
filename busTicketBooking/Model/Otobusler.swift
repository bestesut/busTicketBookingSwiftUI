import Foundation

struct Otobusler: Identifiable {
    let id: UUID = UUID()
    let koltukSayisi: Int
    let firma: String
    let firmaFoto: String
    var koltuklar: [Koltuklar]
    let koltukSira: Int
    
    init(firma: String, koltukSayisi: Int, firmaFoto: String, koltukSira: Int, koltuklar: [Koltuklar]) {
        self.firma = firma
        self.koltukSayisi = koltukSayisi
        self.koltuklar = koltuklar
        self.firmaFoto = firmaFoto
        self.koltukSira = koltukSira
    }
    
}
