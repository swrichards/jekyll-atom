childProcess = require 'child_process'

module.exports =
  class JekyllServer
    pwd: atom.project.getPath()
    pid: 0
    process: null
    consoleLog: ''
    emitter: null

    activate: (emitter) ->
      @emitter = emitter
      JekyllServer.emitter = @emitter

      @emitter.on 'jekyll:start-server', => @start()
      @emitter.on 'jekyll:stop-server', => @stop()
      @emitter.on 'jekyll:server-status', => @status()
      @emitter.on 'jekyll:version', => @version()
      @emitter.on 'jekyll:pre-fill-console', => @preFillConsole()
      @emitter.on 'jekyll:build-site', => @buildSite()

    status: ->
      if @pid == 0
        status = 'Off'
      else
        status = 'On'

      @emitter.emit 'jekyll:server-status-reply', status

    version: ->
      versionCommand = atom.config.get('jekyll.jekyllBinary') + " -v"

      childProcess.exec versionCommand, (error, stdout, stderr) ->
        JekyllServer.emitter.emit 'jekyll:version-reply', stdout.replace('j','J')

    start: ->
      launchMSG = "Launching Server... <i>(" + atom.config.get('jekyll.jekyllBinary') + " " + atom.config.get('jekyll.serverOptions').join(" ") + ")</i><br />"
      @emitMessage launchMSG

      @process = childProcess.spawn atom.config.get('jekyll.jekyllBinary'), atom.config.get('jekyll.serverOptions'), {cwd: @pwd}
      @process.stdout.setEncoding('utf8')

      @pid = @process.pid
      @status()

      @process.stdout.on 'data', (data) ->
        with_brs = data.replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1<br />$2')
        with_changes = with_brs.replace(/ctrl-c/, "<i>Stop Server</i>")
        JekyllServer.consoleLog += with_changes
        JekyllServer.emitter.emit 'jekyll:console-message', with_changes

    stop: ->
      killCMD = "kill " + @pid
      @emitMessage "Stopping Server... <i>(" + killCMD + ")</i><br />"


      childProcess.exec killCMD
      @process = null
      @pid = 0
      @status()

    preFillConsole: ->
      @emitter.emit 'jekyll:console-fill', JekyllServer.consoleLog

    emitMessage: (message) ->
      JekyllServer.consoleLog += message
      @emitter.emit('jekyll:console-message', message)

    buildSite: ->
      @emitMessage 'Building Site...<br />'

      buildCommand = atom.config.get('jekyll.jekyllBinary') + " build"

      childProcess.exec buildCommand, (error, stdout, stderr) ->
        JekyllServer.emitter.emit 'jekyll:console-message', stdout