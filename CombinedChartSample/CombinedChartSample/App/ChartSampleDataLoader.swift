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
            let candidateURLs: [URL?] = [
                bundle.url(
                    forResource: resourceName,
                    withExtension: "json",
                    subdirectory: resourceSubdirectory),
                bundle.url(forResource: resourceName, withExtension: "json"),
                bundle.url(
                    forResource: resourceName,
                    withExtension: "json",
                    subdirectory: "Resources/\(resourceSubdirectory)")
            ]

            for candidateURL in candidateURLs {
                guard let candidateURL,
                      let data = try? Data(contentsOf: candidateURL),
                      let response = try? decoder.decode(ChartSampleData.Response.self, from: data)
                else {
                    continue
                }

                cachedResponses[resourceName] = response
                return response
            }
        }

        return nil
    }
}
