import SwiftUI
import Foundation

struct AccountView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var yolcularViewModel = YolcularViewModel()
    
    var body: some View {
        NavigationStack {
            if yolcularViewModel.isSignedIn {
                ZStack {
                    Color.purple
                        .opacity(0.2)
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                        
                        Text("Hoşgeldin, \(yolcularViewModel.ad)")
                            .font(.title)
                            .padding(.top, 50)
                        
                        NavigationLink(destination: ProfileView(yolcularViewModel: yolcularViewModel)) {
                            Text("Profilim")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.black)
                                .background(.purple.opacity(0.7))
                                .cornerRadius(8)
                        }
                        .padding()
                        Button(action: {
                            // Seyahetler View daha yazılmadı
                        }) {
                            Text("Seyahetlerim")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.black)
                                .background(.purple.opacity(0.7))
                                .cornerRadius(8)
                            
                        }
                        .padding()
                        Button(action: {
                            yolcularViewModel.signOut()
                            dismiss()
                        }) {
                            Text("Çıkış Yap")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.black)
                                .background(.purple.opacity(0.7))
                                .cornerRadius(8)
                            
                        }
                        .padding(.bottom, 400)
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                }
                .navigationTitle("Hesabım")
            } else {
                LoginView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    AccountView()
}
