import Foundation

struct Seyahatlerim: Identifiable, Codable {
    let id: UUID
    let kalkis: String
    let varis: String
    let tarih: String
    let fiyat: Double
    let firmaAd: String
    let firmaFoto: String
    let koltukNo: Int

    init(id: UUID = UUID(), kalkis: String, varis: String, tarih: String, fiyat: Double, firmaAd: String, firmaFoto: String, koltukNo: Int) {
        self.id = id
        self.kalkis = kalkis
        self.varis = varis
        self.tarih = tarih
        self.fiyat = fiyat
        self.firmaAd = firmaAd
        self.firmaFoto = firmaFoto
        self.koltukNo = koltukNo
    }
}
