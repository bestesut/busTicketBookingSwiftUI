import Foundation

struct Seferler: Identifiable {
    let id: Int
    let seferNo: String
    let kalkis: String
    let varis: String
    let saatKalkis: String
    let saatVaris: String
    let fiyat: Double
    let tarih: String
    var otobus: Otobusler
    
    init(id: Int, seferNo: String, kalkis: String, varis: String, saatKalkis: String, saatVaris: String, fiyat: Double, tarih: String, otobus: Otobusler) {
        self.id = id
        self.seferNo = seferNo
        self.kalkis = kalkis
        self.varis = varis
        self.saatKalkis = saatKalkis
        self.saatVaris = saatVaris
        self.fiyat = fiyat
        self.tarih = tarih
        self.otobus = otobus
    }
}
