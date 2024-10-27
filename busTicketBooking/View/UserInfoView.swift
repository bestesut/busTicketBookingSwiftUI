import SwiftUI
import Combine

struct UserInfoView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: Gender = .male
    @State private var showPaymentView = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var sefer: Seferler
    @State var selectedSeatNumber: Int
    @ObservedObject private var yolcularVM: YolcularViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var amount: Double
    var onPaymentSuccess: () -> Void
    var onUserInfoEntered: (Yolcular) -> Void
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Erkek"
        case female = "Kadın"
        
        var id: String { self.rawValue }
    }
    
    init(amount: Double, selectedSeatNumber: Int, onPaymentSuccess: @escaping () -> Void, onUserInfoEntered: @escaping (Yolcular) -> Void, sefer: Seferler, yolcularVM: YolcularViewModel) {
            self.amount = amount
            self.selectedSeatNumber = selectedSeatNumber
            self.onPaymentSuccess = onPaymentSuccess
            self.onUserInfoEntered = onUserInfoEntered
            self.sefer = sefer
            self.yolcularVM = yolcularVM
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.purple
                    .opacity(0.2)
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Ad", text: $firstName)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onReceive(Just(firstName)) { newValue in
                            let filteredName = newValue.filter { $0.isLetter || $0.isWhitespace }
                            if filteredName != newValue {
                                self.firstName = filteredName
                            }
                        }
                    TextField("Soyad", text: $lastName)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onReceive(Just(lastName)) { newValue in
                            let filteredLastName = newValue.filter { $0.isLetter }
                            if filteredLastName != newValue {
                                self.lastName = filteredLastName
                            }
                        }
                    TextField("E-mail", text: $email)
                        .autocapitalization(.none)
                        .textFieldStyle(CustomTextFieldStyle())
                    HStack {
                        Text("Doğum Tarihi:")
                            .foregroundStyle(.gray.opacity(0.8))
                            .padding()
                        DatePicker("Tarih Seçin", selection: $dateOfBirth, displayedComponents: [.date])
                            .datePickerStyle(.automatic)
                            .labelsHidden()
                            .padding()
                            .padding(.leading, 40)
                    }
                    Picker("Cinsiyet", selection: $gender) {
                        ForEach(Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    Button(action: {
                        if validateUserInfo() {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd.MM.yyyy"
                            let formattedDate = dateFormatter.string(from: dateOfBirth)
                            let yolcu = Yolcular(id: UUID().hashValue, ad: firstName, soyad: lastName, cinsiyet: gender.rawValue, email: email, dogumTarihi: formattedDate)
                            onUserInfoEntered(yolcu)
                            showPaymentView = true
                        }
                    }) {
                        Text("Ödemeye Geç")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .navigationBarTitle("Yolcu Bilgileri", displayMode: .inline)
                .alert(isPresented: $showError) {
                    Alert(title: Text("Hata"), message: Text(errorMessage), dismissButton: .default(Text("Tamam")))
                }
                .sheet(isPresented: $showPaymentView) {
                    PaymentView(yolcularVM: yolcularVM, sefer: sefer, amount: amount, selectedSeatNumber: selectedSeatNumber, onPaymentSuccess: {
                        onPaymentSuccess()
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }
        }
    }
    
    func validateUserInfo() -> Bool {
        if firstName.isEmpty || lastName.isEmpty || email.isEmpty {
            errorMessage = "Tüm alanları doldurduğunuzdan emin olun."
            showError = true
            return false
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year!
        
        if age < 18 {
            errorMessage = "18 yaşından küçükler bilet satın alamaz."
            showError = true
            return false
        }
        
        return true
    }
}

struct UserInfoPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        let yolcularVM = YolcularViewModel()
        
        let sefer = Seferler(
            id: UUID(),
            seferNo: "1",
            kalkis: "Şehir A",
            varis: "Şehir B",
            saatKalkis: "10:00",
            saatVaris: "12:00",
            fiyat: 100.0,
            tarih: "01.01.2024",
            otobus: Otobusler(firma: "Kamil Koç", koltukSayisi: 40, firmaFoto: "kamilkoc", koltukSira: 4, koltuklar: [Koltuklar(id: 1, numara: 1, durum: .bos)])
        )

        UserInfoView(amount: sefer.fiyat, selectedSeatNumber: 1, onPaymentSuccess: {
            print("Ödeme başarılı")
        }, onUserInfoEntered: { yolcu in
            print("Yolcu bilgileri: \(yolcu)")
        }, sefer: sefer, yolcularVM: yolcularVM)
    }
}
