import Foundation

public class APIClient {
    public func request<Response: Decodable>(_ request: URLRequest,
                                             type: Response.Type,
                                             completion: @escaping (Response?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, requestError) in
            if let requestError {
                print("DEBUG: get request failed with error : \(requestError.localizedDescription)")
                completion(nil, requestError)
                return
            }
            
            print("---------------------------------------------------------------")
            print("DEBUG:  Request URL: \(response?.url?.absoluteString ?? "")")
            
            guard let data else {
                completion(nil, nil)
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(Response.self, from: data)
                print("DEBUG: Decoded: \(decoded)")
                completion(decoded, nil)
                return
            } catch {
                print("DEBUG: Decode error: \(error)")
                completion(nil, error)
            }
            print("---------------------------------------------------------------")
        }
        task.resume()
    }
}
