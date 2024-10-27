import Foundation

struct Yolcular: Identifiable, Codable {
    let id: Int
    let ad: String
    let soyad: String
    let cinsiyet: String
    let email: String
    let dogumTarihi: String
    // Bunu modelde parametre olarak vermek istemiyorum o yüzden bu şekilde boş tanımladım.
    var seyahatlerim: [Seyahatlerim] = []
    
    init(id: Int, ad: String, soyad: String, cinsiyet: String, email: String, dogumTarihi: String, seyahatlerim: [Seyahatlerim] = []) {
        self.id = id
        self.ad = ad
        self.soyad = soyad
        self.cinsiyet = cinsiyet
        self.email = email
        self.dogumTarihi = dogumTarihi
        self.seyahatlerim = seyahatlerim
    }
}
