import SwiftUI

struct UsageWidgetView: View {
    @ObservedObject var store: UsageStore

    private var percent: Double {
        Double(max(0, min(100, store.snapshot.remainingPercent))) / 100
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 1)

            VStack(alignment: .leading, spacing: 5) {
                topLine
                mainLine
                sampleLine
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 356, height: 154)
        .preferredColorScheme(.dark)
    }

    private var topLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(store.snapshot.plan)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)

            Text(store.snapshot.status)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)

            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(height: 18)
    }

    private var mainLine: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(store.snapshot.remainingLabel)
                    .font(.system(size: 43, weight: .regular, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(store.snapshot.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 140, alignment: .leading)

            Gauge(value: percent) {
                EmptyView()
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(gaugeTint)
            .frame(width: 40, height: 40)

            VStack(alignment: .trailing, spacing: 3) {
                Text(store.snapshot.usedLabel)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)

                Text(store.snapshot.resetLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 124, alignment: .trailing)
        }
        .frame(height: 58)
    }

    private var sampleLine: some View {
        HStack(spacing: 0) {
            ForEach(store.snapshot.samples.prefix(4)) { sample in
                VStack(spacing: 2) {
                    Text(sample.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                    Text(sample.value)
                        .font(.system(size: 15, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 38)
    }

    private var iconName: String {
        switch store.snapshot.remainingPercent {
        case 70...100: return "bolt.horizontal.fill"
        case 35..<70: return "gauge.with.dots.needle.50percent"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private var gaugeTint: Color {
        switch store.snapshot.remainingPercent {
        case 70...100: return .green
        case 35..<70: return .yellow
        default: return .red
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
