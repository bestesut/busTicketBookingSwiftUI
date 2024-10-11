import Foundation
import FirebaseAuth
import FirebaseFirestore

class YolcularViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var errorMessage: String?
    @Published var ad: String = ""
    @Published var soyad: String = ""
    @Published var dogumTarihi: String = ""
    @Published var cinsiyet: String = ""
    @Published var email: String = ""
    
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
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                print("Kullanıcı kaydı hatası: \(error.localizedDescription)") // Hata mesajını yazdır
                return
            }
            
            guard let userId = result?.user.uid else { return }
            print("Kullanıcı başarıyla kaydedildi: \(result?.user.email ?? "")") // Başarı durumu
            
            let formattedDateOfBirth = self?.formatDateToString(date: dogumTarihi)
            
            self?.db.collection("yolcular").document(userId).setData([
                "ad": ad.capitalized,
                "soyad": soyad.capitalized,
                "cinsiyet": cinsiyet,
                "email": email,
                "dogumTarihi": formattedDateOfBirth ?? "",
                "koltukNo": ""

            ]) { error in
                if let error = error {
                    print("Kullanıcı bilgileri Firestore'a eklenirken hata oluştu: \(error.localizedDescription)")
                } else {
                    print("Kullanıcı bilgileri başarıyla Firestore'a eklendi.")
                    DispatchQueue.main.async {
                        self?.isSignedIn = true // Kayıt işlemi başarılı olduğunda view geçişi
                    }
                }
            }
        }
    }
    
    // Giriş
    func signIn(email: String, password: String) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.isSignedIn = true
                print("Kullanıcı başarıyla giriş yaptı: \(result?.user.email ?? "")")
            }
        }
    }
    // Çıkış
    func signOut() {
        do {
            try auth.signOut()
            self.isSignedIn = false
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
            }
            fetchUserData(userId: currentUser.uid) // Kullanıcı verilerini getir
        } else {
            // Kullanıcı oturum açmamış
            DispatchQueue.main.async {
                self.isSignedIn = false
            }
        }
    }
    
    // Verileri çekme
    func fetchUserData(userId: String) {
        guard let userEmail = Auth.auth().currentUser?.email else {
            self.errorMessage = "Kullanıcı oturumu açılmamış"
            return
        }
        
        db.collection("yolcular").whereField("email", isEqualTo: userEmail).getDocuments { (querySnapshot, error) in
            if let error = error {
                self.errorMessage = "Veri çekme hatası: \(error.localizedDescription)"
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    if let ad = data["ad"] as? String,
                       let soyad = data["soyad"] as? String,
                       let dogumTarihi = data["dogumTarihi"] as? String,
                       let cinsiyet = data["cinsiyet"] as? String,
                       let email = data["email"] as? String {
                        self.ad = ad
                        self.soyad = soyad
                        self.dogumTarihi = dogumTarihi
                        self.cinsiyet = cinsiyet
                        self.email = email
                    }
                }
            }
        }
    }
    
}
