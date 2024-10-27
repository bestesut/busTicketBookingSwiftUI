import Foundation
import SwiftUI

struct BiletAraView : View {
    @State private var from: String = ""
    @State private var to: String = ""
    @State private var date: Date = Date()
    @State private var showSeferlerListView: Bool = false
    @State private var showAlert: Bool = false
    @State private var sehirler: [Sehirler] = []
    @StateObject private var seferlerViewModel = SeferlerViewModel()
    @StateObject private var yolcularViewModel = YolcularViewModel()
    
    var body: some View {
        TabView {
            NavigationStack {
                ZStack {
                    Color.purple.opacity(0.15)
                        .ignoresSafeArea()
                    VStack {
                        HStack {
                            Text("NEREDEN")
                                .bold()
                                .foregroundStyle(.purple.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                            Image(systemName: "arrow.forward")
                                .foregroundStyle(.purple.opacity(0.4))
                                .padding(.trailing, 30)
                            Picker("Sehirler", selection: $from) {
                                ForEach(sehirler.filter { $0.isim != to }) { sehir in
                                    Text(sehir.isim).tag(sehir.isim)
                                }
                            }
                            .pickerStyle(.inline)
                            .frame(minWidth: 170, maxHeight: 100)
                            .padding(.trailing, 40)
                        }
                        HStack {
                            Text("NEREYE")
                                .bold()
                                .foregroundStyle(.purple.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                            Image(systemName: "arrow.forward")
                                .foregroundStyle(.purple.opacity(0.4))
                                .padding(.trailing, 30)
                            Picker("Sehirler", selection: $to) {
                                ForEach(sehirler.filter { $0.isim != from }) { sehir in
                                    Text(sehir.isim).tag(sehir.isim)
                                }
                            }
                            .pickerStyle(.inline)
                            .frame(minWidth: 170, maxHeight: 100)
                            .padding(.trailing, 40)
                        }
                        HStack {
                            Text("TARİH")
                                .bold()
                                .foregroundStyle(.purple.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                                .lineLimit(0)
                            Image(systemName: "arrow.forward")
                                .foregroundStyle(.purple.opacity(0.4))
                                .padding(.trailing, 55)
                            DatePicker("Tarih Seçin", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(.automatic)
                                .labelsHidden()
                                .frame(maxHeight: 100)
                                .padding(.trailing, 60)
                        }
                        Button(action: {
                            let selectedDate = Calendar.current.startOfDay(for: date)
                            let today = Calendar.current.startOfDay(for: Date())
                            let formattedDateString = formattedDate(date: selectedDate)
                            if selectedDate >= today && !to.isEmpty && !from.isEmpty {
                                seferlerViewModel.applyFilter(from: from, to: to, date: formattedDateString)
                                showSeferlerListView = true
                            } else {
                                showAlert = true
                            }
                        }) {
                            Text("Bilet Ara")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.purple.opacity(0.9))
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                        .padding(.bottom, 200)
                        .padding()
                        .navigationDestination(isPresented: $showSeferlerListView) {
                            SeferlerListView(seferlerVM: seferlerViewModel, yolcularVM: yolcularViewModel)
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Error!"), message: Text("Invalid input. Ensure all fields are correctly filled."), dismissButton: .default(Text("OK")))
                        }
                    }
                    .onAppear {
                        sehirler = loadSehirler()
                        if let firstFromSehir = sehirler.first {
                            from = firstFromSehir.isim
                        }
                        if let firstToSehir = sehirler.filter({$0.isim != from }).first {
                            to = firstToSehir.isim
                        }
                    }
                }
                .navigationTitle("Filtrele")
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.purple)
                Text("Ara")
                    .foregroundStyle(.purple)
            }
            NavigationStack {
                LoginView(yolcularViewModel: yolcularViewModel)
            }
            .tabItem {
                Image(systemName: "person")
                Text("Hesabım")
            }
            .tint(.purple)
        }
    }
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    func loadSehirler() -> [Sehirler] {
        guard let url = Bundle.main.url(forResource: "sehirler", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let sehirler = try? JSONDecoder().decode([Sehirler].self, from: data) else {
            return []
        }
        return sehirler
    }
}

#Preview {
    BiletAraView()
}
