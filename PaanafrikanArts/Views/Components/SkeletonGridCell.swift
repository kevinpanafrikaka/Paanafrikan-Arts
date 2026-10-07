//
//  SkeletonGridCell.swift
//  PaanafrikanArts
//
//  Placeholder animé affiché pendant le tout premier chargement de la
//  grille, à la place d'un spinner plein écran — donne une idée immédiate
//  de la mise en page à venir.
//

import SwiftUI

struct SkeletonGridCell: View {
    @State private var isPulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .aspectRatio(1, contentMode: .fit)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 80, height: 10)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 50, height: 8)
        }
        .opacity(isPulsing ? 0.5 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
