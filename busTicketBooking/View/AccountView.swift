import SwiftUI
import Foundation

struct AccountView : View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var yolcularViewModel: YolcularViewModel
    
    var body: some View {
        ZStack {
            Color.purple
                .opacity(0.2)
                .ignoresSafeArea()
            
            if yolcularViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
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
                    NavigationLink(destination: SeyahatlerimView(yolcularVM: yolcularViewModel)) {
                        Text("Seyahatlerim")
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
        }
        .navigationTitle("Hesabım")
        .onAppear {
            if let userID = yolcularViewModel.userID {
                yolcularViewModel.fetchUserData(userId: userID)
            }
        }
    }
}

#Preview {
    AccountView(yolcularViewModel: YolcularViewModel())
}
