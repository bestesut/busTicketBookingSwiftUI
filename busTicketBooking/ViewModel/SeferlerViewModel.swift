import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore

class SeferlerViewModel: ObservableObject {
    @Published var seferler: [Seferler] = []
    @Published var filteredSeferler: [Seferler] = []
    private var database: DatabaseReference!
    
    init() {
        database = Database.database().reference()
//        addDummyData(koltukSayisi: 40, kalkis: "İstanbul", varis: "Ankara", saatKalkis: "07.00", saatVaris: "15.00", tarih: "15.10.2024", fiyat: 700, seferNo: "1", firma: "Kamil Koç", firmaFoto: "kamilkoc", koltukSira: 4)
        fetchSeferler()
    }
    
    func fetchSeferler() {
        database.child("seferler").observe(.value) { snapshot in
            var newSeferler: [Seferler] = []
            for child in snapshot.children {
                guard let snapshot = child as? DataSnapshot,
                      let seferData = snapshot.value as? [String: Any] else { continue }
                if let sefer = self.parseSefer(seferData: seferData, key: snapshot.key) {
                    newSeferler.append(sefer)
                }
            }
            DispatchQueue.main.async {
                self.seferler = newSeferler
                self.filteredSeferler = newSeferler  // Başlangıçta tüm seferleri göster
            }
        } withCancel: { error in
            print("Veri çekerken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    private func parseSefer(seferData: [String: Any], key: String) -> Seferler? {
        
        let seferNo = key.replacingOccurrences(of: "sefer", with: "")
        guard let kalkis = seferData["kalkis"] as? String,
              let varis = seferData["varis"] as? String,
              let saatKalkis = seferData["saatKalkis"] as? String,
              let saatVaris = seferData["saatVaris"] as? String,
              let fiyat = seferData["fiyat"] as? Int,
              let tarih = seferData["tarih"] as? String,
              let otobusData = seferData["otobus"] as? [String: Any],
              let firma = otobusData["firma"] as? String,
              let koltukSayisi = otobusData["koltukSayisi"] as? Int,
              let firmaFoto = otobusData["firmaFoto"] as? String,
              let koltukSira = otobusData["koltukSira"] as? Int,
              let koltuklarData = otobusData["koltuklar"] as? [[String: Any]] else {
            print("Sefer verisi eksik veya hatalı: \(seferData)")
            return nil
        }
        
        // Koltuk verilerini işleme
        let koltuklar = koltuklarData.compactMap { koltukData -> Koltuklar? in
            guard let numara = koltukData["numara"] as? Int,
                  let durumString = koltukData["durum"] as? String,
                  let durum = KoltukDurumu(rawValue: durumString) else { return nil }
            
            // Yolcu bilgileri ekleme
            let yolcuData = koltukData["yolcu"] as? [String: Any]
            let yolcu: Yolcular? = yolcuData != nil ? Yolcular(
                id: UUID().hashValue,
                ad: yolcuData?["ad"] as? String ?? "",
                soyad: yolcuData?["soyad"] as? String ?? "",
                cinsiyet: yolcuData?["cinsiyet"] as? String ?? "",
                email: yolcuData?["email"] as? String ?? "",
                dogumTarihi: yolcuData?["dogumTarihi"] as? String ?? ""
            ) : nil
            
            return Koltuklar(id: numara, numara: numara, durum: durum, yolcu: yolcu)
        }
        
        let seferID = Int(key) ?? 0
        let otobus = Otobusler(firma: firma, koltukSayisi: koltukSayisi, firmaFoto: firmaFoto, koltukSira: koltukSira, koltuklar: koltuklar)
        return Seferler(id: seferID, seferNo: seferNo, kalkis: kalkis, varis: varis, saatKalkis: saatKalkis, saatVaris: saatVaris, fiyat: Double(fiyat), tarih: tarih, otobus: otobus)
    }
    
    func updateKoltukDurumu(seferNo: String, koltukNo: Int, yeniDurum: KoltukDurumu, yolcu: Yolcular?) {
        let firebaseKoltukNo = koltukNo - 1
        
        var koltukData: [String: Any] = [
            "durum": yeniDurum.rawValue
        ]
        
        // Koltuklar altına yolcu bilgileri ekleme
        if let currentUser = Auth.auth().currentUser {
            let userId = currentUser.uid
            let firestore = Firestore.firestore()
            
            // Kullanıcı bilgilerini Firestore'dan çek
            firestore.collection("yolcular").document(userId).getDocument { (document, error) in
                if let error = error {
                    print("Kullanıcı bilgileri alınırken hata oluştu: \(error)")
                    return
                }
                
                guard let data = document?.data() else {
                    print("Kullanıcı verisi bulunamadı.")
                    return
                }
                
                // Kullanıcı bilgilerini al
                let yolcu = Yolcular(
                    id: UUID().hashValue,
                    ad: data["ad"] as? String ?? "",
                    soyad: data["soyad"] as? String ?? "",
                    cinsiyet: data["cinsiyet"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    dogumTarihi: data["dogumTarihi"] as? String ?? ""
                )
                
                // Koltuklar altına yolcu bilgilerini ekle
                koltukData["yolcu"] = [
                    "ad": yolcu.ad.capitalized,
                    "soyad": yolcu.soyad.capitalized,
                    "dogumTarihi": yolcu.dogumTarihi,
                    "cinsiyet": yolcu.cinsiyet,
                    "email": yolcu.email
                ]
                
                // Koltuk durumunu güncelle
                self.database.child("seferler/sefer\(seferNo)/otobus/koltuklar/\(firebaseKoltukNo)").updateChildValues(koltukData) { error, _ in
                    if let error = error {
                        print("Koltuk durumu güncellenirken hata oluştu: \(error)")
                    } else {
                        print("Koltuk durumu başarıyla güncellendi. Koltuk \(koltukNo)")
                        DispatchQueue.main.async {
                            if let seferIndex = self.seferler.firstIndex(where: { $0.seferNo == seferNo }),
                               let koltukIndex = self.seferler[seferIndex].otobus.koltuklar.firstIndex(where: { $0.numara == koltukNo }) {
                                self.seferler[seferIndex].otobus.koltuklar[koltukIndex].durum = yeniDurum
                                self.seferler[seferIndex].otobus.koltuklar[koltukIndex].yolcu = yolcu
                            }
                        }
                    }
                }
            }
        } else {
            // Misafir durumunda
            koltukData["yolcu"] = [
                "ad": yolcu?.ad.capitalized ?? "",
                "soyad": yolcu?.soyad.capitalized ?? "",
                "cinsiyet": yolcu?.cinsiyet ?? "",
                "email": yolcu?.email ?? "",
                "dogumTarihi": yolcu?.dogumTarihi ?? ""
            ]
            
            database.child("seferler/sefer\(seferNo)/otobus/koltuklar/\(firebaseKoltukNo)").updateChildValues(koltukData) { error, _ in
                if let error = error {
                    print("Koltuk durumu güncellenirken hata oluştu: \(error)")
                } else {
                    print("Ekleme başarılı.")
                    
                    DispatchQueue.main.async {
                        if let seferIndex = self.seferler.firstIndex(where: { $0.seferNo == seferNo }),
                           let koltukIndex = self.seferler[seferIndex].otobus.koltuklar.firstIndex(where: { $0.numara == koltukNo }) {
                            self.seferler[seferIndex].otobus.koltuklar[koltukIndex].durum = yeniDurum
                            // Misafir yolcu bilgilerini ekleme
                            self.seferler[seferIndex].otobus.koltuklar[koltukIndex].yolcu = yolcu
                        }
                    }
                }
            }
        }
    }
    
    func filterSeferler(from: String, to: String, date: String) -> [Seferler] {
        return seferler.filter { sefer in
            sefer.kalkis == from && sefer.varis == to && sefer.tarih == date
        }
    }
    func applyFilter(from: String, to: String, date: String) {
        filteredSeferler = filterSeferler(from: from, to: to, date: date)
    }
    func addDummyData(koltukSayisi: Int, kalkis: String, varis: String, saatKalkis: String, saatVaris: String, tarih: String, fiyat: Int, seferNo: String, firma: String, firmaFoto: String, koltukSira: Int) {
        var koltukListesi: [Koltuklar] = []
        // Koltuk oluşturma
        var koltuklar: [[String: Any]] = []
        for numara in 1...koltukSayisi {
            let koltuk = Koltuklar(id: numara, numara: numara, durum: .bos)
            koltukListesi.append(koltuk)
            let koltukData: [String: Any] = [
                "numara": koltuk.numara,
                "durum": koltuk.durum.rawValue // Başlangıçta tüm koltuklar boş
            ]
            koltuklar.append(koltukData)
        }
        
        let dummyData: [String: Any] = [
            "fiyat": fiyat,
            "kalkis": kalkis,
            "saatKalkis": saatKalkis,
            "saatVaris": saatVaris,
            "seferNo": seferNo,
            "tarih": tarih,
            "varis": varis,
            "otobus": [
                "firma": firma,
                "firmaFoto": firmaFoto,
                "koltukSayisi": koltukSayisi,
                "koltukSira": koltukSira,
                "koltuklar": koltuklar
            ]
        ]
        
        database.child("seferler/sefer\(seferNo)").setValue(dummyData) { (error, ref) in
            if let error = error {
                print("Error adding dummy data: \(error)")
            } else {
                print("Dummy data added successfully.")
            }
        }
    }
}

