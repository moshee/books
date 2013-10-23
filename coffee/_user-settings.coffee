window.UserSettings = class
  constructor: ->
    @tabs = $$ '.tab-stack a'
    @windowLoc = $ '#settings'
