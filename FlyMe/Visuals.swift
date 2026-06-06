import AVFoundation
import SwiftUI

struct AuroraBackground: View {
    @State private var drifting = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "090B18"), Color(hex: "121129"), Color(hex: "071A24")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.purple.opacity(0.34))
                .frame(width: 330, height: 330)
                .blur(radius: 80)
                .offset(x: drifting ? 120 : -90, y: drifting ? -280 : -180)

            Circle()
                .fill(.cyan.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: drifting ? -130 : 100, y: drifting ? 280 : 190)

            Circle()
                .fill(.pink.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: drifting ? -80 : 150, y: drifting ? 40 : -10)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                drifting.toggle()
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}

struct PageHeader<Action: View>: View {
    let title: String
    let subtitle: String
    let action: Action

    init(
        title: String,
        subtitle: String,
        @ViewBuilder action: () -> Action
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .center, spacing: 16) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.7)
                Spacer(minLength: 8)
                action
            }

            HStack(spacing: 9) {
                Capsule()
                    .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 28, height: 3)
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }
}

extension PageHeader where Action == EmptyView {
    init(title: String, subtitle: String) {
        self.init(title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}

struct ScoreRing: View {
    let score: Int
    @State private var progress = 0.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: 13)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [.cyan, .mint, .purple, .cyan], center: .center),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .cyan.opacity(0.45), radius: 14)

            VStack(spacing: -2) {
                Text("\(score)")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                Text("自律指数")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 154, height: 154)
        .onAppear {
            withAnimation(.spring(duration: 1.1, bounce: 0.1)) {
                progress = Double(score) / 100
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.spring(duration: 0.8, bounce: 0.12)) {
                progress = Double(newValue) / 100
            }
        }
    }
}

struct MetricPill: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.headline)
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.055), in: .rect(cornerRadius: 16))
    }
}

struct CheckInSuccessView: View {
    let kind: CheckInKind
    let onDone: () -> Void

    @AppStorage("discreetMode") private var discreetMode = true
    @AppStorage("soundEffects") private var soundEffects = true
    @State private var revealed = false
    @State private var orbiting = false
    @State private var countdown = 1.0

    var body: some View {
        ZStack {
            Color(hex: "070810").ignoresSafeArea()

            Circle()
                .fill(kind.tint.opacity(0.3))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .scaleEffect(revealed ? 1.15 : 0.25)
                .opacity(revealed ? 1 : 0)

            Circle()
                .fill(.purple.opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 100)
                .offset(x: orbiting ? 140 : -120, y: orbiting ? -260 : 260)

            SuccessParticleField(color: kind.tint, expanded: revealed, rotating: orbiting)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(kind.tint.opacity(0.28 - Double(index) * 0.06), lineWidth: 1)
                            .frame(width: CGFloat(154 + index * 52), height: CGFloat(154 + index * 52))
                            .scaleEffect(revealed ? 1 : 0.35)
                            .opacity(revealed ? 1 : 0)
                            .animation(.spring(duration: 1.15, bounce: 0.12).delay(Double(index) * 0.08), value: revealed)
                    }

                    Circle()
                        .fill(kind.tint.opacity(0.16))
                        .frame(width: 132, height: 132)
                        .glassEffect(.regular.tint(kind.tint.opacity(0.22)), in: .circle)
                        .shadow(color: kind.tint.opacity(0.55), radius: 40)

                    Image(systemName: isDiscreetSensitive ? "checkmark.shield.fill" : kind.symbol)
                        .font(.system(size: 48, weight: .semibold))
                        .symbolEffect(.bounce, value: revealed)
                        .foregroundStyle(.white)
                }
                .scaleEffect(revealed ? 1 : 0.2)
                .rotationEffect(.degrees(revealed ? 0 : -18))

                VStack(spacing: 10) {
                    Text(displayTitle)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text(displayMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 310)
                }
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 18)

                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(kind.tint)
                        Text("\(displayKindTitle) · 已记录")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .glassEffect(.regular.tint(kind.tint.opacity(0.12)), in: .capsule)

                    GeometryReader { proxy in
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(kind.tint)
                                    .frame(width: proxy.size.width * countdown)
                            }
                    }
                    .frame(width: 96, height: 3)
                }
                .opacity(revealed ? 1 : 0)

                Spacer()

                Button {
                    onDone()
                } label: {
                    Text("完成")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .tint(kind.tint)
                .padding(.horizontal, 28)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 24)
            }
            .padding(.vertical, 32)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if soundEffects {
                SuccessSoundPlayer.shared.play(for: kind)
            }
            withAnimation(.spring(duration: 0.9, bounce: 0.26)) {
                revealed = true
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                orbiting = true
            }
            withAnimation(.linear(duration: 4.0)) {
                countdown = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                onDone()
            }
        }
    }

    private var isDiscreetSensitive: Bool {
        discreetMode && kind.isSensitive
    }

    private var displayTitle: String {
        isDiscreetSensitive ? "已完成记录" : kind.successTitle
    }

    private var displayMessage: String {
        isDiscreetSensitive ? "记录已安全保存到这台设备。" : kind.successMessage
    }

    private var displayKindTitle: String {
        isDiscreetSensitive ? "私密记录" : kind.title
    }
}

@MainActor
private final class SuccessSoundPlayer {
    static let shared = SuccessSoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private lazy var format = AVAudioFormat(
        standardFormatWithSampleRate: sampleRate,
        channels: 1
    )!

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.volume = 0.72
    }

    func play(for kind: CheckInKind) {
        guard let buffer = makeBuffer(for: kind) else { return }

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        if !engine.isRunning {
            try? engine.start()
        }

        player.stop()
        player.scheduleBuffer(buffer, at: nil)
        player.play()
    }

    private func makeBuffer(for kind: CheckInKind) -> AVAudioPCMBuffer? {
        let frequencies: [Double] = switch kind {
        case .urge: [440, 523.25]
        case .redirected: [523.25, 659.25, 783.99]
        case .masturbation: [392, 493.88]
        case .intimacy: [523.25, 659.25]
        case .explicitContent: [349.23, 440]
        case .nocturnalEmission: [440, 587.33]
        }

        let noteDuration = 0.12
        let gapDuration = 0.025
        let totalDuration = Double(frequencies.count) * noteDuration
            + Double(max(frequencies.count - 1, 0)) * gapDuration
        let frameCount = AVAudioFrameCount(totalDuration * sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else {
            return nil
        }
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let segmentDuration = noteDuration + gapDuration
            let noteIndex = min(Int(time / segmentDuration), frequencies.count - 1)
            let timeInSegment = time - Double(noteIndex) * segmentDuration

            guard timeInSegment < noteDuration else {
                samples[frame] = 0
                continue
            }

            let attack = min(timeInSegment / 0.018, 1)
            let release = min((noteDuration - timeInSegment) / 0.055, 1)
            let envelope = sin(.pi * min(attack, release) / 2)
            let phase = 2 * Double.pi * frequencies[noteIndex] * timeInSegment
            let tone = sin(phase) + 0.18 * sin(phase * 2)
            samples[frame] = Float(tone * envelope * 0.14)
        }

        return buffer
    }
}

private struct SuccessParticleField: View {
    let color: Color
    let expanded: Bool
    let rotating: Bool

    var body: some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                let angle = Double(index) / 18 * Double.pi * 2
                let radius = CGFloat(125 + (index % 4) * 28)

                Circle()
                    .fill(index.isMultiple(of: 3) ? .white : color)
                    .frame(width: CGFloat(4 + index % 4), height: CGFloat(4 + index % 4))
                    .blur(radius: index.isMultiple(of: 2) ? 0.5 : 2)
                    .shadow(color: color, radius: 8)
                    .offset(
                        x: expanded ? cos(angle) * radius : 0,
                        y: expanded ? sin(angle) * radius : 0
                    )
                    .opacity(expanded ? 0.75 : 0)
                    .animation(
                        .spring(duration: 1.2, bounce: 0.18).delay(Double(index) * 0.018),
                        value: expanded
                    )
            }
        }
        .rotationEffect(.degrees(rotating ? 22 : -12))
        .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: rotating)
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 255) / 255,
            green: Double((value >> 8) & 255) / 255,
            blue: Double(value & 255) / 255
        )
    }
}
