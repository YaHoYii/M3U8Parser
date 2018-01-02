//
//  m3u8Handler.swift
//  DownLoadFile
//
//  Created by yang on 2017/10/5.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

class M3u8Playlist {
  var tsSegmentArray = [M3u8TsSegmentModel]()
  var length = 0
  var identifier = ""
  var videoIndet = ""
  
  func initSegment(with array: [M3u8TsSegmentModel]) {
    tsSegmentArray = array
    length = array.count
  }
}
