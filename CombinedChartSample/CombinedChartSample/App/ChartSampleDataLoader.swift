import Foundation

enum ChartSampleDataLoader {
    private static let resourceSubdirectory = "SampleDatasets"
    private static let decoder = JSONDecoder()
    private static var cachedResponses: [String: ChartSampleData.Response] = [:]

    private final class BundleToken {}

    static func loadResponse(resourceName: String = "SampleChartData.current") -> ChartSampleData.Response? {
        if let cachedResponse = cachedResponses[resourceName] {
            return cachedResponse
        }

        let candidateBundles = [Bundle.main, Bundle(for: BundleToken.self)]

        for bundle in candidateBundles {
            guard let url = bundle.url(
                forResource: resourceName,
                withExtension: "json",
                subdirectory: resourceSubdirectory),
                let data = try? Data(contentsOf: url),
                let response = try? decoder.decode(ChartSampleData.Response.self, from: data)
            else {
                continue
            }

            cachedResponses[resourceName] = response
            return response
        }

        return nil
    }
}
