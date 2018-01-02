//
//  m3u8Handler.swift
//  DownLoadFile
//
//  Created by yang on 2017/10/5.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

protocol SegmentDownloaderDelegate {
    func segmentDownloadSucceeded(with downloader: SegmentDownloader)
    func segmentDownloadFailed(with downloader: SegmentDownloader)
    func updateDownloadProgress(progress: Double,size: Int,currentSize: Int)
}


class SegmentDownloader: NSObject {
    var fileName: String
    var filePath: String
    var subFileName: String
    var downloadURL: String
    var duration: Float
    var index: Int
    var key: String

    var totalSize: Double = 0.0
    var writtenSize: Double = 0.0
    // 当前已写字节数 暂停使用
    var totalWritten: Double = 0.0
  
  lazy var downloadSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    
    return session
  }()
  
  var downloadTask: URLSessionDownloadTask?
  var isDownloading = false
  var finishedDownload = false
  
  var delegate: SegmentDownloaderDelegate?
  
    init(with url: String, filePath: String, fileName: String, subFileName: String,key: String = "", duration: Float = 10.0, index: Int = 0) {
        downloadURL = url
        self.filePath = filePath
        self.fileName = fileName
        self.subFileName = subFileName
        self.duration = duration
        self.index = index
        self.key = key
    }
  
    func startDownload() {
        if checkIfIsDownloaded() {
          finishedDownload = true
          
          delegate?.segmentDownloadSucceeded(with: self)
        } else {
          starDownloadFile()
        }
    }
    
    func starDownloadFile() {
        let url = downloadURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        guard let taskURL = URL(string: url) else { return }
        
        downloadTask = downloadSession.downloadTask(with: taskURL)
        downloadTask?.resume()
        isDownloading = true
    }
  
  func cancelDownload() {
    downloadTask?.cancel()
    isDownloading = false
  }
  
  func pauseDownload() {
    if isDownloading {
      downloadTask?.suspend()
      
      isDownloading = false
    }
  }
  
  func resumeDownload() {
    downloadTask?.resume()
    isDownloading = true
  }
  
  func checkIfIsDownloaded() -> Bool {
    let filePath = generateFilePath().path
    
    if FileManager.default.fileExists(atPath: filePath) {
      return true
    } else {
      return false
    }
  }
  
  func generateFilePath() -> URL {
    return getDocumentsDirectory().appendingPathComponent("Downloads").appendingPathComponent(filePath).appendingPathComponent(fileName).appendingPathComponent(subFileName)
  }
}

extension SegmentDownloader: URLSessionDownloadDelegate {
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    let destinationURL = generateFilePath()
    
    finishedDownload = true
    isDownloading = false
    
    if FileManager.default.fileExists(atPath: destinationURL.path) {
      return
    } else {
      do {
        try FileManager.default.moveItem(at: location, to: destinationURL)
        delegate?.segmentDownloadSucceeded(with: self)
      } catch let error as NSError {
        print(error.localizedDescription)
      }
    }
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if error != nil {
      finishedDownload = false
      isDownloading = false
      
      delegate?.segmentDownloadFailed(with: self)
    }
  }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // 全部字节数
        // 计算当前下载进度并更新视图
       
        if totalSize != Double(totalBytesExpectedToWrite) {
            totalSize = Double(totalBytesExpectedToWrite)
        }
    
        totalWritten = Double(totalBytesWritten)
   //   print(bytesWritten, totalBytesWritten,totalBytesExpectedToWrite)
        delegate?.updateDownloadProgress(progress: totalWritten / totalSize, size: Int(totalBytesExpectedToWrite), currentSize: Int(totalBytesWritten))
       
    }
  
}
