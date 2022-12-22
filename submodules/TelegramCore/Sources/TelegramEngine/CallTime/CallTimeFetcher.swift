import Foundation
import SwiftSignalKit

public protocol CallTimeFetcher {
    func getTimeStamp() -> Signal<Int32, NoError>
}

extension TelegramEngine {
    final class CallTimeFetcherImpl: CallTimeFetcher {
        private let url = "http://worldtimeapi.org/api/timezone/Europe/Moscow"
        public func getTimeStamp() -> Signal<Int32, NoError> {
            return getDataSignal(url: url)
            |> mapToSignal({ [unowned self] data in
                self.getTimeDecodeSignal(data: data, field: "unixtime")
            })
        }

        private func getDataSignal(url: String) -> Signal<Data, NoError> {
            return Signal { subsriber in
                if let url = URL(string: url) {
                    let request = URLRequest(url: url)
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        let statusCodeOK = 200
                        if error != nil
                            || (response as? HTTPURLResponse)?.statusCode != statusCodeOK {
                            fatalError("statusCode != \(statusCodeOK)")
                        } else if let data = data {
                            subsriber.putNext(data)
                        } else {
                            fatalError("No data")
                        }
                    }
                    task.resume()
                } else {
                    fatalError("Invalid url")
                }
                return EmptyDisposable
            }
        }

        private func getTimeDecodeSignal<T>(data:Data, field:String) -> Signal<T, NoError> {
            return Signal { subsriber in
                if let dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
                   let field = dict[field] as? T {
                    subsriber.putNext(field)
                }
                return EmptyDisposable
            }
        }
    }
}
