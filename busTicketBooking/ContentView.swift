//
//  ContentView.swift
//  busTicketBooking
//
//  Created by Beste on 27.09.2024.
//

import SwiftUI
import Lottie

//MARK: - Main

struct ContentView: View {
    
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                withAnimation(.easeOut(duration: 1.5)) {
                    SplashScreen()
                        .transition(.opacity)
                }
            } else {
                BiletAraView()
            }
        }
        .onAppear {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.showSplash = false
                }
            }
        }
    }
}

//MARK: - Splash Screen

struct SplashScreen : View {
        
    var body: some View {
        
        ZStack {
            
            Color(.purple)
                .ignoresSafeArea()
            VStack {
                Spacer(minLength: 50)
                Text("Şu Bilet")
                    .bold()
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                Spacer(minLength: 50)
                
                
                AnimatedView(lottieFile: "bus")
                            
                
                Spacer(minLength: 150)
            }
            
        }
        
    }
    
}

//MARK: - Animated View

struct AnimatedView : UIViewRepresentable {
    
    let lottieFile : String
    let animationView = LottieAnimationView()
    
    func makeUIView(context: Context) -> some UIView {
        
        let view = UIView(frame: .zero)
        
        animationView.animation = LottieAnimation.named(lottieFile)
        animationView.play()
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        view.addSubview(animationView)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        animationView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        animationView.animationSpeed = 1
        
        return view
        
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}

//#Preview {
//    ContentView()
//    LoginView()
//    SeferlerListView()
//}

