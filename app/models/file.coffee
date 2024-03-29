Model = require './model'

module.exports = class File extends Model
  isDirectory: -> @get('type') == 'directory'
  isView: -> @get('name').match /\.eco$/

  # Returns the code editor mode to run
  codeMode: ->
    if @get('name')
      if @get('name').match /\.coffee$/
        "coffeescript"
      else if @get('name').match /\.js$/
        "javascript"
      else if @get('name').match /\.json/
        {name: "javascript", json: yes}
      else if @get('name').match /\.s?css$/
        "css"
      else if @get('name').match /\.(md|markdown|mdown)$/
        "markdown"
      else if @get('name').match /\.html?$/
        {name: "xml", htmlMode: yes}
      else if @get('name').match /\.eco$/
        "eco"
    else
      "text"

  fullPath: -> "#{@get('parent')}/#{@get('name')}"

  railsPath: (method) ->
    path = [app.baseUrl, "projects", @project.get('id'), "files", method].join("/")
    path += "?path=#{[@get('parent'), @get('name')].join "/"}" # Had to do this like this in order to play
                                    # nicely with rails.

  # Lazy-loads the content, calls the callback with the content when done
  fetchContent: ->
    return if @isDirectory() # Folders don't have any content you silly

    $.getJSON @railsPath('get_content'), (data) => 
      @set 'content', data.content, silent: true

      # Force an update notification
      @trigger 'change:content'

  updateContent: (callback) ->
    return if @isDirectory()

    Backbone.Mediator.pub "status:set", "Saving #{@get('name')} ..."
    $.ajax
      url: @railsPath('save_content'), 
      type: 'PUT',
      data: {content: @get('content')},
      success: (data) =>
        @set 'content', data.content, silent: true
        @trigger 'change:content'

        Backbone.Mediator.pub "status:set", "Saved #{@get('name')}"

        callback?(data)
