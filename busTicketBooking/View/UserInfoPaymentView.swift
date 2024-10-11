import SwiftUI

struct UserInfoPaymentView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: Gender = .female
    @State private var showPaymentView = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var amount: Double
    var onPaymentSuccess: () -> Void
    var onUserInfoEntered: (Yolcular) -> Void
    
    enum Gender: String, CaseIterable, Identifiable {
        case male = "Erkek"
        case female = "Kadın"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.purple
                    .opacity(0.2)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        TextField("Ad", text: $firstName)
                            .textFieldStyle(CustomTextFieldStyle())
                        TextField("Soyad", text: $lastName)
                            .textFieldStyle(CustomTextFieldStyle())
                        TextField("E-mail", text: $email)
                            .autocapitalization(.none)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
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
                }
                .navigationBarTitle("Yolcu Bilgileri", displayMode: .inline)
                .alert(isPresented: $showError) {
                    Alert(title: Text("Hata"), message: Text(errorMessage), dismissButton: .default(Text("Tamam")))
                }
                .sheet(isPresented: $showPaymentView) {
                    PaymentView(amount: amount, onPaymentSuccess: {
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
            dateFormatter.dateFormat = "yyyy-MM-dd" // Doğum tarihi formatı (örneğin: 2006-10-09)
            
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year!

            if age < 18 {
                errorMessage = "18 yaşından küçükler bilet satın alamaz."
                showError = true
                return false
            }
        
        return true
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
    }
}

struct UserInfoPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoPaymentView(amount: 100.0, onPaymentSuccess: {
            print("Ödeme başarılı")
        }, onUserInfoEntered: { yolcu in
            // Önizleme için kullanıcı bilgilerini kullanabilirsin
            print("Kullanıcı bilgileri: \(yolcu)")
        })
    }
}
