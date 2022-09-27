//
//  StoryView.swift
//  Storees
//
//  Created by João Gabriel Pozzobon dos Santos on 21/11/20.
//

import SwiftUI
import UIKit

struct StoryView: View {
//    var appData: AppData
//    @Binding var selectedStory: Int
//
//    var story: Story {
//        appData.stories[selectedStory]
//    }
//    @Binding var selectedStory: Int

    var story: Story
//    @Binding var isPresented: Bool
    let animation: Namespace.ID
    
    @State var contentProgress: Double = 0.0
    @State var currentContent: Int = 0 {
        didSet {
            contentProgress = 0.0
//            appData.stories[selectedStory].contents[currentContent].seen = true
        }
    }
    
    var timer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()
    @State var pause = false
    
    @State private var dragOffset: CGFloat = .zero
    
    var body: some SwiftUI.View {
        GeometryReader { geometry in
            ZStack {
                SwiftUI.Color.black
                    .ignoresSafeArea()
                    .opacity(Double(pow(2, -abs(dragOffset)/500)))
                
                display
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .offset(y: dragOffset/pow(2, abs(dragOffset)/500+1))
                    .scaleEffect(pow(2, -abs(dragOffset)/2500))
            }.colorScheme(.dark)
            .onReceive(timer) { _ in
                if contentProgress < 1.0 {
                    contentProgress += pause ? 0 : timer.upstream.interval/story.contents[currentContent].duration
                } else if (currentContent < story.contents.count-1) {
                    currentContent += 1
                } else {
                    dismiss()
                }
            }.highPriorityGesture(
                DragGesture()
                    .onChanged { gesture in
                        dragOffset = max(gesture.translation.height, .leastNonzeroMagnitude)
                        dragOffset = max(gesture.translation.height, .leastNonzeroMagnitude)
                        pause = true
                    }
                    .onEnded() { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
//                            isPresented = dragOffset < 175
                            dragOffset = .zero
                        }
                        pause = false
                    }
            ).onAppear {
                currentContent = story.lastUnseen ?? 0
            }
        }
    }
    
    var display: some View {
        ZStack {
            VStack {
                content
                Spacer()
            }
            
            VStack {
                header
                Spacer()
                footer
            }
        }
    }
    
    var content: some SwiftUI.View {
        SwiftUI.GeometryReader { geometry in
            
                SwiftUI.Group {
                    AsyncImage(url: URL(string: story.contents[currentContent].mediaURL)!, placeholder: { Text("") }, image: { Image(uiImage: $0) })
                        .aspectRatio(contentMode: .fit)
                }.frame(height: geometry.size.width*(16.0/9.0))
                .background(AsyncImage(url: URL(string: story.contents[currentContent].mediaURL)!, placeholder: { Text("") }, image: { Image(uiImage: $0) } ))
                .aspectRatio(contentMode: .fill)
                .blur(radius: 175)
                .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded() { value in
                                if value.location.x > geometry.size.width*0.3 {
                                    if (currentContent < story.contents.count-1) {
                                        currentContent += 1
                                    } else {
                                        dismiss()
                                    }
                                } else {
                                    currentContent -= 1
                                }
                            }
                    )
        }
    }
    
    var header: some SwiftUI.View {
        SwiftUI.VStack(spacing: 10) {
            progress
            
            SwiftUI.HStack(spacing: 14) {
//                story.userImage
                AsyncImage(url: URL(string: story.userImage)!, placeholder: { Text("") }, image: { Image(uiImage: $0)})
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .matchedGeometryEffect(id: story.username+"-image", in: animation)
                
                HStack {
                    Text(story.username)
//                        .font(.system(size: 16, weight: .bold))
                        .font(Font.custom(Constants.globalFontBold, size: 15))
                    Text(interval)
//                        .font(.system(size: 15, weight: .medium))
                        .font(Font.custom(Constants.globalFontMedium, size: 14))
                        .opacity(0.85)
                }.fixedSize()
                .matchedGeometryEffect(id: story.username+"-username", in: animation)
                Spacer()
                
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }.padding()
        .frame(height: 80)
        .background(LinearGradient(gradient: SwiftUI.Gradient(colors: [SwiftUI.Color.black.opacity(0.15), .clear]), startPoint: .top, endPoint: .bottom))
    }
    
    var progress: some View {
        HStack(spacing: 5) {
            ForEach(0..<story.contents.count) {
                ProgressView(value: $0 == currentContent ? min(contentProgress, 1) : ($0 < currentContent ? 1 : 0), total: 1).accentColor(.white)
            }
        }.frame(height: 4)
    }
    
    var interval: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "en")
        return formatter.localizedString(for: story.contents[currentContent].date, relativeTo: Date())
            .replacingOccurrences(of: " second[s]? ago", with: "s", options: .regularExpression)
            .replacingOccurrences(of: " minute[s]? ago", with: "m", options: .regularExpression)
            .replacingOccurrences(of: " hour[s]? ago", with: "h", options: .regularExpression)
    }
    
    var footer: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(SwiftUI.Color.white, lineWidth: 1)
            Text("Send message")
                .font(Font.footnote.weight(.medium))
                .padding(.horizontal)
        }.frame(height: 40)
        .padding(12)
        .background(LinearGradient(gradient: SwiftUI.Gradient(colors: [.clear, SwiftUI.Color.black.opacity(0.15)]), startPoint: .top, endPoint: .bottom))
    }
    
    func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
//            isPresented = false
        }
    }
}
