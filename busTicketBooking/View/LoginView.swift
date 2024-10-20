import Foundation
import SwiftUI
import FirebaseAuth

struct LoginView : View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var showSignupView: Bool = false
    @State private var showProfileView : Bool = false
    @ObservedObject private var seferlerViewModel = SeferlerViewModel()
    @ObservedObject var yolcularViewModel = YolcularViewModel()
    
    var body: some View {
        NavigationStack {
            if isLoggedIn {
                AccountView()
            } else {
                ZStack {
                    Color.purple
                        .opacity(0.2)
                        .ignoresSafeArea()
                    VStack(alignment: .center, spacing: 20) {
                        Text("Giris Yap")
                            .font(.largeTitle)
                            .padding(.bottom, 40)
                        // E-mail
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .textFieldStyle(CustomTextFieldStyle())
                            .padding(.horizontal)
                        // Şifre
                        SecureField("Password", text: $password)
                            .autocapitalization(.none)
                            .textFieldStyle(CustomTextFieldStyle())
                            .padding(.horizontal)
                        // Giriş butonu
                        Button(action: {
                            yolcularViewModel.signIn(email: email, password: password)
                        }) {
                            Text("Giriş Yap")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.purple)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                        .navigationDestination(isPresented: $showProfileView) {
                            AccountView()
                        }
                        .alert(isPresented: .init(get: {
                            yolcularViewModel.errorMessage != nil
                        }, set: { newValue in
                            if !newValue {
                                yolcularViewModel.errorMessage = nil
                            }
                        })) {
                            Alert(title: Text("Hata!"), message: Text(yolcularViewModel.errorMessage ?? "Bir hata oluştu."), dismissButton: .default(Text("Tamam")))
                        }
                        .padding(.horizontal)
                        Text("Hala hesabın yok mu?")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.gray)
                        // Kaydol butonu
                        NavigationLink(destination: SignupView()) {
                            Text("Kaydol")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.purple)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .tint(.purple)
        .onReceive(yolcularViewModel.$isSignedIn) { isSignedIn in
            if isSignedIn {
                isLoggedIn = true
                showProfileView = true
            }
        }
    }
}

#Preview {
    LoginView()
}
