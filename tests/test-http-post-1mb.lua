--[[

Copyright 2015 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local http = require('http')
local string = require('string')

local HOST = "127.0.0.1"
local PORT = process.env.PORT or 10080
local server = nil
local client = nil

local a = string.rep('a', 1024)
local data = string.rep(a, 1024)
local MB = data:len()

require('tap')(function(test)
  test('http-post-1mb', function(expect)
    server = http.createServer(function(request, response)
      p('server:onConnection')
      local postBuffer = ''
      assert(request.method == "POST")
      assert(request.url == "/foo")
      assert(request.headers.bar == "cats")
      request:on('data', function(chunk)
        postBuffer = postBuffer .. chunk
      end)
      request:on('end', expect(function()
        p('server:onEnd')
        assert(postBuffer == data)
        response:write(data)
        response:finish()
        server:close()
      end))
    end)

    server:listen(PORT, HOST, function()
      local headers = {
        {'bar', 'cats'},
        {'Content-Length', MB},
        {'Transfer-Encoding', 'chunked'}
      }
      local req = http.request({
        host = HOST,
        port = PORT,
        method = 'POST',
        path = "/foo",
        headers = headers
      }, function(response)
        assert(response.statusCode == 200)
        assert(response.httpVersion == '1.1')
        response:on('data', expect(function(data)
          assert(data:len() == MB)
          p('All data received')
        end))
        response:on('end', expect(function(data)
          p('Response ended')
        end))
      end)
      req:write(data)
      req:done()
    end)
  end)
end)
