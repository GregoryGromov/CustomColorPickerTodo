import SwiftUI

private enum LayoutConstants {
    static let paletteRadius: CGFloat = 130

    static let backgroundCornerRadius: CGFloat = 20
    static let backgroundHeight: CGFloat = 500

    static let colorCodeBackgroundPadding: CGFloat = 7
    static let colorCodeBackgroundCornerRadius: CGFloat = 20

    static let colorCodeVerticalPadding: CGFloat = 4

    static let contentPadding: CGFloat = 30

    static let selectedColorIndicatorDiameter: CGFloat = 30
    static let colorLabelMaxWidth: CGFloat = 100

    static let sliderWidth: CGFloat = 180
    static let sliderTraillingPadding: CGFloat = 10

    static let colorCursorWidth: CGFloat = 30
    static let colorCursorShadowColorOpacity: CGFloat = 0.2
    static let colorCursorShadowRadius: CGFloat = 4
}

@available(iOS 15.0, *)
public struct LocalColorPicker: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedColor: Color
    let backgroundColor: Color

    @State private var startedColor = Color.white
    @State private var sliderColor = Color.black

    @State private var brightness: Double = 1.0
    @State private var hue = 0.0
    @State private var saturation = 0.0

    @State private var centerPosition = CGPoint.zero
    @State private var location = CGPoint.zero

    let radius: CGFloat = LayoutConstants.paletteRadius
    var diameter: CGFloat {
        radius * 2
    }
    let lightGray = Color(hex: "#EEEEEF")

    public init(selectedColor: Binding<Color>, backgroundColor: Color) {
        self._selectedColor = selectedColor
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.backgroundCornerRadius)
                        .fill(.white)
                        .frame(height: LayoutConstants.backgroundHeight)
                        .padding()
                    Spacer()
                }
                VStack {
                    colorInfoBar
                    brightnessInfoBar
                    colorPicker
                }
                .padding(LayoutConstants.contentPadding)
            }
            .onAppear {
                initializePalettePosition()
                startedColor = selectedColor
            }
            .background(backgroundColor)
        }
    }

// MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { val in
                location = val.location

                let distanceX = val.location.x - centerPosition.x
                let distanceY = val.location.y - centerPosition.y

                let dir = CGPoint(x: distanceX, y: distanceY)
                var distance = sqrt(distanceX * distanceX + distanceY * distanceY)

                if distance < radius {
                    location = val.location
                } else {
                    let clampedX = dir.x / distance * radius
                    let clampedY = dir.y / distance * radius
                    location = CGPoint(x: clampedX + centerPosition.x,
                                       y: clampedY + centerPosition.y)
                    distance = radius
                }

                if distance == 0 { return }
                var angle = Angle(radians: -Double(atan(dir.y / dir.x)))

                if dir.x < 0 {
                    angle.degrees += 180
                } else if dir.x > 0 && dir.y > 0 {
                    angle.degrees += 360
                }

                hue = angle.degrees / 360
                saturation = Double(distance / radius)

                selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
            }
    }

// MARK: - Methods

    private func updateBrightness(_ brightness: Double) {
        selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
        sliderColor = .black.opacity(brightness)
    }

    private func initializePalettePosition() {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height

        centerPosition.x = width / 2 - LayoutConstants.contentPadding
        centerPosition.y = height / 5.2

        location.x = width / 2 - LayoutConstants.contentPadding
        location.y = height / 5.2
    }

// MARK: - UI Components

    private var colorPicker: some View {
        ZStack {
            Circle()
                .fill(palette)
                .frame(width: diameter, height: diameter)
                .position(centerPosition)
            colorCursor
            .position(location)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(dragGesture)
        .toolbar {
            cancelToolBarItem
            saveToolBarItem
        }
    }

    private var colorInfoBar: some View {
        HStack {
            selectedColorIndicator
            Spacer()
            Text(selectedColor.toHex())
                .fontWeight(.semibold)
                .padding(LayoutConstants.colorCodeBackgroundPadding)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.colorCodeBackgroundCornerRadius)
                        .fill(lightGray)
                )
                .padding(.vertical, LayoutConstants.colorCodeVerticalPadding)
                .frame(maxWidth: LayoutConstants.colorLabelMaxWidth, alignment: .leading)
        }
        .padding()
    }

    private var selectedColorIndicator: some View {
        ZStack {
            Circle()
                .fill(palette)
                .frame(width: LayoutConstants.selectedColorIndicatorDiameter)
            Circle()
                .fill(.white)
                .frame(width: LayoutConstants.selectedColorIndicatorDiameter * 0.85)
            Circle()
                .fill(selectedColor)
                .frame(width: LayoutConstants.selectedColorIndicatorDiameter * 0.65)
        }
    }

    private var brightnessInfoBar: some View {
        HStack {
            Text("Ярокость")
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
            Slider(value: $brightness, in: 0.0...1.0, step: 0.01)
                .frame(width: LayoutConstants.sliderWidth)
                .tint(sliderColor)
                .onChange(of: brightness) { newValue in
                    updateBrightness(newValue)
                }
                .padding(.trailing, LayoutConstants.sliderTraillingPadding)
        }
        .padding(.horizontal)
    }

    private var colorCursor: some View {
        ZStack {
            Circle()
                .frame(width: LayoutConstants.colorCursorWidth)
                .foregroundColor(lightGray)
            Circle()
                .frame(width: LayoutConstants.colorCursorWidth * 0.93)
                .foregroundColor(.white)
        }
        .shadow(
            color: .gray.opacity(LayoutConstants.colorCursorShadowColorOpacity),
            radius: LayoutConstants.colorCursorShadowRadius,
            x: 0,
            y: 0
        )
    }

    private var saveToolBarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                Text("Сохранить")
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
        }
    }

    private var cancelToolBarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                selectedColor = startedColor
                dismiss()
            } label: {
                Text("Отменить")
                    .foregroundStyle(.blue)
            }
        }
    }

    private var palette: some ShapeStyle {
        AngularGradient(gradient: Gradient(colors: [
            Color(hue: 1.0, saturation: 1, brightness: brightness),
            Color(hue: 0.9, saturation: 1, brightness: brightness),
            Color(hue: 0.8, saturation: 1, brightness: brightness),
            Color(hue: 0.7, saturation: 1, brightness: brightness),
            Color(hue: 0.6, saturation: 1, brightness: brightness),
            Color(hue: 0.5, saturation: 1, brightness: brightness),
            Color(hue: 0.4, saturation: 1, brightness: brightness),
            Color(hue: 0.3, saturation: 1, brightness: brightness),
            Color(hue: 0.2, saturation: 1, brightness: brightness),
            Color(hue: 0.1, saturation: 1, brightness: brightness),
            Color(hue: 0.0, saturation: 1, brightness: brightness)
        ]), center: .center)
    }
}

//  MARK: - Extension

@available(iOS 15.0, *)
extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return ""
        }

        let red = String(format: "%02lX", Int(components[0] * 255.0))
        let green = String(format: "%02lX", Int(components[1] * 255.0))
        let blue = String(format: "%02lX", Int(components[2] * 255.0))

        return "#\(red)\(green)\(blue)"
    }

    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
