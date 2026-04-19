// PacingPal
// SVGLogoView.swift
// Logo 组件 - 使用 SwiftUI 原生绘制

import SwiftUI

struct SVGLogoView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        LogoShape()
            .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Logo Shape
struct LogoShape: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let scale = min(width, height) / 100
            
            ZStack {
                // Row 1 - Top wave
                Circle()
                    .frame(width: 4 * scale, height: 4 * scale)
                    .position(x: 20 * scale, y: 35 * scale)
                    .opacity(0.5)
                
                Circle()
                    .frame(width: 6 * scale, height: 6 * scale)
                    .position(x: 32 * scale, y: 28 * scale)
                    .opacity(0.8)
                
                Circle()
                    .frame(width: 7 * scale, height: 7 * scale)
                    .position(x: 44 * scale, y: 24 * scale)
                
                Circle()
                    .frame(width: 6 * scale, height: 6 * scale)
                    .position(x: 56 * scale, y: 28 * scale)
                    .opacity(0.8)
                
                Circle()
                    .frame(width: 4 * scale, height: 4 * scale)
                    .position(x: 68 * scale, y: 35 * scale)
                    .opacity(0.5)
                
                Circle()
                    .frame(width: 3 * scale, height: 3 * scale)
                    .position(x: 80 * scale, y: 45 * scale)
                    .opacity(0.3)
                
                // Row 2 - Middle wave
                Circle()
                    .frame(width: 3 * scale, height: 3 * scale)
                    .position(x: 15 * scale, y: 50 * scale)
                    .opacity(0.3)
                
                Circle()
                    .frame(width: 5 * scale, height: 5 * scale)
                    .position(x: 27 * scale, y: 45 * scale)
                    .opacity(0.6)
                
                Circle()
                    .frame(width: 6.4 * scale, height: 6.4 * scale)
                    .position(x: 39 * scale, y: 38 * scale)
                    .opacity(0.9)
                
                Circle()
                    .frame(width: 7.6 * scale, height: 7.6 * scale)
                    .position(x: 50 * scale, y: 35 * scale)
                
                Circle()
                    .frame(width: 6.4 * scale, height: 6.4 * scale)
                    .position(x: 61 * scale, y: 38 * scale)
                    .opacity(0.9)
                
                Circle()
                    .frame(width: 5 * scale, height: 5 * scale)
                    .position(x: 73 * scale, y: 45 * scale)
                    .opacity(0.6)
                
                Circle()
                    .frame(width: 3 * scale, height: 3 * scale)
                    .position(x: 85 * scale, y: 50 * scale)
                    .opacity(0.3)
                
                // Row 3 - Bottom wave
                Circle()
                    .frame(width: 4 * scale, height: 4 * scale)
                    .position(x: 20 * scale, y: 65 * scale)
                    .opacity(0.5)
                
                Circle()
                    .frame(width: 6 * scale, height: 6 * scale)
                    .position(x: 32 * scale, y: 72 * scale)
                    .opacity(0.8)
                
                Circle()
                    .frame(width: 7 * scale, height: 7 * scale)
                    .position(x: 44 * scale, y: 76 * scale)
                
                Circle()
                    .frame(width: 6 * scale, height: 6 * scale)
                    .position(x: 56 * scale, y: 72 * scale)
                    .opacity(0.8)
                
                Circle()
                    .frame(width: 4 * scale, height: 4 * scale)
                    .position(x: 68 * scale, y: 65 * scale)
                    .opacity(0.5)
                
                Circle()
                    .frame(width: 3 * scale, height: 3 * scale)
                    .position(x: 80 * scale, y: 55 * scale)
                    .opacity(0.3)
                
                // Center accent
                Circle()
                    .frame(width: 8 * scale, height: 8 * scale)
                    .position(x: 50 * scale, y: 50 * scale)
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        SVGLogoView()
            .frame(width: 40, height: 40)
            .foregroundColor(.blue)
        
        SVGLogoView()
            .frame(width: 80, height: 80)
            .foregroundColor(.green)
    }
}
