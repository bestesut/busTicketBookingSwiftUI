import Foundation
import SwiftUI
import FirebaseAuth

struct SignupView : View {
    
    enum AlertType: Identifiable {
        case missingFields
        case firebaseError(String)
        
        var id: Int {
            switch self {
            case .missingFields:
                return 1
            case .firebaseError:
                return 2
            }
        }
    }
    
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var surname: String = ""
    @State private var password: String = ""
    @State private var showAlert: Bool = false
    @State private var selectedGender: String = ""
    @State private var dateOfBirth: Date = Date()
    @StateObject private var seferlerViewModel = SeferlerViewModel()
    @StateObject private var yolcularViewModel = YolcularViewModel()
    @State private var alertMessage: String = ""
    @State private var alertType: AlertType?
    
    var body: some View {
        NavigationStack {
            if yolcularViewModel.isSignedIn {
                AccountView()
            } else {
                ZStack {
                    Color.purple.opacity(0.15)
                        .ignoresSafeArea()
                    VStack(alignment: .center, spacing: 20) {
                        Text("Kayıt Ol")
                            .font(.largeTitle)
                            .padding(.bottom, 40)
                        // Kullanıcı adı alanı
                        TextField("E-mail", text: $email)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        
                        TextField("Ad", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .padding()
                        
                        TextField("Soyad", text: $surname)
                            .padding()
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        // Şifre alanı
                        SecureField("Parola", text: $password)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Doğum Tarihi:")
                                .foregroundStyle(.gray.opacity(0.8))
                                .padding(.trailing, 80)
                            DatePicker("Tarih Seçin", selection: $dateOfBirth, displayedComponents: [.date])
                                .datePickerStyle(.automatic)
                                .labelsHidden()
                                .padding()
                        }
                        
                        HStack {
                            Text("Cinsiyet: ")
                                .foregroundStyle(.gray.opacity(0.8))
                                .padding(.trailing, 55)
                            Picker("Options", selection: $selectedGender) {
                                Text("Kadın").tag("Kadın")
                                Text("Erkek").tag("Erkek")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .padding(.bottom, 30)
                        
                        // Kaydol butonu
                        Button(action: {
                            if email.isEmpty || password.isEmpty || name.isEmpty || surname.isEmpty || selectedGender.isEmpty {
                                alertMessage = "Lütfen tüm alanları doldurunuz."
                                alertType = .missingFields
                            } else if dateOfBirth > Date() {
                                alertMessage = "Geçerli bir doğum tarihi seçiniz."
                                alertType = .missingFields
                            } else {
                                yolcularViewModel.signUp(email: email, password: password, ad: name, soyad: surname, cinsiyet: selectedGender, dogumTarihi: dateOfBirth)
                            }
                        }) {
                            Text("Kayıt Ol")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.purple)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                        .navigationDestination(isPresented: $yolcularViewModel.isSignedIn) {
                            AccountView()
                        }
                        .alert(item: $alertType) { alertType in
                            switch alertType {
                            case .missingFields:
                                return Alert(title: Text("Eksik Bilgi"), message: Text("Lütfen tüm alanları doldurunuz."), dismissButton: .default(Text("Tamam")))
                            case .firebaseError(let message):
                                return Alert(title: Text("Hata!"), message: Text(message), dismissButton: .default(Text("Tamam")))
                            }
                        }
                        .onChange(of: yolcularViewModel.errorMessage) {
                            if let errorMessage = yolcularViewModel.errorMessage {
                                alertType = .firebaseError(errorMessage)
                            }
                        }
                        .padding()
                        
                    }
                }
            }
        }
    }
}

#Preview {
    SignupView()
}

