import Foundation
import SystemConfiguration

class wwdcController {
    
    class func getResourceURLs(fromHTML: String, fileExtension: String)  -> ([String]) {
        let pat = "\\b.*(https://.*\\." + fileExtension + ")\\b"
        let regex = try! NSRegularExpression(pattern: pat, options: [])
        let matches = regex.matches(in: fromHTML, options: [], range: NSRange(location: 0, length: fromHTML.characters.count))
        var resourceURLs = [String]()
        for match in matches {
            let range = match.rangeAt(1)
            let r = fromHTML.index(fromHTML.startIndex, offsetBy: range.location) ..< fromHTML.index(fromHTML.startIndex, offsetBy: range.location+range.length)
            let url = fromHTML.substring(with: r)
            resourceURLs.append(url)
        }
        
        return resourceURLs
    }
    
    class func getSubtitleURLs(fromText: String)  -> ([String]) {
        let pat = "\\b.*(subtitles/.*\\." + "m3u8" + ")\\b"
        let regex = try! NSRegularExpression(pattern: pat, options: [])
        let matches = regex.matches(in: fromText, options: [], range: NSRange(location: 0, length: fromText.characters.count))
        var resourceURLs = [String]()
        for match in matches {
            let range = match.rangeAt(1)
            let r = fromText.index(fromText.startIndex, offsetBy: range.location) ..< fromText.index(fromText.startIndex, offsetBy: range.location+range.length)
            let url = fromText.substring(with: r)
            resourceURLs.append(url)
        }
        
        return resourceURLs
    }
    
    class func getSubtitle(fromText: String, baseURL: String) -> (String) {
        let pat = "\\b.*(file.*\\." + "webvtt" + ")\\b"
        let regex = try! NSRegularExpression(pattern: pat, options: [])
        let matches = regex.matches(in: fromText, options: [], range: NSRange(location: 0, length: fromText.characters.count))
        
        var subtitle = ""
        var i = 0
        for match in matches {
            let range = match.rangeAt(1)
            let r = fromText.index(fromText.startIndex, offsetBy: range.location) ..< fromText.index(fromText.startIndex, offsetBy: range.location+range.length)
            var url = fromText.substring(with: r)
            url = URL(string: url, relativeTo: URL(string: baseURL))!.absoluteString
            var urlString = wwdcController.getStringContent(fromURL: url)
            
            let tmp = urlString.components(separatedBy: "\n")
            urlString = urlString.replacingOccurrences(of: tmp[0]+"\n", with: "")
            urlString = urlString.replacingOccurrences(of: tmp[1]+"\n", with: "")
            subtitle += urlString
            i = i+1
            wwdcController.show(progress: i*100/matches.count, barWidth: 70)
        }
        return subtitle
    }
    
    class func show(progress: Int, barWidth: Int) {
        print("\r[", terminator: "")
        let pos = Int(Double(barWidth*progress)/100.0)
        for i in 0...barWidth {
            switch(i) {
            case _ where i < pos:
                print("🁢", terminator:"")
                break
            case pos:
                print("🁢", terminator:"")
                break
            default:
                print(" ", terminator:"")
                break
            }
        }
        
        print("] \(progress)% ", terminator:"")
        fflush(__stdoutp)
    }
    
    class func getSessionsList(fromHTML: String) -> Array<String> {
        let pat = "\"\\/videos\\/play\\/wwdc2017\\/([0-9]*)\\/\""
        let regex = try! NSRegularExpression(pattern: pat, options: [])
        let matches = regex.matches(in: fromHTML, options: [], range: NSRange(location: 0, length: fromHTML.characters.count))
        var sessionsListArray = [String]()
        for match in matches {
            for n in 0..<match.numberOfRanges {
                let range = match.rangeAt(n)
                let r = fromHTML.index(fromHTML.startIndex, offsetBy: range.location) ..<
                    fromHTML.index(fromHTML.startIndex, offsetBy: range.location+range.length)
                switch n {
                case 1:
                    sessionsListArray.append(fromHTML.substring(with: r))
                default: break
                }
            }
        }
        return sessionsListArray
    }
    
    class func getTitle(fromHTML: String) -> (String) {
        let pat = "<h1>(.*)</h1>"
        let regex = try! NSRegularExpression(pattern: pat, options: [])
        let matches = regex.matches(in: fromHTML, options: [], range: NSRange(location: 0, length: fromHTML.characters.count))
        var title = ""
        if !matches.isEmpty {
            let range = matches[0].rangeAt(1)
            let r = fromHTML.index(fromHTML.startIndex, offsetBy: range.location) ..<
                fromHTML.index(fromHTML.startIndex, offsetBy: range.location+range.length)
            title = fromHTML.substring(with: r)
        }
        
        return title
    }
    
    class func getHDURLs(fromHTML: String) -> (String) {
        let pat = "\\b.*(https://.*" + "hd" + ".*\\.mp4)\\b"
        let regex = try! NSRegularExpression(pattern: pat, options: [])
        let matches = regex.matches(in: fromHTML, options: [], range: NSRange(location: 0, length: fromHTML.characters.count))
        var videoURL = ""
        if !matches.isEmpty {
            let range = matches[0].rangeAt(1)
            let r = fromHTML.index(fromHTML.startIndex, offsetBy: range.location) ..<
                fromHTML.index(fromHTML.startIndex, offsetBy: range.location+range.length)
            videoURL = fromHTML.substring(with: r)
        }
        
        return videoURL
    }
    
    class func getStringContent(fromURL: String) -> (String) {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        var result = ""
        guard let URL = URL(string: fromURL) else {return result}
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        
        let semaphore = DispatchSemaphore.init(value: 0)
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                result = String.init(data: data!, encoding: .utf8)!
            } else {
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
            
            semaphore.signal()
        })
        task.resume()
        semaphore.wait()
        return result
    }
    
    class func getSubtitleFile(htmlText: String, fileName: String, forSession sessionIdentifier: String = "???") {
        //let subtitleFileName = fileName + ".srt"
        let hlsList = wwdcController.getResourceURLs(fromHTML: htmlText, fileExtension: "m3u8")
        
        if let hlsURL = hlsList.first {
            print("Subtitle : Subtitle is download !!!")
            let hlsText = wwdcController.getStringContent(fromURL: hlsURL)
            let subtitleList = wwdcController.getSubtitleURLs(fromText: hlsText)
            for subtitle in subtitleList {
                let fileSequenceURL = URL(string: subtitle, relativeTo: URL(string: hlsURL))!.absoluteString
                let local = URL(string: fileSequenceURL)!.deletingLastPathComponent().lastPathComponent
                var path = "subtitles/"
                switch local {
                case "eng":
                    path.append("eng/")
                case "zho":
                    path.append("zho/")
                default:
                    break;
                }
                path.append(fileName+".srt")
                if FileManager.default.fileExists(atPath: path) {
                    print("\(fileName): already exists, nothing to do!")
                    continue
                }
                
                let fileSequenceText = wwdcController.getStringContent(fromURL: fileSequenceURL)
                let subtitle = wwdcController.getSubtitle(fromText: fileSequenceText, baseURL: fileSequenceURL)
                try? subtitle.write(toFile: path, atomically: true, encoding: .utf8)
            }
        } else {
            print("Subtitle : Subtitle is not yet available !!!")
        }
    }
}

func sortFunc(value1: String, value2: String) -> Bool {
    
    let filteredVal1 = value1.substring(to: value1.index(value1.startIndex, offsetBy: 3))
    let filteredVal2 = value2.substring(to: value2.index(value2.startIndex, offsetBy: 3))
    
    return filteredVal1 < filteredVal2;
}

func createSubtitleDirectory(path: String) {
    if !FileManager.default.fileExists(atPath: path) {
        try? FileManager.default.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: true, attributes: nil)
    }
}

let htmlSessionListString = wwdcController.getStringContent(fromURL: "https://developer.apple.com/videos/wwdc2017/")
print("Let me ask Apple about currently available sessions. This can take some time (15 to 20 sec.) ...")
var sessionsListArray = wwdcController.getSessionsList(fromHTML: htmlSessionListString)
sessionsListArray=Array(Set(sessionsListArray))
sessionsListArray.sort(by: sortFunc)

createSubtitleDirectory(path: "subtitles/eng")
createSubtitleDirectory(path: "subtitles/zho")
for (_, value) in sessionsListArray.enumerated() {
    let fromURL = "https://developer.apple.com/videos/play/wwdc2017/" + value + "/"
    let htmlText = wwdcController.getStringContent(fromURL: fromURL)
    
    let title = wwdcController.getTitle(fromHTML: htmlText)
    print("\n[Session \(value)] : \(title)")
    
    let videoURLString = wwdcController.getHDURLs(fromHTML: htmlText)
    if videoURLString.isEmpty {
        print("Subtitle : Subtitle is not yet available !!!")
    } else {
        let fileName = URL(fileURLWithPath: videoURLString).deletingPathExtension().lastPathComponent
        //print("Video : \(fileName)")
        
        wwdcController.getSubtitleFile(htmlText: htmlText, fileName: fileName, forSession: value)
    }
}
