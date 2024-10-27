import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct KoltuklarView: View {
    @ObservedObject var seferlerViewModel: SeferlerViewModel
    @State var sefer: Seferler
    @State private var selectedSeat: Koltuklar?
    @State private var showPaymentView = false
    @State private var showUserInfoView = false
    @State private var isUserLoggedIn = false
    @State private var isLoading = false
    @ObservedObject var yolcularVM: YolcularViewModel

    var body: some View {
        ZStack {
            Color.blue
                .opacity(0.2)
                .ignoresSafeArea()
            VStack {
                Text("\(sefer.otobus.firma) - Koltuklar")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: sefer.otobus.koltukSira)) {
                    ForEach(sefer.otobus.koltuklar) { koltuk in
                        Button(action: {
                            selectedSeat = selectedSeat?.id == koltuk.id ? nil : koltuk
                        }) {
                            Text("\(koltuk.numara)")
                                .frame(width: 50, height: 50)
                                .background(koltukColor(for: koltuk))
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        .disabled(koltuk.durum == .dolu)
                    }
                }
                Button(action: {
                    if selectedSeat != nil {
                        if isUserLoggedIn {
                            showPaymentView = true
                        } else {
                            showUserInfoView = true
                        }
                    }
                }) {
                    Text("Satın Al")
                        .font(.title)
                        .foregroundColor(selectedSeat == nil ? Color.gray : Color.blue)
                        .padding()
                        .cornerRadius(8)
                }
                .disabled(selectedSeat == nil)
                .padding()
            }
            .padding()
            .overlay(
                Group {
                    if isLoading {
                        Color.black.opacity(0.3)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                    }
                }
            )
            .onAppear {
                isUserLoggedIn = Auth.auth().currentUser != nil
                seferlerViewModel.addListener(for: sefer.seferNo) { updatedSefer in
                    self.sefer = updatedSefer
                }
            }
            .onDisappear {
                seferlerViewModel.removeListener(for: sefer.seferNo)
            }
            .sheet(isPresented: $showPaymentView) {
                PaymentView(yolcularVM: yolcularVM, sefer: sefer, amount: sefer.fiyat, selectedSeatNumber: selectedSeat?.numara ?? 0, onPaymentSuccess: handleSuccessfulPayment)
            }
            .navigationDestination(isPresented: $showUserInfoView) {
                UserInfoView(amount: sefer.fiyat, selectedSeatNumber: selectedSeat?.numara ?? 0, onPaymentSuccess: handleSuccessfulPayment, onUserInfoEntered: handleUserInfoEntered, sefer: sefer, yolcularVM: yolcularVM)
            }
        }
    }
    
    private func koltukColor(for koltuk: Koltuklar) -> Color {
        if koltuk.durum == .dolu {
            if let yolcu = koltuk.yolcu {  // Yolcu bilgisi varsa kontrol et
                switch yolcu.cinsiyet.lowercased() {
                case "kadın":
                    return .purple
                case "erkek":
                    return .blue
                default:
                    return .red
                }
            } else {
                return .red
            }
        } else if selectedSeat?.id == koltuk.id {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func handleUserInfoEntered(yolcu: Yolcular) {
        if var seat = selectedSeat,
           let _ = sefer.otobus.koltuklar.firstIndex(where: { $0.id == seat.id }) {
            seat.yolcu = yolcu
            self.selectedSeat = seat  // Güncellenmiş seat'i yeniden atadım
        }
    }
    
    private func handleSuccessfulPayment() {
        isLoading = true
        if let selectedSeat = selectedSeat {
            seferlerViewModel.updateKoltukDurumu(seferNo: sefer.seferNo,
                                                 koltukNo: selectedSeat.numara,
                                                 yeniDurum: .dolu,
                                                 yolcu: selectedSeat.yolcu) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success:
                        self.selectedSeat = nil
                    case .failure(let error):
                        print("Error updating seat status: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            isLoading = false
        }
    }
}

struct KoltuklarView_Previews: PreviewProvider {
    static var previews: some View {
        
        let koltuklar = (1...40).map { Koltuklar(id: $0, numara: $0, durum: .bos) }
        let otobus = Otobusler(firma: "Kamil Koç", koltukSayisi: 40, firmaFoto: "kamilkoc", koltukSira: 4, koltuklar: koltuklar)
        var mutableOtobus = otobus
        mutableOtobus.koltuklar = koltuklar
        
        let sefer = Seferler(
            id: UUID(),
            seferNo: "123",
            kalkis: "İstanbul",
            varis: "Ankara",
            saatKalkis: "08:00",
            saatVaris: "10:00",
            fiyat: 100.0,
            tarih: "01.10.2024",
            otobus: mutableOtobus
        )
        let seferlerViewModel = SeferlerViewModel()
        seferlerViewModel.seferler = [sefer]
                
        return KoltuklarView(seferlerViewModel: seferlerViewModel, sefer: sefer, yolcularVM: YolcularViewModel())
    }
}
