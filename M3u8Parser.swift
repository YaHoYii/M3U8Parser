//
//  m3u8Handler.swift
//  DownLoadFile
//
//  Created by yang on 2017/10/5.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import Alamofire

protocol M3u8ParserDelegate: class {
  func parseM3u8Succeeded(by parser: M3u8Parser)
  func parseM3u8Failed(by parser: M3u8Parser)
}

open class M3u8Parser {
   weak var delegate: M3u8ParserDelegate?
  
   var m3u8Data: String = ""
   var tsSegmentArray = [M3u8TsSegmentModel]()
   var tsPlaylist = M3u8Playlist()
   var identifier = ""
   var videoIndet = ""
  /**
   To parse m3u8 file with a provided URL.
   
   - parameter url: A string of URL you want to parse.
   */
  open func parse(with url: String) {
    guard let m3u8ParserDelegate = delegate else {
      //print("M3u8ParserDelegate not set.")
      return
    }
    
    if !(url.hasPrefix("http://") || url.hasPrefix("https://")) {
      //print("Invalid URL.")
      m3u8ParserDelegate.parseM3u8Failed(by: self)
      return
    }
    
    DispatchQueue.global(qos: .background).async {
      do {
        let m3u8Content = try String(contentsOf: URL(string: url)!, encoding: .utf8)
       //print(m3u8Content)
        if m3u8Content == "" {
          //print("Empty m3u8 content.")
          m3u8ParserDelegate.parseM3u8Failed(by: self)
          return
        } else {
          guard (m3u8Content.range(of: "#EXTM3U") != nil) else {
            //print("No EXTINF info.")
            m3u8ParserDelegate.parseM3u8Failed(by: self)
            return
          }
          self.m3u8Data = m3u8Content
          if self.tsSegmentArray.count > 0 { self.tsSegmentArray.removeAll() }
          
            let segmentRange = m3u8Content.range(of: "#EXTM3U")!
          let segmentsString = String(m3u8Content.suffix(from: segmentRange.lowerBound)).components(separatedBy: "#EXT-X-ENDLIST")
            // 以 \n为节点 把文件内的string转化为数组
          var segmentArray = segmentsString[0].components(separatedBy: "\n")
            // 筛选出不包含#EXT-X-DISCONTINUITY这个标签的数组
            segmentArray = segmentArray.filter { !$0.contains("#EXT-X-DISCONTINUITY") }
         //print(segmentArray)
            var keyArray: [String] = []
            if m3u8Content.contains("#EXT-X-KEY:") {
               keyArray = segmentArray.filter{ $0.contains("#EXT-X-KEY") }
            }
            
            let duretionArray = segmentArray.filter{ $0.contains("#EXTINF") }
            let tsArray = segmentArray.filter{ $0.contains(".ts?") }
            
         //print(keyArray)
         //print(duretionArray)
         //print(tsArray)
            
            for i in 0..<tsArray.count {
                var segmentModel = M3u8TsSegmentModel()
                if m3u8Content.contains("#EXT-X-KEY:") {
                    /// #EXT-X-KEY:METHOD=AES-128,URI="http://eduwind.cn/hls/clef?id=35631",IV=0x88e1ae3cd5464adfcc0e267426e2b814
                    // 类似于上边的字符串，要把URI中的替换掉
                    var keys = keyArray[i]
                  //print(keys)
                    // 从第一个字母开始往后数11位获得下标
                    let startSlicingIndex = keys.index(keys.startIndex, offsetBy: 11)
                    // key之后的所有 ,获得子字符串
                    let subvalues = keys[startSlicingIndex...]
                    // 以 , 为分界点，分为数组
                    let keyArray = subvalues.components(separatedBy: ",")
                    // 获取下标为1的字符串，也就是URI 的字符串
                    var URIkey = keyArray[1]
                    // 截取URI的5位后的字符串，得到的是http://eduwind.cn/hls/clef?id=35631"，多一个引号，需要去掉
                    let URIStarIndex = URIkey.index(URIkey.startIndex, offsetBy: 5)
                    let URIEndIndex = URIkey[URIStarIndex...].index(URIkey[URIStarIndex...].endIndex, offsetBy: -2)
                    let keyurl = URIkey[URIStarIndex...][...URIEndIndex]
                 //  print(keyurl)
                    
                    let starIndex = keys.index(keys.startIndex, offsetBy: 31)

                    keys.replaceSubrange(starIndex...keys.index(starIndex, offsetBy: keyurl.count - 1), with: "http://localhost:8099/videoKey.txt")
           
                   //print(keys)
                    
                    segmentModel.key = keys
                    requextVideoKey(keyUrl: String(keyurl))

                }

                let segmentDurationPart = duretionArray[i].components(separatedBy: ":")[1]
          //print(duretionArray[i].components(separatedBy: ":"))
          //print(segmentDurationPart)
                var segmentDuration: Float = 0.0
                
                if segmentDurationPart.contains(",") {
                    // 然后以 ， 为节点转化为数组取下首元素
                    segmentDuration = Float(segmentDurationPart.components(separatedBy: ",")[0])!
            //        //print(segmentArray)
                } else {
                    segmentDuration = Float(segmentDurationPart)!
                }
                segmentModel.duration = segmentDuration
                
                let segmentURL = tsArray[i]
              //print(segmentURL)
                
                if m3u8Content.contains("#EXT-X-KEY:")  {
                    segmentModel.locationURL = "http://u20094.cloud.eduwind.com" + segmentURL
                }else {
                    segmentModel.locationURL = segmentURL
                }
                
              //  segmentModel.key = ""
                self.tsSegmentArray.append(segmentModel)
              //print(self.tsSegmentArray)
                
            }

            self.tsPlaylist.initSegment(with: self.tsSegmentArray)
            self.tsPlaylist.identifier = self.identifier
            self.tsPlaylist.videoIndet = self.videoIndet
          
            m3u8ParserDelegate.parseM3u8Succeeded(by: self)
        }
      } catch let error {
        //print(error.localizedDescription)
        //print("Read m3u8 file content error.")
      }
    }
    
    
    func requextVideoKey(keyUrl: String) {
        
        // 请求key的操作
        let url = URL(string: String(keyUrl))
        var request = URLRequest(url: url!)   //请求
        request.httpMethod = "GET"   //修改http方法
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request,
                                        completionHandler: {(data, response, error) -> Void in
                                            if error != nil{
                                               //print(error.debugDescription)
                                            }else{

											//	let string = String(data: data!, encoding: String.Encoding.utf8)
											//	print(string!)
                                                
                                                let myDirectory = NSHomeDirectory() + "/Documents/Downloads/\(self.videoIndet)/\(self.identifier)/videoKey.txt"
                                                let fileManager = FileManager.default
                                                // 将key 写入文件
                                                fileManager.createFile(atPath: myDirectory, contents: data, attributes: nil)
                                            }
        }) as URLSessionTask
        
        //使用resume方法启动任务
        dataTask.resume()
        
    }

  }
}
