import SwiftUI

struct SeferlerListView: View {
    @ObservedObject var seferlerVM: SeferlerViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.purple.opacity(0.2)
                    .ignoresSafeArea()
                VStack {
                    Text("Seferler")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding()
                    
                    if seferlerVM.filteredSeferler.isEmpty {
                        Text("Sefer bulunamadı.")
                            .foregroundColor(.red)
                            .font(.headline)
                    } else {
                        List(seferlerVM.filteredSeferler) { sefer in
                            NavigationLink(destination: KoltuklarView(seferlerViewModel: seferlerVM, sefer: sefer)) {
                                VStack(alignment: .leading) {
                                    Image(sefer.otobus.firmaFoto)
                                        .resizable()
                                        .frame(width: 100, height: 50)
                                        .scaledToFit()
                                    Text("\(sefer.otobus.firma)")
                                        .font(.headline)
                                        .lineLimit(1)
                                    Text("\(sefer.kalkis) -> \(sefer.varis)")
                                        .font(.subheadline)
                                        .bold()
                                    Text("Tarih: \(sefer.tarih) | Saat: \(sefer.saatKalkis) - \(sefer.saatVaris) | Fiyat: \(sefer.fiyat, specifier: "%.2f") TL")
                                        .font(.subheadline)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .onAppear {
//                print("Filtered Seferler: \(seferlerVM.filteredSeferler.count)")
//                print("All Seferler: \(seferlerVM.seferler.count)")
            }
        }
    }
}
