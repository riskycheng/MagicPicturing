//
//  ContentView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

struct ContentView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        if isActive {
            MainTabView()
        } else {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("魔法修图")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("智能照片编辑")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.0)) {
                        self.opacity = 1.0
                        self.scale = 1.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
