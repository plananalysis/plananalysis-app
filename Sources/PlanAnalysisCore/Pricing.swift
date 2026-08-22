import Foundation

public struct ModelPrice: Sendable, Equatable {
    public var inputPerM: Double
    public var outputPerM: Double
    public var cacheReadPerM: Double
    public var cacheCreatePerM: Double

    public init(inputPerM: Double, outputPerM: Double, cacheReadPerM: Double, cacheCreatePerM: Double? = nil) {
        self.inputPerM = inputPerM
        self.outputPerM = outputPerM
        self.cacheReadPerM = cacheReadPerM
        self.cacheCreatePerM = cacheCreatePerM ?? inputPerM * 1.25
    }

    public func costUsd(input: Int, output: Int, cacheRead: Int, cacheCreate: Int) -> Double {
        let m = 1_000_000.0
        return (Double(input) * inputPerM
            + Double(output) * outputPerM
            + Double(cacheRead) * cacheReadPerM
            + Double(cacheCreate) * cacheCreatePerM) / m
    }
}

public enum Pricing {
    /// Official / OpenRouter list prices used for Equiv. API $. Unknown models cost 0.
    public static func price(for model: String?) -> ModelPrice? {
        guard let raw = model?.lowercased(), !raw.isEmpty else { return nil }
        let rows: [(String, ModelPrice)] = [
            ("claude-opus", ModelPrice(inputPerM: 15, outputPerM: 75, cacheReadPerM: 1.50)),
            ("claude-sonnet-5", ModelPrice(inputPerM: 2, outputPerM: 10, cacheReadPerM: 0.20)),
            ("claude-sonnet", ModelPrice(inputPerM: 3, outputPerM: 15, cacheReadPerM: 0.30)),
            ("claude-haiku", ModelPrice(inputPerM: 1, outputPerM: 5, cacheReadPerM: 0.10)),
            ("glm-5", ModelPrice(inputPerM: 1.40, outputPerM: 4.40, cacheReadPerM: 0.26)),
            ("glm-4", ModelPrice(inputPerM: 0.60, outputPerM: 2.20, cacheReadPerM: 0.11)),
            ("gpt-5.6-sol", ModelPrice(inputPerM: 1.75, outputPerM: 14, cacheReadPerM: 0.175)),
            ("gpt-5.6", ModelPrice(inputPerM: 1.75, outputPerM: 14, cacheReadPerM: 0.175)),
            ("gpt-5.5", ModelPrice(inputPerM: 1.25, outputPerM: 10, cacheReadPerM: 0.125)),
            ("gpt-5", ModelPrice(inputPerM: 1.25, outputPerM: 10, cacheReadPerM: 0.125)),
            ("o3", ModelPrice(inputPerM: 2, outputPerM: 8, cacheReadPerM: 0.50)),
        ]
        return rows.first(where: { raw.contains($0.0) })?.1
    }

    public static func costUsd(_ delta: TokenDelta) -> Double {
        guard let price = price(for: delta.model) else { return 0 }
        return price.costUsd(
            input: delta.input,
            output: delta.output,
            cacheRead: delta.cacheRead,
            cacheCreate: delta.cacheCreate
        )
    }
}
