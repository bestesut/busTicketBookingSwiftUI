import Foundation
import FirebaseAuth
import FirebaseFirestore

class YolcularViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var ad: String = ""
    @Published var soyad: String = ""
    @Published var dogumTarihi: String = ""
    @Published var cinsiyet: String = ""
    @Published var email: String = ""
    @Published var userID: String?
    @Published var seyahatlerim: [Seyahatlerim] = []
    
    private var auth = Auth.auth()
    private var db : Firestore!
    
    init() {
        db = Firestore.firestore()
        checkedIfSignedIn()
    }
    private func formatDateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    // Kayıt
    func signUp(email: String, password: String, ad: String, soyad: String, cinsiyet: String, dogumTarihi: Date) {
        isLoading = true
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
                print("Kullanıcı kaydı hatası: \(error.localizedDescription)") // Hata mesajını yazdır
                return
            }
            guard let userId = result?.user.uid else {
                self?.isLoading = false
                return
            }
            print("Kullanıcı başarıyla kaydedildi: \(result?.user.email ?? "")") // Başarı durumu
            let formattedDateOfBirth = self?.formatDateToString(date: dogumTarihi)
            self?.db.collection("yolcular").document(userId).setData([
                "ad": ad.capitalized,
                "soyad": soyad.capitalized,
                "cinsiyet": cinsiyet,
                "email": email,
                "dogumTarihi": formattedDateOfBirth ?? ""
            ]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Kullanıcı bilgileri Firestore'a eklenirken hata oluştu: \(error.localizedDescription)")
                    } else {
                        self?.userID = userId
                        self?.ad = ad.capitalized
                        self?.soyad = soyad.capitalized
                        self?.email = email
                        self?.cinsiyet = cinsiyet
                        self?.dogumTarihi = formattedDateOfBirth ?? ""
                        self?.isSignedIn = true
                        print("Kullanıcı bilgileri başarıyla Firestore'a eklendi.")
                    }
                    self?.isLoading = false
                }
            }
        }
    }
    func resetViewModel() {
        DispatchQueue.main.async {
            self.isSignedIn = false
            self.userID = nil
            self.ad = ""
            self.soyad = ""
            self.email = ""
            self.dogumTarihi = ""
            self.cinsiyet = ""
            self.errorMessage = nil
            self.seyahatlerim = []
        }
    }
    // Giriş
    func signIn(email: String, password: String) {
        resetViewModel()
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let userId = result?.user.uid {
                    self?.isSignedIn = true
                    print("Kullanıcı başarıyla giriş yaptı: \(result?.user.email ?? "")")
                    self?.fetchUserData(userId: userId)
                }
            }
        }
    }
    // Çıkış
    func signOut() {
        do {
            try auth.signOut()
            resetViewModel()
            print("Kullanıcı başarıyla çıkış yaptı.")
        } catch let signOutError as NSError {
            self.errorMessage = signOutError.localizedDescription
        }
    }
    
    // Current User Kontrolü
    func checkedIfSignedIn() {
        if let currentUser = auth.currentUser {
            // Kullanıcı oturum açmış
            DispatchQueue.main.async {
                self.isSignedIn = true
                self.userID = currentUser.uid
            }
            fetchUserData(userId: currentUser.uid) // Kullanıcı verilerini getir
        } else {
            // Kullanıcı oturum açmamış
            DispatchQueue.main.async {
                self.isSignedIn = false
                self.userID = nil
            }
        }
    }
    // Verileri çekme
    func fetchUserData(userId: String) {
        guard !isLoading else { return }
        isLoading = true
        db.collection("yolcular").document(userId).getDocument { (document, error) in
            if let error = error {
                self.errorMessage = "Veri çekme hatası: \(error.localizedDescription)"
            } else if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    self.ad = data["ad"] as? String ?? ""
                    self.soyad = data["soyad"] as? String ?? ""
                    self.dogumTarihi = data["dogumTarihi"] as? String ?? ""
                    self.cinsiyet = data["cinsiyet"] as? String ?? ""
                    self.email = data["email"] as? String ?? ""
                    self.seyahatlerim = data["seyahatlerim"] as? [Seyahatlerim] ?? []
                    self.fetchSeyahatlerim(userId: userId)
                }
            } else {
                self.errorMessage = "Kullanıcı bulunamadı."
            }
            self.isLoading = false
        }
    }
    // Seyahat ekleme
    func addSeyahatToYolcu(userId: String, seyahatlerim: Seyahatlerim) {
        if Auth.auth().currentUser != nil {
            let db = Firestore.firestore()
            let yolcuRef = db.collection("yolcular").document(userId)
            
            do {
                let encodedSeyahat = try Firestore.Encoder().encode(seyahatlerim)
                yolcuRef.updateData([
                    "seyahatlerim": FieldValue.arrayUnion([encodedSeyahat])
                ]) { error in
                    if let error = error {
                        print("Seyahat eklenirken hata oluştu: \(error.localizedDescription)")
                    } else {
                        print("Seyahat başarıyla eklendi.")
                        self.fetchUserData(userId: userId)
                    }
                }
            } catch {
                print("Seyahat encode edilirken hata: \(error.localizedDescription)")
            }
        }
    }
    // Seyahat çekme
    func fetchSeyahatlerim(userId: String) {
        db.collection("yolcular").document(userId).getDocument { (document, error) in
            if let error = error {
                self.errorMessage = "Seyahat verileri çekme hatası: \(error.localizedDescription)"
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let seyahatData = data?["seyahatlerim"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: seyahatData, options: [])
                        self.seyahatlerim = try JSONDecoder().decode([Seyahatlerim].self, from: jsonData)
                    } catch {
                        self.errorMessage = "Veri parse hatası: \(error.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Seyahat verileri bulunamadı."
                }
            } else {
                self.errorMessage = "Kullanıcı bulunamadı."
            }
        }
    }
}
