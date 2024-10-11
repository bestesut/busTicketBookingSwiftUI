import SwiftUI
import Foundation

struct ProfileView: View {
    
    @ObservedObject var yolcularViewModel = YolcularViewModel()
    
    var body: some View {
        ZStack {
            if yolcularViewModel.cinsiyet == "Kadın" {
                Color.purple
                    .opacity(0.3)
                    .ignoresSafeArea()
            } else if yolcularViewModel.cinsiyet == "Erkek" {
                Color.blue
                    .opacity(0.3)
                    .ignoresSafeArea()
            }
            VStack {
                if yolcularViewModel.cinsiyet == "Kadın" {
                    Image("female")
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else if yolcularViewModel.cinsiyet == "Erkek" {
                    Image("male")
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                HStack {
                    Text("E-mail: ")
                        .font(.title2)
                        .padding(.leading)
                        .padding(.vertical)
                        .bold()
                    Text(yolcularViewModel.email)
                        .font(.title2)
                    Spacer()
                }
                HStack {
                    Text("Ad: ")
                        .font(.title2)
                        .padding(.leading)
                        .padding(.vertical)
                        .bold()
                    Text(yolcularViewModel.ad)
                        .font(.title2)
                    Spacer()
                }
                HStack {
                    Text("Soyad: ")
                        .font(.title2)
                        .bold()
                        .padding(.leading)
                        .padding(.vertical)
                    Text(yolcularViewModel.soyad)
                        .font(.title2)
                    Spacer()
                }
                HStack {
                    Text("Doğum Tarihi: ")
                        .font(.title2)
                        .padding(.leading)
                        .padding(.vertical)
                        .bold()
                    Text(yolcularViewModel.dogumTarihi)
                        .font(.title2)
                    Spacer()
                }
                HStack {
                    Text("Cinsiyet: ")
                        .font(.title2)
                        .padding(.leading)
                        .padding(.vertical)
                        .bold()
                    Text(yolcularViewModel.cinsiyet)
                        .font(.title2)
                    Spacer()
                }
                
            }
        }
    }
}

#Preview {
    ProfileView()
}
