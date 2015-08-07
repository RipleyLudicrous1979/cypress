@App = do (Backbone, Marionette) ->

  App = new Marionette.Application

  ## I think this should be window.App not global
  global.App = App

  App.addRegions
    mainRegion:   "#main-region"
    footerRegion: "#footer-region"

  ## store the default region as the main region
  App.reqres.setHandler "default:region", -> App.mainRegion

  App.on "start", (options = {}) ->
    options = options.backend.parseArgs(options)

    ## create a App.config model from the passed in options
    App.config = App.request("config:entity", options)

    App.config.log("Starting Desktop App", options: _.omit(options, "backend"))

    ## create an App.updater model which is shared across the app
    App.updater = App.request "new:updater:entity"

    ## our config + updater are ready
    App.vent.trigger "app:entities:ready", App

    ## if we are in smokeTest mode
    ## then just output the pong's value
    ## and exit
    if options.smokeTest
      process.stdout.write(options.pong + "\n")
      return process.exit()

    ## if we are updating then do not start the app
    ## or display any UI. just finish installing the updates
    if options.updating
      ## display the GUI
      App.execute "gui:display", options.coords

      ## start the updates being applied app so the user knows its still a-happen-ning
      return App.execute "start:updates:applied:app", options.appPath, options.execPath

    ## check cache store for user
    App.config.getUser().then (user) ->
      ## set the current user
      App.execute "set:current:user", user

      ## do we have a session?
      options.session = user?.session_token?

      App.config.cli(options)

  return App