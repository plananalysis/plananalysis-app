// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlanAnalysis",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PlanAnalysisCore", targets: ["PlanAnalysisCore"]),
        .executable(name: "PlanAnalysisApp", targets: ["PlanAnalysisApp"]),
    ],
    targets: [
        .target(name: "PlanAnalysisCore"),
        .executableTarget(
            name: "PlanAnalysisApp",
            dependencies: ["PlanAnalysisCore"]
        ),
        .testTarget(
            name: "PlanAnalysisCoreTests",
            dependencies: ["PlanAnalysisCore"]
        ),
    ]
)
