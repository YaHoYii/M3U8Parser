//
//  m3u8Handler.swift
//  DownLoadFile
//
//  Created by yang on 2017/10/5.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public enum Status {
  case started
  case paused
  case canceled
  case finished
}

protocol VideoDownloaderDelegate {
    func videoDownloadSucceeded(by downloader: VideoDownloader)
    func videoDownloadFailed(by downloader: VideoDownloader)
    func updateFileNumber(_ progress: Float)
    func updateSizeProgress(_ progress: Double,size: Int, currentSize: Int)
}

open class VideoDownloader {
  public var downloadStatus: Status = .paused
  
  var m3u8Data: String = ""
  var tsPlaylist = M3u8Playlist()
  var segmentDownloaders = [SegmentDownloader]()
  var tsFilesIndex = 0
  var neededDownloadTsFilesCount = 0
  var downloadURLs = [String]()
  var downloadingProgress: Float {
    let finishedDownloadFilesCount = segmentDownloaders.filter({ $0.finishedDownload == true }).count
    let fraction = Float(finishedDownloadFilesCount) / Float(neededDownloadTsFilesCount)
    let roundedValue = round(fraction * 100) / 100
    
    return roundedValue
  }
  
  fileprivate var startDownloadIndex = 2
  
  var delegate: VideoDownloaderDelegate?
  
  open func startDownload() {
    
    checkOrCreatedM3u8Directory()
    
    var newSegmentArray = [M3u8TsSegmentModel]()
    
    let notInDownloadList = tsPlaylist.tsSegmentArray.filter { !downloadURLs.contains($0.locationURL) }
    neededDownloadTsFilesCount = tsPlaylist.length
   //print(tsPlaylist.tsSegmentArray)
   //print(notInDownloadList)
    for i in 0 ..< notInDownloadList.count {
      let subfileName = "\(tsFilesIndex).ts"
 
      let segmentDownloader = SegmentDownloader(with: notInDownloadList[i].locationURL,
                                                  filePath: tsPlaylist.videoIndet,
                                                  fileName: tsPlaylist.identifier,
                                                  subFileName: subfileName,
                                                  key: notInDownloadList[i].key,
                                                  duration: notInDownloadList[i].duration,
                                                  index: tsFilesIndex)
 
      segmentDownloader.delegate = self
      
      segmentDownloaders.append(segmentDownloader)
      downloadURLs.append(notInDownloadList[i].locationURL)
      
      var segmentModel = M3u8TsSegmentModel()
      segmentModel.duration = segmentDownloaders[i].duration
      segmentModel.locationURL = segmentDownloaders[i].fileName
      segmentModel.key = segmentDownloaders[i].key
      segmentModel.index = segmentDownloaders[i].index
      newSegmentArray.append(segmentModel)
      
      tsPlaylist.tsSegmentArray = newSegmentArray
      
      tsFilesIndex += 1
    }
    
     for i in 0 ..< notInDownloadList.count {
        
        segmentDownloaders[i].startDownload()

    }
//
//    if notInDownloadList.count == 1 {
//         segmentDownloaders[0].startDownload()
//    }else if notInDownloadList.count == 2 {
//        segmentDownloaders[0].startDownload()
//        segmentDownloaders[1].startDownload()
//    }else {
//        segmentDownloaders[0].startDownload()
//        segmentDownloaders[1].startDownload()
//        segmentDownloaders[2].startDownload()
 //   }

    
    downloadStatus = .started
  }
  
  func checkDownloadQueue() {
    
  }
  
  func updateLocalM3U8file() {
    checkOrCreatedM3u8Directory()
    
    let filePath = getDocumentsDirectory().appendingPathComponent("Downloads").appendingPathComponent(tsPlaylist.videoIndet).appendingPathComponent(tsPlaylist.identifier).appendingPathComponent("\(tsPlaylist.identifier).m3u8")
    
    var header = "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:35\n"
    var content = ""
    
    for i in 0 ..< tsPlaylist.tsSegmentArray.count {
      let segmentModel = tsPlaylist.tsSegmentArray[i]
       //print(segmentModel.key)
      let key = segmentModel.key + "\n"
      let length = "#EXTINF:\(segmentModel.duration),\n"
      let fileName = "http://localhost:8099/\(segmentModel.index).ts\n"
      content += (key + length + fileName)
    }
    
    header.append(content)
    header.append("#EXT-X-ENDLIST\n")
    
    let writeData: Data = header.data(using: .utf8)!
    try! writeData.write(to: filePath)
    
  }
  
  private func checkOrCreatedM3u8Directory() {
    let filePath = getDocumentsDirectory().appendingPathComponent("Downloads").appendingPathComponent(tsPlaylist.videoIndet).appendingPathComponent(tsPlaylist.identifier)
    
    if !FileManager.default.fileExists(atPath: filePath.path) {
      try! FileManager.default.createDirectory(at: filePath, withIntermediateDirectories: true, attributes: nil)
    }
  }
  
  open func deleteAllDownloadedContents() {
    let filePath = getDocumentsDirectory().appendingPathComponent("Downloads").path
    
    if FileManager.default.fileExists(atPath: filePath) {
      try! FileManager.default.removeItem(atPath: filePath)
    } else {
      //print("File has already been deleted.")
    }
  }
  
  static func deleteDownloadedContents(with name: String) {

    if FileManager.default.fileExists(atPath: name) {
      try! FileManager.default.removeItem(atPath: name)
    } else {
      //print("Could not find directory with name: \(name)")
    }
  }
  
  open func pauseDownloadSegment() {
    _ = segmentDownloaders.map { $0.pauseDownload() }
    
    downloadStatus = .paused
  }
  
  open func cancelDownloadSegment() {
    _ = segmentDownloaders.map { $0.cancelDownload() }
    
    downloadStatus = .canceled
  }
  
  open func resumeDownloadSegment() {
    _ = segmentDownloaders.map { $0.resumeDownload() }
    
    downloadStatus = .started
  }
}

extension VideoDownloader: SegmentDownloaderDelegate {
    func segmentDownloadSucceeded(with downloader: SegmentDownloader) {
        let finishedDownloadFilesCount = segmentDownloaders.filter({ $0.finishedDownload == true }).count

        DispatchQueue.main.async {
          self.delegate?.updateFileNumber(self.downloadingProgress)
        }

        updateLocalM3U8file()

        let downloadingFilesCount = segmentDownloaders.filter({ $0.isDownloading == true }).count

        if finishedDownloadFilesCount == neededDownloadTsFilesCount {
          delegate?.videoDownloadSucceeded(by: self)
          
          downloadStatus = .finished
        } else if startDownloadIndex == neededDownloadTsFilesCount - 1 {
          if segmentDownloaders[startDownloadIndex].isDownloading == true { return }
        }
        else if downloadingFilesCount < 3 || finishedDownloadFilesCount != neededDownloadTsFilesCount {
          if startDownloadIndex < neededDownloadTsFilesCount - 1 {
            startDownloadIndex += 1
          }
          
          segmentDownloaders[startDownloadIndex].startDownload()
        }
    }

    func segmentDownloadFailed(with downloader: SegmentDownloader) {
        delegate?.videoDownloadFailed(by: self)
    }
    
    func updateDownloadProgress(progress: Double, size: Int, currentSize: Int) {
        delegate?.updateSizeProgress(progress, size: size, currentSize: currentSize)
    }
    
    
    
}
