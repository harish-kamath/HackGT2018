//
//  ComputerVisionOCR.swift
//  ComputerVisionOCR
//
//  Created by Dimitar Chakarov on 14/07/2018.
//

import Foundation

open class ComputerVisionOCR {
    public static let shared = ComputerVisionOCR()

	private var apiKey: String?
	private var baseUrl: String?
  
  var responseCode: Int = 0
  var label: String = ""
  var previousLabel: String = ""
  var cou: Int = 0
	
	private init() {}
	
	open func configure(apiKey: String, baseUrl: String) {
		self.apiKey = apiKey
		self.baseUrl = baseUrl
	}
  
  open func textOperations(_ u:String, completion: @escaping (_ response: Data? ) -> Void) {
    guard let apiKey = apiKey, let _ = baseUrl else {
      fatalError("Please run configure first!")
    }
    let s = u
    let c = URL(string: s)!
    var request = URLRequest(url: c)
    request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
    //request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    //request.httpBodyStream = InputStream(data: imageData)
    //request.httpMethod = "POST"
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard error == nil else {
        print("Error!!")
        completion(nil)
        return
      }
      
      
      let httpResponse = response as! HTTPURLResponse
      let t = String(data: data!, encoding: .utf8)!
      if(httpResponse.statusCode == 200 && t.range(of: "NotStarted") == nil && t.range(of: "Running") == nil){
      do {
        var jsonArray = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)  as! [String:AnyObject]
        if let a = jsonArray["recognitionResult"] as! [String:Any]?{
          if let b = a["lines"] as! [Any]?{
            if(b.count > 0){
            let c = b[0] as! [String:Any]
              if let d = c["text"] as! String?{
                self.responseCode = httpResponse.statusCode
                self.label = d
              } else {
                
                self.responseCode = httpResponse.statusCode
                self.label = "BAD!!NOTGOOD"
              }
            } else {
              
              self.responseCode = httpResponse.statusCode
              self.label = "BAD!!NOTGOOD"
            }
          } else {
            
            self.responseCode = httpResponse.statusCode
            self.label = "BAD!!NOTGOOD"
          }
        }
        else {
          self.responseCode = httpResponse.statusCode
          self.label = "BAD!!NOTGOOD"
        }
        

        
        
      } catch {
        print("JSON Processing Failed")
      }
      }
      completion(data)
    }
    
    task.resume()
  }
  
  func recCall(_ s:String){
    print("Call \(cou)")
    self.textOperations(s, completion: { data in
      if(self.responseCode != 200) {
        self.recCall(s)
        self.cou = self.cou + 1
      }
      else{
        print("LABEL")
        print(self.label)
        self.previousLabel = self.label
        self.label = ""
        self.responseCode = 0
      }
    })
  }
	
	open func requestOCRData(_ imageData: Data, language: String = "en", detectOrientation: Bool = true, completion: @escaping (_ response: Data? ) -> Void) {
		guard let apiKey = apiKey, let baseUrl = baseUrl else {
			fatalError("Please run configure first!")
		}
		let s = "\(baseUrl)/recognizeText?mode=Handwritten"
    let c = URL(string: s)!
		var request = URLRequest(url: c)
		request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
		request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    request.httpBodyStream = InputStream(data: imageData)
		request.httpMethod = "POST"
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			guard error == nil else {
        print("Error!")
				completion(nil)
				return
			}
      
      let r = response as! HTTPURLResponse
      let respString = r.allHeaderFields["Operation-Location"] as! String
      self.recCall(respString)

      
			completion(data)
		}
		
		task.resume()
	}
	
	open func requestOCRString(_ imageData: Data, language: String = "en", detectOrientation: Bool = true, completion: @escaping (_ response: [String]? ) -> Void) {
		
		func parseResponse(responseData: Data) throws -> [String] {
			let decoder = JSONDecoder()
			let response = try decoder.decode(OCRResponse.self, from: responseData)
			let result = response.regions.reduce([], { (result, regions) in
				return result + regions.lines.reduce([], { (result, lines) in
					return result + lines.words.reduce([], { (result, words) in
						return result + [words.text]
					})
				})
			})
			return result
		}
		
		struct OCRResponse: Codable {
			struct Regions: Codable {
				struct Lines: Codable {
					struct Words: Codable {
						let boundingBox: String
						let text: String
					}
					let boundingBox: String
					let words: [Words]
				}
				let boundingBox: String
				let lines: [Lines]
			}
			let regions: [Regions]
		}
		
		requestOCRData(imageData) { data in
			guard let data = data else {
				completion(nil)
				return
			}
			do {
                //print(String(data: data, encoding: .utf8))
				let result = try parseResponse(responseData: data)
				completion(result)
			} catch {
				completion(nil)
			}
		}
	}
}
