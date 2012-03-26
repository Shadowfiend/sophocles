graft = require('graft').graft
https = require('https')

postsCollection = null

class GithubRequest
  constructor: (path) ->
    log.debug "Starting up for #{path}."
    @path = path

  run: (callback) ->
    request = https.request {
      host: 'api.github.com',
      port: 443,
      path: "#{@path}",
      method: 'GET'
    }, (response) ->
      response.setEncoding 'utf8'

      body = []

      response.on 'data', (chunk) ->
        body.push chunk

      response.on 'error', (err) ->
        log.error err

        callback err

      response.on 'end', ->
        body = body.join("");

        if (response.statusCode >= 300)
          if (response.headers["content-type"].indexOf("application/json") == 0)
              msg = JSON.parse(body).error || body;
          else
              msg = body;

          msg = "GitHub error " + @path + ": " + msg;

          log.error "#{msg}; status code: #{response.statusCode}"

          callback msg
        else
          callback null, body

    request.end()

fetchPostFromGithub = (id, callback) ->
  (new GithubRequest("/repos/Shadowfiend/#{id}/commits?sha=master")).run (err, body) ->
    if err?
      log.error err
      callback false
    else
      commits = JSON.parse body

      insertPost = ->
        validCommits = commits.filter (commit) -> commit

        commitsForRecord = validCommits.map (commit) ->
          message: commit.commit.message
          stats: commit.stats
          files: commit.files

        postsCollection.insert
          repoName: id
          title: id
          commits: commitsForRecord

        callback true

      commitCount = 0
      handlerForIndex = (index) ->
        (error, body) ->
          commitCount++

          if err?
            commits[index] = undefined
            log.error err
          else
            commits[index] = JSON.parse(body)

            if commitCount == commits.length
              insertPost()

      commits.forEach (commit, i) ->
        (new GithubRequest("/repos/Shadowfiend/#{id}/commits/#{commit.sha}")).run handlerForIndex(i)

failErrors = (response, callback) ->
  (err, parameters...) ->
    if err?
      log.error err
      response.render 'error', { layout: null, status: 500 }
    else
      callback parameters...

withPostsCollection = (response, callback) ->
  if postsCollection
    callback postsCollection
  else
    response.render 'error', { layout: null, status: 500 }

withPostsQuery = (query, response, callback) ->
  withPostsCollection response, (posts) ->
    posts.find query, failErrors(response, (cursor) ->
      cursor.toArray failErrors(response, callback))

renderPosts = (request, response) ->
  withPostsQuery {}, response, (posts) ->
    response.render 'posts/index', {
      layout: 'posts-layout',
      locals:
        title: 'Posts'
    }, failErrors(response, (html) ->
      graft html, {
        'li.post': posts.map (post) ->
          '.title': post.title
          '.body': post.body
      }, failErrors response, (grafted) ->
        response.send grafted, { 'Content-Type': 'text/html' }
    )
      
renderPost = (request, response) ->
  withPostsQuery { repoName: request.params.id }, response, (posts) ->
    if posts.length
      post = posts[0]

      response.render 'posts/post', {
        layout: 'posts-layout',
        locals:
          title: "Posts—#{post.title}"
      }, failErrors(response, (html) ->
        graft html, {
          '.title': post.title
          '.text li': post.commits.map (commit) -> commit.message
          '.diffs li': post.commits.map (commit) -> commit.patch
        }, failErrors response, (grafted) ->
          response.send grafted, { 'Content-Type': 'text/html' })
    else
      fetchPostFromGithub request.params.id, (success) ->
        if success
          renderPost request, response
        else
          response.render 'error', { status: 404 }

exports.setPostsCollection = (collection) ->
  postsCollection = collection

exports.setUpRoutes = (app) ->
  app.get '/', renderPosts
  app.get '/posts/:id', renderPost
