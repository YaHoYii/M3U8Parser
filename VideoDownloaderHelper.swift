//
//  m3u8Handler.swift
//  DownLoadFile
//
//  Created by yang on 2017/10/5.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public func getDocumentsDirectory() -> URL {
      let paths = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask)
      let documentsDirectory = paths[0]
      print(documentsDirectory)
      return documentsDirectory
}
