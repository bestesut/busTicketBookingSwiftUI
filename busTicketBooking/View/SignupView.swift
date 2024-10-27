import Foundation
import Combine
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
    @ObservedObject private var seferlerViewModel = SeferlerViewModel()
    @ObservedObject var yolcularViewModel = YolcularViewModel()
    @State private var alertMessage: String = ""
    @State private var alertType: AlertType?
    
    var body: some View {
        NavigationStack {
            if yolcularViewModel.isSignedIn {
                AccountView(yolcularViewModel: yolcularViewModel)
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
                            .autocapitalization(.none)
                            .textFieldStyle(CustomTextFieldStyle())
                            .padding(.horizontal)
                        
                        TextField("Ad", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .padding(.horizontal)
                            .onReceive(Just(name)) { newValue in
                                let filteredName = newValue.filter { $0.isLetter || $0.isWhitespace }
                                if filteredName != newValue {
                                    self.name = filteredName
                                }
                            }
                        
                        TextField("Soyad", text: $surname)
                            .padding(.horizontal)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onReceive(Just(surname)) { newValue in
                                let filteredSurname = newValue.filter { $0.isLetter }
                                if filteredSurname != newValue {
                                    self.surname = filteredSurname
                                }
                            }
                        
                        // Şifre alanı
                        SecureField("Parola", text: $password)
                            .autocapitalization(.none)
                            .textFieldStyle(CustomTextFieldStyle())
                            .padding(.horizontal)
                        
                        HStack(alignment: .center, spacing: 20) {
                            Text("Doğum Tarihi:")
                                .foregroundStyle(.gray.opacity(0.8))
                                .padding(.trailing, 65)
                            DatePicker("Tarih Seçin", selection: $dateOfBirth, displayedComponents: [.date])
                                .datePickerStyle(.automatic)
                                .labelsHidden()
                                .padding()
                        }
                        
                        HStack(alignment: .center, spacing: 20) {
                            Text("Cinsiyet: ")
                                .foregroundStyle(.gray.opacity(0.8))
                                .padding(.trailing, 50)
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
                            AccountView(yolcularViewModel: yolcularViewModel)
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
                        .onChange(of: yolcularViewModel.isSignedIn) {
                            if yolcularViewModel.isSignedIn {
                                withAnimation {
                                    yolcularViewModel.fetchUserData(userId: yolcularViewModel.userID ?? "")
                                }
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

