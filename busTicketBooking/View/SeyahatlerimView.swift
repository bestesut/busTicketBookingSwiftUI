import SwiftUI

struct SeyahatlerimView: View {
    @ObservedObject var yolcularVM: YolcularViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.gray
                    .opacity(0.1)
                    .ignoresSafeArea()
                VStack {
                    if yolcularVM.isSignedIn == false {
                        ProgressView("Yükleniyor...")
                    } else if yolcularVM.seyahatlerim.isEmpty {
                        Text("Henüz bir bilet satın almadınız.")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(yolcularVM.seyahatlerim) { seyahat in
                                SeferKart(seyahat: seyahat)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.clear)
                    }
                }
                .navigationTitle("Seyahatlerim")
                .onAppear() {
                    if let userId = yolcularVM.userID {
                        yolcularVM.fetchUserData(userId: userId)
                    } else {
                        print("Kullanıcı oturum açmamış.")
                    }
                }
            }
        }
    }
}

// Bilet kartı
struct SeferKart: View {
    let seyahat: Seyahatlerim

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(seyahat.firmaAd)
                    .font(.title2)
                    .bold()
                Spacer()
                Text("Koltuk No: \(seyahat.koltukNo)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            HStack {
                Image(seyahat.firmaFoto)
                    .resizable()
                    .frame(width: 100, height: 50)
                    .scaledToFit()
                Spacer()
                Text(String(format: "%.2f TL", seyahat.fiyat))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("\(seyahat.kalkis) → \(seyahat.varis)")
                    .font(.headline)
                Spacer()
                Text(seyahat.tarih)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.red.opacity(0.15)))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.vertical, 5)
    }
}

struct SeyahatlerimView_Previews: PreviewProvider {
    static var previews: some View {
        let yolcularViewModel = YolcularViewModel()
        yolcularViewModel.seyahatlerim = [Seyahatlerim(kalkis: "Ankara", varis: "İstanbul", tarih: "10.10.2010", fiyat: 50, firmaAd: "Kamil Koç", firmaFoto: "kamilkoc", koltukNo: 1)]
        return SeyahatlerimView(yolcularVM: yolcularViewModel)
    }
}
