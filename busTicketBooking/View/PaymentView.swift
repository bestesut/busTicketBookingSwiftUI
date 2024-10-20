import SwiftUI
import Combine

struct PaymentView: View {
    @State private var cardNumber: String = ""
    @State private var cardHolderName: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""
    @State var amount: Double = 0.0
    @State private var isPaymentSuccessful = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedMonth = 1
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var alertType: AlertType?
    @Environment(\.presentationMode) var presentationMode
    
    var onPaymentSuccess: () -> Void = {}
    
    // Alert çakışmasını önlemek için
    enum AlertType: Identifiable {
        case paymentSuccess
        case error(String)
        
        var id: String {
            switch self {
            case .paymentSuccess:
                return "paymentSuccess"
            case .error(let message):
                return "error-\(message)"
            }
        }
    }
    
    let months = Array(1...12)
    let years = Array(Calendar.current.component(.year, from: Date())...Calendar.current.component(.year, from: Date()) + 10)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.purple
                    .opacity(0.2)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Ödeme Bilgileri")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        TextField("Kart Numarası", text: $cardNumber)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onReceive(Just(cardNumber)) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count <= 16 {
                                    self.cardNumber = formatCardNumber(filtered)
                                } else {
                                    // Eğer 16 haneden fazla girilmeye çalışılıyorsa, sadece ilk 16 al
                                    self.cardNumber = formatCardNumber(String(filtered.prefix(16)))
                                }
                            }
                        
                        TextField("Kart Sahibinin Adı", text: $cardHolderName)
                            .autocapitalization(.words)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onReceive(Just(cardHolderName)) { newValue in
                                let filteredName = newValue.filter { $0.isLetter || $0.isWhitespace }
                                if filteredName != newValue {
                                    self.cardHolderName = filteredName
                                }
                            }
                        
                        HStack(spacing: 15) {
                            Picker("Ay", selection: $selectedMonth) {
                                ForEach(months, id: \.self) { month in
                                    Text(String(format: "%02d", month)).tag(month)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(5)
                            .cornerRadius(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            Picker("Yıl", selection: $selectedYear) {
                                ForEach(years, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(5)
                            .cornerRadius(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            
                            Spacer()
                            
                            TextField("CVV", text: $cvv)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onReceive(Just(cvv)) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered.count <= 3 {
                                        self.cvv = filtered
                                    } else {
                                        // Eğer 3 haneden fazla girilmeye çalışılıyorsa, sadece ilk 3'ü al
                                        self.cvv = String(filtered.prefix(3))
                                    }
                                    
                                }
                        }
                        HStack {
                            Text("Ödenecek Tutar:")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f TL", amount))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding()
                        Button(action: processPayment) {
                            Text("Ödemeyi Tamamla")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.purple.opacity(0.7))
                                .cornerRadius(8)
                        }
                        .alert(item: $alertType) { alertType in
                                switch alertType {
                                case .paymentSuccess:
                                    return Alert(title: Text("Başarılı!"), message: Text("Ödemeniz başarıyla gerçekleştirildi."), dismissButton: .default(Text("Tamam")) {
                                        onPaymentSuccess()
                                        presentationMode.wrappedValue.dismiss()
                                    })
                                case .error(let message):
                                    return Alert(title: Text("Hata"), message: Text(message), dismissButton: .default(Text("Tamam")))
                                }
                            }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Ödeme Sayfası", displayMode: .inline)
        }
    }
    
    func formatCardNumber(_ number: String) -> String {
        var formatted = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += "-"
            }
            formatted += String(char)
        }
        return formatted
    }
    
    func isValidExpiryDate() -> Bool {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        return selectedYear > currentYear || (selectedYear == currentYear && selectedMonth >= currentMonth)
    }
    
    func processPayment() {
        if !isValidExpiryDate() {
            alertType = .error("Son kullanma tarihi geçmiş bir kart kullanılamaz.")
            return
        }
        if validatePaymentDetails() {
            isPaymentSuccessful = true
            alertType = .paymentSuccess
        }
    }
    
    func validatePaymentDetails() -> Bool {
        if cardNumber.isEmpty || cardHolderName.isEmpty || cvv.isEmpty {
            errorMessage = "Tüm alanları doldurduğunuzdan emin olun."
            showError = true
            return false
        }
        if cardNumber.count != 16 {
            errorMessage = "Kart numarası 16 haneli olmalıdır."
            showError = true
            return false
        }
        if cvv.count != 3 {
            errorMessage = "CVV 3 haneli olmalıdır."
            showError = true
            return false
        }
        return true
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(amount: 500.00)
    }
}
