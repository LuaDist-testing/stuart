local class = require 'middleclass'
local has_luasocket, http = pcall(require, 'socket.http')
local jsonutil = require 'stuart.util.json'
local moses = require 'stuart.util.moses'
local _, socketUrl = pcall(require, 'socket.url')

local FileSystem = require 'stuart.FileSystem'

local WebHdfsFileSystem = class('WebHdfsFileSystem', FileSystem)

function WebHdfsFileSystem:initialize(uri)
  assert(has_luasocket)
  FileSystem.initialize(self, uri)
  self.parsedUri = socketUrl.parse(uri)
end

function WebHdfsFileSystem:getFileStatus(path)
  local urlSegments = moses.clone(self.parsedUri)
  urlSegments.path = urlSegments.path .. '/v1/' .. (path or '')
  urlSegments.query = 'op=GETFILESTATUS'
  local uri = socketUrl.build(urlSegments)
  local json, status, headers = http.request(uri)
  local obj = jsonutil.decode(json)
  if obj.RemoteException then error(obj.RemoteException.message) end
  return obj.FileStatus, status, headers
end

function WebHdfsFileSystem:isDirectory(path)
  local fileStatus = self:getFileStatus(path)
  return fileStatus and fileStatus.type == 'DIRECTORY'
end

function WebHdfsFileSystem:listStatus(path)
  local urlSegments = moses.clone(self.parsedUri)
  urlSegments.path = urlSegments.path .. '/v1/' .. (path or '')
  urlSegments.query = 'op=LISTSTATUS'
  local uri = socketUrl.build(urlSegments)
  local json, status, headers = http.request(uri)
  local obj = jsonutil.decode(json)
  if obj.RemoteException then error(obj.RemoteException.message) end
  return obj.FileStatuses.FileStatus, status, headers
end

function WebHdfsFileSystem:mkdirs(path)
  local urlSegments = moses.clone(self.parsedUri)
  urlSegments.path = urlSegments.path .. '/v1/' .. (path or '')
  urlSegments.query = 'op=MKDIRS'
  local uri = socketUrl.build(urlSegments)
  local json, status, headers = http.request(uri)
  local obj = jsonutil.decode(json)
  if obj.RemoteException then error(obj.RemoteException.message) end
  return obj.boolean, status, headers
end

function WebHdfsFileSystem:open(path)
  local urlSegments = moses.clone(self.parsedUri)
  urlSegments.path = urlSegments.path .. '/v1/' .. (path or '')
  urlSegments.query = 'op=OPEN'
  local uri = socketUrl.build(urlSegments)
  local data, status, headers = http.request(uri)
  return data, status, headers
end

return WebHdfsFileSystem
