import Foundation
import SwiftUI
import FirebaseDatabase
import FirebaseAuth

struct KoltuklarView : View {
    @State private var selectedSeat: Koltuklar?
    @StateObject private var seferlerViewModel = SeferlerViewModel()
    @State var sefer: Seferler
    @State private var showPaymentView = false
    @State private var showUserInfoView = false
    @State private var isUserLoggedIn = false
    
    init(sefer: Seferler, seferlerViewModel: SeferlerViewModel) {
        _sefer = State(initialValue: sefer)
        _seferlerViewModel = StateObject(wrappedValue: seferlerViewModel)
    }
    
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
                            if selectedSeat?.id == koltuk.id {
                                selectedSeat = nil
                            } else {
                                selectedSeat = koltuk
                            }
                        }) {
                            Text("\(koltuk.numara)")
                                .frame(width: 50, height: 50)
                                .background(koltuk.durum == .bos ? (selectedSeat?.id == koltuk.id ? Color.yellow : Color.green) : Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
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
            .onAppear {
                if let guncelSefer = seferlerViewModel.seferler.first(where: { $0.seferNo == sefer.seferNo }) {
                    self.sefer = guncelSefer
                }
                isUserLoggedIn = Auth.auth().currentUser != nil
            }
            .sheet(isPresented: $showPaymentView) {
                PaymentView(amount: sefer.fiyat, onPaymentSuccess: handleSuccessfulPayment)
            }
            .navigationDestination(isPresented: $showUserInfoView) {
                UserInfoPaymentView(amount: sefer.fiyat, onPaymentSuccess: handleSuccessfulPayment, onUserInfoEntered: { yolcu in
                    self.handleUserInfoEntered(yolcu: yolcu)
                })
            }
        }
    }
    
    func handleUserInfoEntered(yolcu: Yolcular) {
        // Koltuk seçimi yapıldıysa, yolcu bilgisini güncelle
        if let selectedSeat = selectedSeat {
            // Seçili koltuğun bilgilerini güncelle
            if let index = sefer.otobus.koltuklar.firstIndex(where: { $0.id == selectedSeat.id }) {
                sefer.otobus.koltuklar[index].yolcu = yolcu
            }
        }
    }
    
    func handleSuccessfulPayment() {
        if let selectedSeat = selectedSeat,
           let index = sefer.otobus.koltuklar.firstIndex(where: { $0.id == selectedSeat.id }) {
            sefer.otobus.koltuklar[index].durum = .dolu
            seferlerViewModel.updateKoltukDurumu(seferNo: sefer.seferNo, koltukNo: selectedSeat.numara, yeniDurum: .dolu, yolcu: sefer.otobus.koltuklar[index].yolcu)
            self.selectedSeat = nil
            if let guncelSefer = seferlerViewModel.seferler.first(where: { $0.seferNo == sefer.seferNo }) {
                self.sefer = guncelSefer
            }
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
            id: 1,
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
        
        return KoltuklarView(sefer: sefer, seferlerViewModel: seferlerViewModel)
    }
}
