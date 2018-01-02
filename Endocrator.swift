//
//  m3u8Handler.swift
//  DownLoadFile
//
//  Created by yang on 2017/10/5.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public protocol EndocratorDelegate: class {
    func videoDownloadSucceeded()
    func videoDownloadFailed()

    func update(_ endocrator: Endocrator ,progress: Float, with directoryName: String)
    func updateSize(_ endocrator: Endocrator ,_ progress: Double, size: Int, currentSize: Int)
}

open class Endocrator {
	var filesize: Int = 0
	var array = [[String: Int]]()
	var sizeDic: [String: Int] = [:]
	public let downloader = VideoDownloader()
	public var progress: Float = 0.0
	public var id: String!
	public var lectureFileName: String = "" {
	 didSet {
	   m3u8Parser.identifier = lectureFileName
	 }
	}
	public var courseFileName: String = "" {
	 didSet {
		m3u8Parser.videoIndet = courseFileName
	 }
	}
	public var m3u8URL = ""

	private let m3u8Parser = M3u8Parser()

	public weak var delegate: EndocratorDelegate?

	public init() {

	}

	open func parse() {
		downloader.delegate = self
		m3u8Parser.delegate = self
		m3u8Parser.parse(with: m3u8URL)
	}
}

extension Endocrator: M3u8ParserDelegate {
  func parseM3u8Succeeded(by parser: M3u8Parser) {
    downloader.tsPlaylist = parser.tsPlaylist
   //print(parser.tsPlaylist.tsSegmentArray)
    downloader.m3u8Data = parser.m3u8Data
    downloader.startDownload()
  }
  
  func parseM3u8Failed(by parser: M3u8Parser) {
       //print("Parse m3u8 file failed.")
  }

}

extension Endocrator: VideoDownloaderDelegate {

    func videoDownloadSucceeded(by downloader: VideoDownloader) {
        delegate?.videoDownloadSucceeded()
    }

    func videoDownloadFailed(by downloader: VideoDownloader) {
        delegate?.videoDownloadFailed()
    }

    func updateFileNumber(_ progress: Float) {
        self.progress = progress
        delegate?.update(self, progress: progress, with: lectureFileName)
//      guard let size = sizeDic[id] else {
//         return
//      }
//		print(filesize,"++++++++++++++++++++",self.id)
        realmDownload = (self,Double(self.progress),filesize / 1024 / 1024)
    }
    
    func updateSizeProgress(_ progress: Double, size: Int, currentSize: Int) {
     //print(size,"________-----------__________------")
        var dicKeys: Set<String> = []
        if progress == 1 {
            array.append([self.id : size])
            for dic in array {
                dicKeys.insert(dic.keys.first!)
            }
        }
        
        for key in dicKeys {
            let dicArry = array.filter { (dic) -> Bool in
                return dic.keys.first == key
            }
            var intArr: [Int] = []
            for aaa in dicArry {
                intArr.append(aaa.values.first!)
                filesize += aaa.values.first!
            }
          //  sizeDic.updateValue(filesize, forKey: self.id)
        }

//        if !sizeDic.isEmpty {
//           //print(sizeDic,"333333333333333333")
//        }

        delegate?.updateSize(self, Double(self.progress), size: filesize/1024/1024, currentSize: currentSize)
    }
}
