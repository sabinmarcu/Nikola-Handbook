coffee = require "coffee-script"
express = require "express"
stitch = require "stitch"
mongoose = require "mongoose"
fs = require "fs"
io = require("socket.io")

argv = process.argv.slice 2
pub = __dirname + "/client"

app = express.createServer()
io = io.listen(app)

packageData =
  paths: [pub + "/app"]

packageData.dependencies = [
  pub + "/libs/cltk/CLFramework.coffee",
  pub + "/libs/cltk/CLUtils.coffee",
  pub + "/libs/cltk/CLDynamicFileLoader.coffee",
  pub + "/libs/cltk/CLLIghtBox.coffee",
  pub + "/libs/cltk/CLShaderLoader.coffee",
  pub + "/libs/cltk/lightbox.css"
]

mongoose.connect "mongodb://localhost/nikola"
SnippetSchema = new mongoose.Schema(
  name:
    type: String
    unique: true

  DI: {}
  DE: {}
  FUNC: {}
  description: String
  tags: Array
)
Snippet = mongoose.model("snippets", SnippetSchema)
Snippet.find {}, (err, doc) ->
  console.log err, doc

package = stitch.createPackage packageData

app.configure ->
	app.use app.router
	app.use express.static(pub + "/public")
	app.set "views", pub + "app/views"
	app.get "/application.js", package.createServer()
	app.get "/bootstrap.js", (req, res) -> 
		fs.readFile pub + "/app/script.coffee", 'utf-8', (err, data) ->
			if err 
				res.writeHead 404
				res.end "Problem!"
			else
				res.writeHead "200", 
					"Content-Type" : "text/javascript"

				code = coffee.compile data
				res.end code



port = parseInt(argv[0]) or process.env.PORT or 8080
console.log "Started listening to port #{port}"
app.listen port

sendError = (error, sock, callback) ->
  sock.emit "errorLog", error
  callback()  if callback

sendSuccess = (message, sock, callback) ->
  sock.emit "successLog", message
  callback()  if callback

sendJson = (json, sock, callback) ->
  sock.emit "getSnippet", json
  callback()  if callback

io.sockets.on "connection", (sock) ->
  sock.on "requestSnippet", (data) ->
   Snippet.find
     name:
       $regex: new RegExp(data.name, "i")
   , (err, docs) ->
     if err
       sendError err, sock
     else if docs.length
       sendJson docs[0], sock
     else
       sendError "The snippet cannot be found!", sock

  sock.on "requestSnippetRemove", (data) ->
   Snippet.find
     _id: data
   , (err, docs) ->
     unless err
       for doc of docs
         docs[doc].remove()
       sendSuccess "Successfuly deleted the document!", sock

  sock.on "requestSnippetSave", (data) ->
   s = new Snippet()
   s.DI = data.DI
   s.DE = data.DE
   s.FUNC = data.FUNC
   s.name = data.name
   s.descr = data.descr
   s.tags = data.tags
   s.save (err) ->
     if err
       sendError "Could not save snippet. Reason : \n" + err, sock
     else
       sendSuccess "Saved the document!", sock

  sock.on "requestSnippetList", (data) ->
   Snippet.find {}, (err, data) ->
     unless err
       snippets = ""
       for s of data
         snippets = "<li onclick='NH.requestSnippetFunc(\"" + data[s].name + "\")'>" + data[s].name + "</li>" + snippets
       sendSuccess snippets, sock
