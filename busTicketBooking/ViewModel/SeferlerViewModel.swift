import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore

class SeferlerViewModel: ObservableObject {
    @Published var seferler: [Seferler] = []
    @Published var filteredSeferler: [Seferler] = []
    private var database: DatabaseReference!
    private var listeners: [String: DatabaseHandle] = [:]
    
    init() {
        database = Database.database().reference()
//        addDummyData(koltukSayisi: 40, kalkis: "İstanbul", varis: "Ankara", saatKalkis: "07.00", saatVaris: "15.00", tarih: "19.10.2024", fiyat: 700, seferNo: "1", firma: "Kamil Koç", firmaFoto: "kamilkoc", koltukSira: 4)
//        addDummyData(koltukSayisi: 30, kalkis: "Adana", varis: "Adıyaman", saatKalkis: "10.00", saatVaris: "18.00", tarih: "19.10.2024", fiyat: 900, seferNo: "2", firma: "Metro", firmaFoto: "metro", koltukSira: 3)
        fetchSeferler()
    }
    
    func addListener(for seferNo: String, completion: @escaping (Seferler) -> Void) {
        let handle = database.child("seferler/sefer\(seferNo)").observe(.value) { snapshot in
            guard let seferData = snapshot.value as? [String: Any],
                  let sefer = self.parseSefer(seferData: seferData, key: seferNo) else { return }
            DispatchQueue.main.async {
                completion(sefer)
            }
        }
        listeners[seferNo] = handle
    }
    
    func removeListener(for seferNo: String) {
        if let handle = listeners[seferNo] {
            database.child("seferler/sefer\(seferNo)").removeObserver(withHandle: handle)
            listeners.removeValue(forKey: seferNo)
        }
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
            }
        } withCancel: { error in
            print("Veri çekerken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    private func parseSefer(seferData: [String: Any], key: String) -> Seferler? {
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

        let koltuklar = koltuklarData.compactMap { koltukData -> Koltuklar? in
            guard let numara = koltukData["numara"] as? Int,
                  let durumString = koltukData["durum"] as? String,
                  let durum = KoltukDurumu(rawValue: durumString) else { return nil }

            let yolcuData = koltukData["yolcu"] as? [String: Any]
            let yolcu = yolcuData.map {
                Yolcular(
                    id: UUID().hashValue,
                    ad: $0["ad"] as? String ?? "",
                    soyad: $0["soyad"] as? String ?? "",
                    cinsiyet: $0["cinsiyet"] as? String ?? "",
                    email: $0["email"] as? String ?? "",
                    dogumTarihi: $0["dogumTarihi"] as? String ?? ""
                )
            }

            return Koltuklar(id: numara, numara: numara, durum: durum, yolcu: yolcu)
        }

        let otobus = Otobusler(
            firma: firma,
            koltukSayisi: koltukSayisi,
            firmaFoto: firmaFoto,
            koltukSira: koltukSira,
            koltuklar: koltuklar
        )

        return Seferler(
            id: UUID(),
            seferNo: key.replacingOccurrences(of: "sefer", with: ""),
            kalkis: kalkis,
            varis: varis,
            saatKalkis: saatKalkis,
            saatVaris: saatVaris,
            fiyat: Double(fiyat),
            tarih: tarih,
            otobus: otobus
        )
    }
    
    func updateKoltukDurumu(seferNo: String, koltukNo: Int, yeniDurum: KoltukDurumu, yolcu: Yolcular?, completion: @escaping (Result<Void, Error>) -> Void) {
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
                    completion(.failure(error))
                    return
                }
                
                guard let data = document?.data() else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı verisi bulunamadı."])))
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
                        completion(.success(()))
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
                    print("Koltuk durumu başarıyla güncellendi. Koltuk \(koltukNo)")
                    
                    DispatchQueue.main.async {
                        if let seferIndex = self.seferler.firstIndex(where: { $0.seferNo == seferNo }),
                           let koltukIndex = self.seferler[seferIndex].otobus.koltuklar.firstIndex(where: { $0.numara == koltukNo }) {
                            self.seferler[seferIndex].otobus.koltuklar[koltukIndex].durum = yeniDurum
                            self.seferler[seferIndex].otobus.koltuklar[koltukIndex].yolcu = yolcu
                        }
                    }
                    completion(.success(()))
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

