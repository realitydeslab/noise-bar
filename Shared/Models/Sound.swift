import Foundation

public struct Sound: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let filename: String
    public let iconName: String

    public init(id: String, name: String, filename: String, iconName: String) {
        self.id = id
        self.name = name
        self.filename = filename
        self.iconName = iconName
    }
}

public enum SoundLibrary {
    public static let all: [Sound] = [
        Sound(id: "airplane",        name: "Airplane",        filename: "air-plane",       iconName: "air-plane"),
        Sound(id: "birds",           name: "Birds",           filename: "birds-tree",      iconName: "birds-tree"),
        Sound(id: "brown-noise",     name: "Brown noise",     filename: "brown-noise3",    iconName: "brown-noise"),
        Sound(id: "cave",            name: "Cave",            filename: "cave-drops",      iconName: "cave"),
        Sound(id: "coffee",          name: "Coffee",          filename: "coffee",          iconName: "coffee"),
        Sound(id: "drops",           name: "Drops",           filename: "drops",           iconName: "drops"),
        Sound(id: "fire",            name: "Fire",            filename: "fire",            iconName: "fire"),
        Sound(id: "leaves",          name: "Leaves",          filename: "leaves",          iconName: "leaves"),
        Sound(id: "night",           name: "Night",           filename: "night",           iconName: "night"),
        Sound(id: "rain",            name: "Rain",            filename: "rain",            iconName: "rain"),
        Sound(id: "storm",           name: "Storm",           filename: "storm",           iconName: "storm"),
        Sound(id: "stream-water",    name: "Stream water",    filename: "stream-water",    iconName: "stream-water"),
        Sound(id: "train",           name: "Train",           filename: "train",           iconName: "train"),
        Sound(id: "underwater",      name: "Underwater",      filename: "underwater",      iconName: "underwater"),
        Sound(id: "washing-machine", name: "Washing machine", filename: "washing-machine", iconName: "washing-machine"),
        Sound(id: "waterfall",       name: "Waterfall",       filename: "waterfall",       iconName: "waterfall"),
        Sound(id: "waves",           name: "Waves",           filename: "waves",           iconName: "waves"),
        Sound(id: "wind",            name: "Wind",            filename: "wind",            iconName: "wind"),
    ]

    public static func byID(_ id: String) -> Sound? {
        all.first { $0.id == id }
    }
}
